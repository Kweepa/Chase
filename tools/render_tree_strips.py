#!/usr/bin/env python3
"""Render 24 tree strip columns to a verification PNG (1:1 pixels)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GFX_POOL = ROOT / "build" / "gfx_pool.asm"
TREE_STRIPS = ROOT / "build" / "tree_strips.asm"
OUT_PNG = ROOT / "build" / "tree_strips_verify.png"
BIN_DEFAULT = ROOT / "build" / "deathchase.bin"

TREE_STRIP_WIDE = {0, 1}
SCREEN_BG_TRANSITION_Y = 10
SLICE_GAP = 8
PLAYFIELD_ROWS = 22

# VIC-20 colour indices → RGB (approximate)
VIC_RGB = (
    (0, 0, 0),
    (255, 255, 255),
    (136, 0, 0),
    (104, 214, 198),
    (164, 92, 229),
    (0, 168, 68),
    (0, 0, 204),
    (212, 204, 72),
)


def parse_num(token: str) -> int:
    token = token.strip().split(";", 1)[0].strip()
    if token.startswith("$"):
        return int(token[1:], 16)
    return int(token, 0)


def parse_byte_line(line: str) -> list[int]:
    return [parse_num(x) for x in line.split("!byte", 1)[1].split(",") if x.strip()]


def parse_gfx_pool(path: Path) -> list[bytes]:
    rows: list[bytes] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if "!byte" not in line:
            continue
        vals = parse_byte_line(line)
        rows.append(bytes(vals[:8]))
    return rows


def parse_tree_strips(path: Path) -> tuple[list[int], list[int], list[list[int]], list[list[int]]]:
    text = path.read_text(encoding="utf-8")
    lens = [int(x) for x in re.search(r"tree_strip_len\s+!byte\s+([^\n]+)", text).group(1).split(",")]
    ym = re.search(r"tree_strip_y\s+!byte\s+([^\n]+)", text)
    if ym:
        screen_rows = [int(x) for x in ym.group(1).split(",")]
    else:
        offsets = [
            int(x)
            for x in re.search(r"tree_strip_offset\s+!byte\s+([^\n]+)", text).group(1).split(",")
        ]
        screen_rows = [o // 22 for o in offsets]

    chrs: list[list[int]] = []
    fgs: list[list[int]] = []
    for d in range(24):
        cm = re.search(rf"tree_strip_{d}_chr\s+((?:\s+!byte[^\n]+\n?)+)", text)
        fm = re.search(rf"tree_strip_{d}_fg\s+((?:\s+!byte[^\n]+\n?)+)", text)
        cvals: list[int] = []
        fvals: list[int] = []
        if cm:
            for line in cm.group(1).splitlines():
                if "!byte" in line:
                    cvals.extend(parse_byte_line(line))
        if fm:
            for line in fm.group(1).splitlines():
                if "!byte" in line:
                    fvals.extend(parse_byte_line(line))
        chrs.append(cvals)
        fgs.append(fvals)
    return lens, screen_rows, chrs, fgs


def load_huge_fg(bin_path: Path) -> dict[int, list[int]]:
    """Spectrum ink per chr row for huge strips 0–1 (fg table is 0 in asm)."""
    sys.path.insert(0, str(ROOT / "tools"))
    from convert_gfx import (  # noqa: WPS433
        STRIP_LENGTHS,
        TREE_STRIP_WIDE,
        parse_strip_rom,
        rom_strip_table,
        spectrum_fg,
        strip_data_start,
    )

    if not bin_path.is_file():
        return {}
    code = bin_path.read_bytes()
    refs = rom_strip_table(code)
    out: dict[int, list[int]] = {}
    for d in sorted(TREE_STRIP_WIDE):
        ref = refs[d]
        end_addr = strip_data_start(
            refs[d + 1].addr if d + 1 < len(refs) else 0x7CA1
        )
        rows = parse_strip_rom(
            code,
            strip_data_start(ref.addr),
            end_addr,
            wide=True,
            max_rows=STRIP_LENGTHS[d],
        )
        fgs: list[int] = []
        for pair in rows:
            fgs.append(spectrum_fg(pair[0][0]))
            fgs.append(spectrum_fg(pair[1][0]))
        out[d] = fgs
    return out


def blit_glyph(
    img: Image.Image,
    x0: int,
    y0: int,
    glyph: bytes,
    ink: int,
    paper: int,
) -> None:
    ink_rgb = VIC_RGB[ink & 7]
    paper_rgb = VIC_RGB[paper & 7]
    px = img.load()
    for row, byte in enumerate(glyph):
        y = y0 + row
        if y < 0 or y >= img.height:
            continue
        for col in range(8):
            x = x0 + col
            if x < 0 or x >= img.width:
                continue
            on = (byte >> (7 - col)) & 1
            px[x, y] = ink_rgb if on else paper_rgb


def slice_width(depth: int) -> int:
    return 16 if depth in TREE_STRIP_WIDE else 8


def render(
    pool: list[bytes],
    lens: list[int],
    ys: list[int],
    chrs: list[list[int]],
    fgs: list[list[int]],
    huge_fg: dict[int, list[int]],
) -> Image.Image:
    widths = [slice_width(d) for d in range(24)]
    total_w = sum(widths) + SLICE_GAP * 23
    total_h = PLAYFIELD_ROWS * 8
    img = Image.new("RGB", (total_w, total_h), VIC_RGB[3])  # cyan sky default

    # grass below horizon
    px = img.load()
    horizon_px = SCREEN_BG_TRANSITION_Y * 8
    for y in range(horizon_px, total_h):
        for x in range(total_w):
            px[x, y] = VIC_RGB[5]

    x_cursor = 0
    for d in range(24):
        wide = d in TREE_STRIP_WIDE
        row_len = lens[d]
        y_base = ys[d] * 8
        strip_chrs = chrs[d]
        strip_fgs = fgs[d]
        huge = huge_fg.get(d, [])

        if row_len == 0:
            x_cursor += widths[d] + SLICE_GAP
            continue

        if wide:
            for row in range(row_len):
                li = row * 2
                ri = li + 1
                if ri >= len(strip_chrs):
                    break
                left = pool[strip_chrs[li]] if strip_chrs[li] < len(pool) else bytes(8)
                right = pool[strip_chrs[ri]] if strip_chrs[ri] < len(pool) else bytes(8)
                row_y = y_base + row * 8
                paper = 3 if (y_base // 8 + row) < SCREEN_BG_TRANSITION_Y else 5
                fg_l = huge[li] if li < len(huge) else 1
                fg_r = huge[ri] if ri < len(huge) else 1
                blit_glyph(img, x_cursor, row_y, left, fg_l, paper)
                blit_glyph(img, x_cursor + 8, row_y, right, fg_r, paper)
        else:
            for row in range(row_len):
                if row >= len(strip_chrs):
                    break
                glyph = pool[strip_chrs[row]] if strip_chrs[row] < len(pool) else bytes(8)
                row_y = y_base + row * 8
                paper = 3 if (y_base // 8 + row) < SCREEN_BG_TRANSITION_Y else 5
                ink = strip_fgs[row] if row < len(strip_fgs) else 1
                blit_glyph(img, x_cursor, row_y, glyph, ink, paper)

        x_cursor += widths[d] + SLICE_GAP

    return img


def main() -> int:
    pool = parse_gfx_pool(GFX_POOL)
    lens, ys, chrs, fgs = parse_tree_strips(TREE_STRIPS)
    huge_fg = load_huge_fg(BIN_DEFAULT)
    img = render(pool, lens, ys, chrs, fgs, huge_fg)
    OUT_PNG.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT_PNG)
    print(f"Wrote {OUT_PNG} ({img.width}x{img.height})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
