#!/usr/bin/env python3
"""Deduplicate Spectrum 8x8 rows and emit gfx_pool.asm + tree_strips.asm for VIC-20."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BIN_DEFAULT = ROOT / "build" / "deathchase.bin"
UI_PNG = ROOT / "UI.png"
UI_TXT = ROOT / "UI.txt"
HANDLEBAR_SOURCE = ROOT / "handlebar_source.txt"
PLAYFIELD_CHR_LIMIT = 256
OUT_ASM = ROOT / "build" / "gfx_pool.asm"
OUT_JSON = ROOT / "build" / "gfx_index.json"
OUT_EQUATES = ROOT / "build" / "gfx_equates.asm"
OUT_STRIPS = ROOT / "build" / "tree_strips.asm"
ORG = 0x4000

ROM_TREE_GFX_END = 0x7CA1

CHR_HELICOPTER = 2
CHR_TANK = 4
CHR_ENEMY = 24
CHR_BOLT = 1
CHR_EXPLOSION = 9

# Fallback UI glyph order when UI.png / UI.txt are absent ($, B, 0–9)
UI_GLYPH_ORDER = "$B0123456789"

TREE_MARK_SMALL = 0x20
TREE_MARK_LARGE = 0x40

# Spectrum $6D73 — 25 × 3-byte strip refs (first entry repeated); depths 0–23 use [0..23]
ROM_STRIP_TABLE = 0x6D73
STRIP_TABLE_ENTRIES = 25
# Spectrum $64F4 — display-file anchors (reference only)
ROM_SCREEN_ANCHOR = 0x64F4

TREE_STRIP_COUNT = 26
# Spectrum logical depths 0–23; depths 0–1 each become two single-column strips (L, R).
SPECTRUM_STRIP_COUNT = 24
TREE_HUGE_SPLIT_DEPTHS = {0, 1}
# y / len tables include two empty-row sentinel slots after strip data
TREE_STRIP_Y_COUNT = TREE_STRIP_COUNT + 2
EMPTY_ROW_Y = 18

DEPTH_KINDS = (
    ["huge"] * 3
    + ["large"] * 6
    + ["small"] * 15
)
DEPTH_MAX_ROWS = {"huge": 18, "large": 17, "small": 16}

# Strip row counts per depth (monotonic; depth 23 = beyond horizon)
STRIP_LENGTHS = (
    [18, 17]
    + [15, 14, 13, 12, 11, 10]
    + [6, 6, 6, 5, 5, 5, 4, 3]
    + [3, 3, 3, 3, 2, 2, 2]
    + [0]
)

PLAYFIELD_ROWS = 22
SCREEN_COLS = 23
LOGIC_ROWS = 24

# Spectrum paper colours in attr bits 5..3
SPECTRUM_PAPER_CYAN = 5
SPECTRUM_PAPER_GREEN = 4
# Playfield char row where cyan sky meets green grass (all depths align via tree_strip_y)
SCREEN_BG_TRANSITION_Y = 10

# VIC-20 ink 0–7 (background via raster IRQ later)
SPECTRUM_INK = (0, 6, 2, 4, 5, 3, 7, 1)  # Spectrum ink 0–7 → VIC colour


def va(addr: int) -> int:
    return addr - ORG


class StripRef:
    __slots__ = ("flag", "addr")

    def __init__(self, flag: int, addr: int) -> None:
        self.flag = flag
        self.addr = addr


def rom_strip_table(code: bytes) -> list[StripRef]:
    """$6D73: flag (0=huge/large, 1=small) + little-endian gfx address."""
    i = va(ROM_STRIP_TABLE)
    if code[i] not in (0, 1):
        i += 1
    entries: list[StripRef] = []
    for _ in range(STRIP_TABLE_ENTRIES):
        flag = code[i]
        addr = code[i + 1] | (code[i + 2] << 8)
        entries.append(StripRef(flag, addr))
        i += 3
    return entries


def rom_strip_ptrs(code: bytes) -> list[int]:
    return [e.addr for e in rom_strip_table(code)[:TREE_STRIP_COUNT]]


# Placeholder chr for an empty half of a double-wide strip (must not be chr 0)
TREE_EMPTY_HALF_UDG = bytes([0, 0, 0, 0, 0, 0, 0, 1])


def strip_data_start(table_addr: int) -> int:
    """$6D73 LE word points two bytes into the first attr+8 unit."""
    return table_addr - 2


def parse_strip_unit(code: bytes, addr: int) -> tuple[int, bytes, int]:
    """One strip unit: attribute byte + 8-byte UDG definition."""
    i = va(addr)
    attr = code[i]
    udg = bytes(code[i + 1 : i + 9])
    return attr, udg, addr + 9


# One logical strip row: one (attr, udg) narrow, or left+right pair when wide.
StripRow = tuple[tuple[int, bytes], ...]


def collect_strip_units(
    code: bytes, start: int, end_addr: int
) -> list[tuple[int, bytes]]:
    """Read every attr+8 unit from start until end_addr."""
    units: list[tuple[int, bytes]] = []
    addr = start
    while addr < end_addr and va(addr) + 9 <= len(code):
        attr, udg, addr = parse_strip_unit(code, addr)
        units.append((attr, udg))
    return units


def parse_strip_rom(
    code: bytes,
    start: int,
    end_addr: int,
    *,
    wide: bool,
    max_rows: int,
) -> list[StripRow]:
    """Sequential attr+8-byte UDG units from start until next strip address."""
    units = collect_strip_units(code, start, end_addr)
    rows: list[StripRow] = []
    if wide:
        # Huge trees: left column units, then right column units — zip by row.
        half = len(units) // 2
        for i in range(min(max_rows, half)):
            attr_l, udg_l = units[i]
            attr_r, udg_r = units[half + i]
            if is_empty_udg(udg_l) and is_empty_udg(udg_r):
                continue
            rows.append(((attr_l, udg_l), (attr_r, udg_r)))
    else:
        for attr, udg in units:
            if len(rows) >= max_rows:
                break
            if is_empty_udg(udg):
                continue
            rows.append(((attr, udg),))
    return rows


def spectrum_fg(attr: int) -> int:
    ink = attr & 7
    return SPECTRUM_INK[ink]


def spectrum_paper(attr: int) -> int:
    return (attr >> 3) & 7


def is_empty_udg(udg: bytes) -> bool:
    return udg == bytes(8)


def paper_transition_index(entries: list[tuple[int, bytes]]) -> int:
    """0-based strip row of first cyan→green paper change (Spectrum sky/grass)."""
    for i in range(1, len(entries)):
        if (
            spectrum_paper(entries[i - 1][0]) == SPECTRUM_PAPER_CYAN
            and spectrum_paper(entries[i][0]) == SPECTRUM_PAPER_GREEN
        ):
            return i
    for i, (attr, _) in enumerate(entries):
        if spectrum_paper(attr) == SPECTRUM_PAPER_GREEN:
            return i
    return 0


def strip_horizon_row(length: int) -> int:
    """Strip row index that aligns cyan→green at screen row SCREEN_BG_TRANSITION_Y."""
    if length >= 12:
        return 10
    if length >= 10:
        return length - 2
    if length >= 5:
        return length - 1
    return length


def tree_strip_screen_y(length: int) -> int:
    """Playfield char row of strip top; horizon row lands at SCREEN_BG_TRANSITION_Y."""
    if length == 0:
        return 0
    return SCREEN_BG_TRANSITION_Y - strip_horizon_row(length)


def strip_udg_to_chr(
    pool: Pool,
    udg: bytes,
    used: set[bytes] | None = None,
    *,
    label: str = "tree strip",
) -> int:
    """Tree strip chr indices must never be chr_blank (0)."""
    if used is not None:
        used.add(udg)
    idx = pool.add(udg, label)
    if idx == 0:
        raise ValueError(f"tree strip UDG deduped to chr 0: {udg.hex()}")
    return idx


def strip_asm_label(depth: int, side: str | None = None) -> str:
    """ASM label base: tree_strip_0_left, tree_strip_2, …"""
    if side is None:
        return f"tree_strip_{depth}"
    side_name = "left" if side == "L" else "right"
    return f"tree_strip_{depth}_{side_name}"


def build_strip_column_side(
    pool: Pool,
    entries: list[StripRow],
    *,
    column: int,
    empty_half_chr: int,
    used_udgs: set[bytes],
    strip_depth: int,
    side: str,
) -> tuple[list[int], list[int], int]:
    """One column of a huge strip — one chr per row (empty half uses placeholder)."""
    chrs: list[int] = []
    fgs: list[int] = []
    tag = f"tree strip {strip_depth} {side}"

    for row in entries:
        attr, udg = row[column]
        if is_empty_udg(udg):
            chrs.append(empty_half_chr)
        else:
            chrs.append(strip_udg_to_chr(pool, udg, used_udgs, label=tag))
        fgs.append(spectrum_fg(attr))

    return chrs, fgs, len(entries)


def build_strip_column(
    pool: Pool,
    entries: list[StripRow],
    *,
    used_udgs: set[bytes],
    strip_depth: int,
) -> tuple[list[int], list[int], int]:
    """Single-column strip; tree_strip_len = vertical row count (not chr count)."""
    chrs: list[int] = []
    fgs: list[int] = []
    tag = f"tree strip {strip_depth}"

    for row in entries:
        attr, udg = row[0]
        if is_empty_udg(udg):
            continue
        chrs.append(strip_udg_to_chr(pool, udg, used_udgs, label=tag))
        fgs.append(spectrum_fg(attr))

    return chrs, fgs, len(entries)


def aligned_rows(code: bytes, start: int, end: int) -> list[bytes]:
    chunk = code[va(start) : va(end)]
    return [bytes(chunk[i : i + 8]) for i in range(0, len(chunk) - 7, 8)]


def composite_tank_obscured(tank_row: bytes, trunk_row: bytes) -> bytes:
    out = bytearray(8)
    for i in range(8):
        out[i] = tank_row[i] & ~trunk_row[i]
    return bytes(out)


def digit_row(d: int, row: int) -> int:
    """Fallback 8×8 row for UI glyphs when UI.png / UI.txt are absent."""
    fonts = {
        0: [0x3C, 0x66, 0x6E, 0x76, 0x66, 0x66, 0x3C, 0x00],
        1: [0x18, 0x38, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x00],
        2: [0x3C, 0x66, 0x06, 0x1C, 0x30, 0x60, 0x7E, 0x00],
        3: [0x3C, 0x66, 0x06, 0x1C, 0x06, 0x66, 0x3C, 0x00],
        4: [0x0C, 0x1C, 0x2C, 0x4C, 0x7E, 0x0C, 0x0C, 0x00],
        5: [0x7E, 0x60, 0x7C, 0x06, 0x06, 0x66, 0x3C, 0x00],
        6: [0x1C, 0x30, 0x60, 0x7C, 0x66, 0x66, 0x3C, 0x00],
        7: [0x7E, 0x06, 0x0C, 0x18, 0x30, 0x30, 0x30, 0x00],
        8: [0x3C, 0x66, 0x66, 0x3C, 0x66, 0x66, 0x3C, 0x00],
        9: [0x3C, 0x66, 0x66, 0x3E, 0x06, 0x0C, 0x38, 0x00],
    }
    if d == ord("$"):
        pat = [0x3C, 0x6A, 0xFF, 0x6A, 0x6A, 0x7E, 0x18, 0x00]
        return pat[row]
    if d == ord("B"):
        pat = [0x18, 0x3C, 0x7E, 0xFF, 0x7E, 0x3C, 0x18, 0x00]
        return pat[row]
    return fonts.get(d, [0] * 8)[row]


def hardcoded_ui_glyph(ch: str) -> bytes:
    if ch == "$":
        key: int | str = ord("$")
    elif ch == "B":
        key = ord("B")
    elif ch.isdigit():
        key = int(ch)
    else:
        raise ValueError(f"no hardcoded UI glyph for {ch!r}")
    return bytes([digit_row(key, row) for row in range(8)])


def _png_pixel_on(px: tuple[int, ...]) -> bool:
    """Treat bright opaque pixels as set bits (white glyph on dark background)."""
    if len(px) >= 4 and px[3] < 128:
        return False
    return sum(px[:3]) / len(px[:3]) > 127


def _png_cell_to_udg(img, col: int) -> bytes:
    x0 = col * 8
    out = bytearray(8)
    for y in range(8):
        byte = 0
        for x in range(8):
            if _png_pixel_on(img.getpixel((x0 + x, y))):
                byte |= 1 << (7 - x)
        out[y] = byte
    return bytes(out)


def load_ui_png(png_path: Path, txt_path: Path) -> list[tuple[str, bytes]]:
    """Load UI.png (8N×8); return (char, udg) pairs in UI.txt order."""
    from PIL import Image  # noqa: WPS433

    chars = txt_path.read_text(encoding="utf-8").strip()
    if not chars:
        raise ValueError(f"{txt_path} is empty")
    img = Image.open(png_path).convert("RGBA")
    if img.height != 8:
        raise ValueError(f"{png_path} height must be 8, got {img.height}")
    expected_w = 8 * len(chars)
    if img.width != expected_w:
        raise ValueError(
            f"{png_path} width must be {expected_w} ({len(chars)} glyphs), got {img.width}"
        )
    return [(ch, _png_cell_to_udg(img, i)) for i, ch in enumerate(chars)]


def load_ui_glyphs() -> tuple[list[tuple[str, bytes]], str]:
    """Return UI (char, udg) pairs in pool emission order."""
    if UI_PNG.is_file() and UI_TXT.is_file():
        txt = UI_TXT.read_text(encoding="utf-8").strip()
        return load_ui_png(UI_PNG, UI_TXT), f"UI.png ({txt!r})"
    if UI_PNG.is_file() ^ UI_TXT.is_file():
        missing = UI_TXT if UI_PNG.is_file() else UI_PNG
        print(f"Warning: UI source incomplete — missing {missing.name}, using hardcoded UI")
    return [(ch, hardcoded_ui_glyph(ch)) for ch in UI_GLYPH_ORDER], "hardcoded"


def required_ui_equates() -> dict[str, str]:
    """Game code equate name → ASCII character in UI.txt."""
    return {"$": "chr_ui_base", "B": "chr_bike", "0": "chr_digit_0"}


def ui_glyph_label(ch: str) -> str:
    if ch == "$":
        return "ui score ($)"
    if ch == "B":
        return "ui bike (B)"
    if ch.isdigit():
        return f"ui digit {ch}"
    return f"ui {ch!r}"


def parse_handlebar_byte_line(line: str) -> list[int]:
    return [
        int(token.strip().replace("$", ""), 16)
        for token in line.split(",")
        if token.strip()
    ]


def matrix_columns_to_udgs(matrix: list[list[int]]) -> list[bytes]:
    """Column-major strip rows → one 8-byte UDG per column."""
    if not matrix:
        return []
    cols = len(matrix[0])
    if any(len(row) != cols for row in matrix):
        raise ValueError("ragged handlebar matrix")
    return [bytes(matrix[row][col] for row in range(len(matrix))) for col in range(cols)]


def parse_handlebar_source(path: Path) -> list[tuple[str, list[bytes]]]:
    """Parse handlebar_source.txt into labelled 8×8 UDG lists."""
    sections: list[tuple[str, list[bytes]]] = []
    name = ""
    matrix: list[list[int]] = []

    def flush() -> None:
        nonlocal matrix, name
        if matrix:
            sections.append((name, matrix_columns_to_udgs(matrix)))
            matrix = []

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith(";"):
            lower = line.lower()
            if "udg row" in lower or "bike body" in lower:
                flush()
                name = line.lstrip(";").strip()
            continue
        if "$" in line:
            matrix.append(parse_handlebar_byte_line(line))
    flush()
    return sections


def handlebar_section_slug(name: str) -> str:
    lower = name.lower()
    if "bike body" in lower:
        row = "1" if "row 1" in lower else "2"
        return f"bike_body_{row}"
    pose = "fwd"
    if " left " in f" {lower} ":
        pose = "left"
    elif " right " in f" {lower} ":
        pose = "right"
    row = "1" if "row 1" in lower else "2"
    return f"handlebar_{pose}_{row}"


BIKE_BODY_POOL_ORDER = (
    "bike_body_1",
    "bike_body_2",
)

# Runtime-copied from playerbike.asm; pool holds blank placeholders only.
HANDLEBAR_FWD_CHR_SLOTS = 14


def bike_body_chr_rows(
    pool: Pool, sections: list[tuple[str, list[bytes]]]
) -> tuple[list[int], list[int]]:
    """Map 9×2 bike body logical columns to deduped pool chr indices."""
    by_slug = {handlebar_section_slug(name): udgs for name, udgs in sections}
    row1 = [pool.index[u] for u in by_slug["bike_body_1"]]
    row2 = [pool.index[u] for u in by_slug["bike_body_2"]]
    return row1, row2


def emit_bike_body_chr_asm(row1: list[int], row2: list[int]) -> list[str]:
    fmt = lambda row: ", ".join(str(c) for c in row)
    return [
        "; Bike body draw table — 9 columns × 2 rows (screen order, left→right)",
        "; Logical cols 0–8; chr indices after pool dedup (not sequential).",
        "bike_body_width = 9",
        "bike_body_height = 2",
        "bike_body_chr",
        f"    !byte {fmt(row1)}    ; row 1 (top)",
        f"    !byte {fmt(row2)}    ; row 2 (bottom)",
        "",
    ]


def emit_ui_frame_asm(
    row1: list[int], row2: list[int], solid_chr: int, blank_chr: int = 0
) -> list[str]:
    """Emit SCREEN_COLS x 4 UI frame around the 9x2 bike body."""

    b = solid_chr
    z = blank_chr
    w = SCREEN_COLS
    side = (w - len(row1)) // 2

    chr_rows = [
        [b] * side + row1 + [b] * side,
        [b, z, z, z, z, z, b] + row2 + [b, z, z, z, z, z, b],
        [b] + [z] * (w - 2) + [b],
        [b] * w,
    ]

    body_cols = ["BLACK", "BLACK", "BLACK", "BLUE", "BLUE", "BLUE", "BLACK", "BLACK", "BLACK"]
    col_rows = [
        ["PURPLE"] * side + body_cols + ["PURPLE"] * side,
        ["PURPLE", "BLACK", "BLACK", "BLACK", "BLACK", "BLACK", "PURPLE"]
        + body_cols
        + ["PURPLE", "BLACK", "BLACK", "BLACK", "BLACK", "BLACK", "PURPLE"],
        ["PURPLE"] + ["BLACK"] * (w - 2) + ["PURPLE"],
        ["PURPLE"] * w,
    ]

    fmt_chr = lambda row: ", ".join(str(c) for c in row)
    fmt_col = lambda row: ", ".join(row)
    return [
        f"; UI frame + bike body draw table — {w} columns x 4 rows",
        "; B = solid block, 0 = blank, bike body embedded in rows 1-2.",
        f"ui_frame_width = {w}",
        "ui_frame_height = 4",
        "ui_frame_chr",
        *(f"    !byte {fmt_chr(row)}" for row in chr_rows),
        "",
        "ui_frame_col",
        *(f"    !byte {fmt_col(row)}" for row in col_rows),
        "",
    ]


def add_bike_body_sections(
    pool: Pool, sections: list[tuple[str, list[bytes]]]
) -> dict[str, dict[str, int]]:
    by_slug: dict[str, tuple[str, list[bytes]]] = {}
    for name, udgs in sections:
        by_slug[handlebar_section_slug(name)] = (name, udgs)

    meta: dict[str, dict[str, int]] = {}
    for slug in BIKE_BODY_POOL_ORDER:
        if slug not in by_slug:
            continue
        name, udgs = by_slug[slug]
        start = len(pool.rows)
        for i, udg in enumerate(udgs):
            pool.add(udg, f"{slug} {i}")
        meta[slug] = {"start": start, "count": len(udgs), "label": name}
    return meta


class Pool:
    """Chr 0 is always blank."""

    def __init__(self) -> None:
        blank = bytes(8)
        self.rows: list[bytes] = [blank]
        self.labels: list[str] = ["blank"]
        self.index: dict[bytes, int] = {blank: 0}

    def add(self, row: bytes, label: str = "") -> int:
        if row in self.index:
            return self.index[row]
        idx = len(self.rows)
        self.rows.append(row)
        self.labels.append(label or "gfx")
        self.index[row] = idx
        return idx

    def reserve(self, count: int, prefix: str) -> int:
        """Reserve chr slots (blank); not deduped — for runtime UDG copy targets."""
        start = len(self.rows)
        blank = bytes(8)
        for i in range(count):
            self.rows.append(blank)
            self.labels.append(f"{prefix} {i} (reserved)")
        return start


def emit_tree_strips_asm(
    strips: list[tuple[list[int], list[int]]],
    strip_labels: list[str],
    lens: list[int],
    ys: list[int],
    rom_ptrs: list[int],
    strip_comments: list[str],
) -> list[str]:
    lines = [
        "; Auto-generated by tools/convert_gfx.py — do not edit",
        ";",
        "; Spectrum tree draw model:",
        ";   $6D73 — 25 strip gfx refs (flag + LE addr; first entry repeated)",
        ";   flag 0 = huge/large, 1 = small; attr + 8-byte UDG, repeat",
        ";   Table LE addr − 2 = first attr byte; next strip addr − 2 = end",
        ";   Strips 0–3: huge trunks split L/R (was interleaved 2× wide on Spectrum).",
        "; VIC tables:",
        ";   tree_strip_ptr    → column of chr indices (no chr 0 in strips)",
        ";   tree_strip_fg_ptr → matching ink per chr",
        f";   tree_strip_y      → playfield char row of strip top ({TREE_STRIP_Y_COUNT} entries; last two = empty row)",
        ";   tree_strip_len    → vertical row count per depth",
        "",
        f"tree_strip_count = {TREE_STRIP_COUNT}",
        "",
        "tree_strip_len",
        "    !byte " + ", ".join(str(n) for n in lens),
        "",
        "tree_strip_y",
        "    !byte " + ", ".join(str(y) for y in ys),
        "",
        "tree_strip_ptr",
    ]
    for label in strip_labels:
        lines.append(f"    !word {label}_chr")
    lines.append("")
    lines.append("tree_strip_fg_ptr")
    for label in strip_labels:
        lines.append(f"    !word {label}_fg")
    lines.append("")

    for label, (chrs, fgs), comment in zip(strip_labels, strips, strip_comments):
        lines.append(comment)
        lines.append(f"{label}_chr")
        for i in range(0, len(chrs), 16):
            chunk = chrs[i : i + 16]
            lines.append("    !byte " + ", ".join(str(c) for c in chunk))
        lines.append(f"{label}_fg")
        for i in range(0, len(fgs), 16):
            chunk = fgs[i : i + 16]
            lines.append("    !byte " + ", ".join(str(c) for c in chunk))
        lines.append("")

    lines.append("; Spectrum $64AB tree density by sector (1..8)")
    lines.append("tree_density")
    lines.append("    !byte 7, 15, 25, 35, 45, 55, 65, 75")
    lines.append("")
    return lines


def main() -> int:
    bin_path = Path(sys.argv[1]) if len(sys.argv) > 1 else BIN_DEFAULT
    code = bin_path.read_bytes()
    pool = Pool()
    meta: dict = {"sprites": {}}

    chr_blank = 0
    meta["chr_blank"] = chr_blank

    strip_refs = rom_strip_table(code)
    empty_half_chr = pool.add(TREE_EMPTY_HALF_UDG, "tree empty half")
    tree_udgs: set[bytes] = set()

    strips: list[tuple[list[int], list[int]]] = []
    strip_labels: list[str] = []
    strip_comments: list[str] = []
    lens: list[int] = []
    ys: list[int] = []
    strip_meta: list[dict] = []
    rom_ptrs: list[int] = []

    for depth in range(SPECTRUM_STRIP_COUNT):
        ref = strip_refs[depth]
        wide = depth in TREE_HUGE_SPLIT_DEPTHS
        row_limit = STRIP_LENGTHS[depth]
        end_addr = strip_data_start(
            strip_refs[depth + 1].addr
            if depth + 1 < len(strip_refs)
            else ROM_TREE_GFX_END
        )
        strip_row = tree_strip_screen_y(row_limit)

        if row_limit == 0:
            label = strip_asm_label(depth)
            strips.append(([], []))
            strip_labels.append(label)
            strip_comments.append(
                f"; depth {depth} — Spectrum ${ref.addr:04X}, empty"
            )
            lens.append(0)
            ys.append(EMPTY_ROW_Y)
            rom_ptrs.append(ref.addr)
            strip_meta.append(
                {
                    "strip_index": len(strips) - 1,
                    "depth": depth,
                    "spectrum_depth": depth,
                    "side": None,
                    "label": label,
                    "rom_ptr": f"${ref.addr:04X}",
                    "flag": ref.flag,
                    "wide": False,
                    "len": 0,
                    "chr_count": 0,
                    "screen_row": EMPTY_ROW_Y,
                    "y": EMPTY_ROW_Y,
                }
            )
            continue

        rom_rows = parse_strip_rom(
            code,
            strip_data_start(ref.addr),
            end_addr,
            wide=wide,
            max_rows=row_limit,
        )
        rom_trans = [(r[0][0], r[0][1]) for r in rom_rows]
        horizon = strip_horizon_row(row_limit)
        transition = paper_transition_index(rom_trans)

        if wide:
            for column, side in ((0, "L"), (1, "R")):
                chrs, fgs, row_count = build_strip_column_side(
                    pool,
                    rom_rows,
                    column=column,
                    empty_half_chr=empty_half_chr,
                    used_udgs=tree_udgs,
                    strip_depth=depth,
                    side=side,
                )
                label = strip_asm_label(depth, side)
                strips.append((chrs, fgs))
                strip_labels.append(label)
                side_name = "left" if side == "L" else "right"
                strip_comments.append(
                    f"; depth {depth} {side_name} — Spectrum ${ref.addr:04X}, "
                    f"{row_count} rows, {len(chrs)} chrs"
                )
                lens.append(row_count)
                ys.append(strip_row)
                rom_ptrs.append(ref.addr)
                strip_meta.append(
                    {
                        "strip_index": len(strips) - 1,
                        "depth": depth,
                        "spectrum_depth": depth,
                        "side": side,
                        "label": label,
                        "rom_ptr": f"${ref.addr:04X}",
                        "flag": ref.flag,
                        "wide": True,
                        "len": row_count,
                        "chr_count": len(chrs),
                        "screen_row": strip_row,
                        "y": strip_row,
                        "horizon_row": horizon,
                        "transition_row": transition,
                    }
                )
                if chrs and min(chrs) == 0:
                    raise ValueError(f"strip {len(strips) - 1} contains chr 0")
        else:
            chrs, fgs, row_count = build_strip_column(
                pool,
                rom_rows,
                used_udgs=tree_udgs,
                strip_depth=depth,
            )
            label = strip_asm_label(depth)
            strips.append((chrs, fgs))
            strip_labels.append(label)
            strip_comments.append(
                f"; depth {depth} — Spectrum ${ref.addr:04X}, "
                f"{row_count} rows, {len(chrs)} chrs"
            )
            lens.append(row_count)
            ys.append(strip_row)
            rom_ptrs.append(ref.addr)
            strip_meta.append(
                {
                    "strip_index": len(strips) - 1,
                    "depth": depth,
                    "spectrum_depth": depth,
                    "side": None,
                    "label": label,
                    "rom_ptr": f"${ref.addr:04X}",
                    "flag": ref.flag,
                    "wide": False,
                    "len": row_count,
                    "chr_count": len(chrs),
                    "screen_row": strip_row,
                    "y": strip_row,
                    "horizon_row": horizon,
                    "transition_row": transition,
                }
            )
            if chrs and min(chrs) == 0:
                raise ValueError(f"strip {len(strips) - 1} contains chr 0")

    if len(strips) != TREE_STRIP_COUNT:
        raise ValueError(f"expected {TREE_STRIP_COUNT} strips, got {len(strips)}")
    if len(strip_labels) != TREE_STRIP_COUNT:
        raise ValueError(
            f"expected {TREE_STRIP_COUNT} strip labels, got {len(strip_labels)}"
        )

    # Two empty-row sentinel slots (y=18) for auto column clear.
    ys.append(EMPTY_ROW_Y)
    lens.append(0)
    ys.append(EMPTY_ROW_Y)
    lens.append(0)

    meta["tree_strips"] = strip_meta
    meta["tree_strip_count"] = TREE_STRIP_COUNT
    meta["trees_unique"] = len(tree_udgs)
    tree_chr_end = len(pool.rows)
    meta["tree_chr_end"] = tree_chr_end

    def assign_group(name: str, rows: list[bytes], reserve: int, label: str) -> int:
        start = pool.add(rows[0], label) if rows else 0
        for i, r in enumerate(rows[1:], 1):
            pool.add(r, f"{label} {i}")
        meta["sprites"][name] = {"start": start, "count": len(rows), "reserve": reserve}
        return start

    enemies = aligned_rows(code, 0x717A, 0x7204)
    assign_group("enemies", enemies, CHR_ENEMY, "enemy bike")

    heli = aligned_rows(code, 0x631A, 0x633A)[:2]
    assign_group("helicopter", heli, CHR_HELICOPTER, "helicopter")

    tank = aligned_rows(code, 0x6C07, 0x6C17)[:2]
    tank_start = len(pool.rows)
    for i, r in enumerate(tank):
        pool.add(r, "tank" if i == 0 else f"tank {i}")
    trunk = next((u for u in tree_udgs if any(u)), bytes([0x18] * 8))
    for i, r in enumerate(tank):
        pool.add(
            composite_tank_obscured(r, trunk),
            "tank obscured" if i == 0 else f"tank obscured {i}",
        )
    meta["sprites"]["tank"] = {"start": tank_start, "count": 4}

    bolt_rows = aligned_rows(code, 0x7214, 0x7246)[:1]
    assign_group("bolt", bolt_rows, CHR_BOLT, "bolt")

    exp_rows = aligned_rows(code, 0x6A7A, 0x6AC2)[:CHR_EXPLOSION]
    assign_group("explosion", exp_rows, CHR_EXPLOSION, "explosion")

    ui_order, ui_source = load_ui_glyphs()
    ui_start = len(pool.rows)
    ui_chr: dict[str, int] = {}
    for ch, udg in ui_order:
        idx = pool.add(udg, ui_glyph_label(ch))
        ui_chr.setdefault(ch, idx)
    for ch, equate in required_ui_equates().items():
        if ch not in ui_chr:
            raise ValueError(
                f"UI must include {ch!r} ({equate}); "
                f"have {''.join(c for c, _ in ui_order)!r}"
            )
    meta["sprites"]["ui"] = {
        "start": ui_start,
        "count": len(ui_order),
        "pool_slots": len(pool.rows) - ui_start,
        "source": ui_source,
        "order": "".join(ch for ch, _ in ui_order),
        "chr": ui_chr,
    }
    ui_end = len(pool.rows)

    ui_frame_lines: list[str] = []
    if HANDLEBAR_SOURCE.is_file():
        hb_sections = parse_handlebar_source(HANDLEBAR_SOURCE)
        meta["handlebars"] = add_bike_body_sections(pool, hb_sections)
        hb = meta["handlebars"]
        body_count = hb["bike_body_1"]["count"] + hb["bike_body_2"]["count"]
        body_end = hb["bike_body_2"]["start"] + hb["bike_body_2"]["count"] - 1
        handlebar_fwd_start = pool.reserve(
            HANDLEBAR_FWD_CHR_SLOTS, "handlebar_fwd"
        )
        fwd_end = handlebar_fwd_start + HANDLEBAR_FWD_CHR_SLOTS - 1
        meta["handlebar_playfield"] = {
            "bike_body_start": hb["bike_body_1"]["start"],
            "bike_body_count": body_count,
            "handlebar_fwd_start": handlebar_fwd_start,
            "handlebar_fwd_count": HANDLEBAR_FWD_CHR_SLOTS,
            "fits_in_256": fwd_end < PLAYFIELD_CHR_LIMIT and body_end < PLAYFIELD_CHR_LIMIT,
        }
        row1, row2 = bike_body_chr_rows(pool, hb_sections)
        solid_chr = pool.index[bytes([0xFF] * 8)]
        meta["ui_frame_chr"] = {"row1": row1, "row2": row2, "solid_chr": solid_chr}
        ui_frame_lines = emit_ui_frame_asm(row1, row2, solid_chr)
    else:
        meta["handlebars"] = {}

    meta["total_chr"] = len(pool.rows)
    over = len(pool.rows) - PLAYFIELD_CHR_LIMIT
    meta["spare"] = -over if over > 0 else PLAYFIELD_CHR_LIMIT - len(pool.rows)

    OUT_ASM.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "; Auto-generated by tools/convert_gfx.py — do not edit",
        f"; {len(pool.rows)} unique glyphs",
        f"; playfield budget ({PLAYFIELD_CHR_LIMIT}): "
        + (
            f"{meta['spare']} spare"
            if meta["spare"] >= 0
            else f"{-meta['spare']} over limit"
        ),
        f"; tree strips: {meta['trees_unique']} UDGs in chr 1..{tree_chr_end - 1}",
        "",
        "gfx_pool_size = " + str(len(pool.rows)),
        "",
        "gfx_pool",
    ]
    for i, row in enumerate(pool.rows):
        hexes = ", ".join(f"${b:02x}" for b in row)
        lines.append(f"    !byte {hexes}    ; chr {i} — {pool.labels[i]}")
    lines.append("gfx_pool_end = *")
    lines.append("")
    lines.extend(ui_frame_lines)
    OUT_ASM.write_text("\n".join(lines) + "\n", encoding="utf-8")

    ui = meta["sprites"]["ui"]
    equates = [
        "; Auto-generated by tools/convert_gfx.py — do not edit",
        f"gfx_pool_size = {len(pool.rows)}",
        f"chr_blank = {chr_blank}",
        f"chr_ui_base = {ui['chr']['$']}",
        f"chr_bike = {ui['chr']['B']}",
        f"chr_digit_0 = {ui['chr']['0']}",
        f"TREE_MARK_SMALL = ${TREE_MARK_SMALL:02x}",
        f"TREE_MARK_LARGE = ${TREE_MARK_LARGE:02x}",
    ]
    if meta.get("handlebars"):
        hb = meta["handlebars"]
        hp = meta["handlebar_playfield"]
        equates.append(f"chr_bike_body = {hb['bike_body_1']['start']}")
        equates.append(f"chr_handlebar_fwd = {hp['handlebar_fwd_start']}")
    equates.append("")
    OUT_EQUATES.write_text("\n".join(equates) + "\n", encoding="utf-8")

    strip_lines = emit_tree_strips_asm(
        strips, strip_labels, lens, ys, rom_ptrs, strip_comments
    )
    OUT_STRIPS.write_text("\n".join(strip_lines) + "\n", encoding="utf-8")
    OUT_JSON.write_text(json.dumps(meta, indent=2), encoding="utf-8")

    spare_msg = (
        f"{meta['spare']} spare in {PLAYFIELD_CHR_LIMIT}"
        if meta["spare"] >= 0
        else f"{-meta['spare']} over {PLAYFIELD_CHR_LIMIT}"
    )
    print(f"Wrote {OUT_ASM} ({len(pool.rows)} glyphs, {spare_msg})")
    print(f"  tree UDGs: {meta['trees_unique']} unique, chr 1..{tree_chr_end - 1}")
    print(f"  UI glyphs: {ui_source} ({ui['count']} chars, chr {ui_start}..{ui_end - 1})")
    if meta.get("handlebars"):
        hp = meta["handlebar_playfield"]
        fit = "yes" if hp["fits_in_256"] else "no"
        print(
            f"  handlebars: bike body chr {hp['bike_body_start']}"
            f"..+{hp['bike_body_count']}, "
            f"fwd chr {hp['handlebar_fwd_start']}..+{hp['handlebar_fwd_count']} "
            f"(fits in 256: {fit})"
        )
    print(f"Wrote {OUT_EQUATES}")
    print(f"Wrote {OUT_STRIPS}")
    print(f"Wrote {OUT_JSON}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
