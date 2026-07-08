#!/usr/bin/env python3
"""Generate scroll.asm — per-cell copy offsets for tree map scroll+shunt.

Map layout (front row at lowest address):
  row 0 = front (bike), row 23 = back (horizon, planted separately)

Forward table: row_shift + symmetric per-row shunt (widths from tree_strip).
Left/right: forward offset -1 / +1 (right pull from higher addr = right-to-left).

Rows 1..13 in tables; depth-only rows 0..10 and 14..22 handled in game code.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_ASM = ROOT / "scroll.asm"
GFX_INDEX = ROOT / "build" / "gfx_index.json"

COLS = 22
ROWS = 24
STRIDE = COLS

SCROLL_DIRECT_ROWS = 11
SCROLL_DEEP_ROW_FIRST = 14

SHUNT_ROW_FIRST = 1
SHUNT_ROW_LAST = 13

DEPTH_LEFT = STRIDE - 1   # $15 — corridor, left of centre
DEPTH_CENTER = STRIDE     # $16 — corridor centre columns
DEPTH_RIGHT = STRIDE + 1  # $17 — corridor, right of centre
CENTER_COL_LO = COLS // 2 - 1  # col 10
CENTER_COL_HI = COLS // 2      # col 11

STEER_SHIFT = 1

# Row 0 front shunt simulated but not emitted in tables.
FRONT_ROW_LEFT_WIDTH = 15


def left_shunt_row(row: list[int], width: int) -> list[int]:
    """Shift cols 0..width-1 left; clear col width; cols width+1.. unchanged."""
    if width <= 0:
        return row[:]
    out = row[:]
    limit = min(width, COLS)
    for c in range(limit - 1):
        out[c] = row[c + 1]
    if limit < COLS:
        out[limit - 1] = row[limit]
        out[limit] = 0
    return out


def right_shunt_row_symmetric(row: list[int], width: int) -> list[int]:
    """Shift rightmost `width` cols right; clear col COLS-width-1 (mirror of left)."""
    if width <= 0:
        return row[:]
    out = row[:]
    start = COLS - width
    clear_col = start - 1
    if clear_col < 0:
        return out
    for c in range(COLS - 1, start, -1):
        out[c] = row[c - 1]
    out[clear_col] = 0
    return out


def apply_symmetric_shunt(row: list[int], width: int) -> list[int]:
    g = left_shunt_row(row, width)
    return right_shunt_row_symmetric(g, width)


def row_shift(grid: list[list[int]]) -> list[list[int]]:
    out = [[0] * COLS for _ in range(ROWS)]
    for r in range(ROWS - 1):
        out[r] = grid[r + 1][:]
    out[ROWS - 1] = grid[ROWS - 1][:]
    return out


def load_row_widths() -> dict[int, int]:
    """Per logic row 1..13: symmetric shunt half-width from tree_strip metadata."""
    data = json.loads(GFX_INDEX.read_text(encoding="utf-8"))
    strips = {s["depth"]: s for s in data["tree_strips"]}
    widths: dict[int, int] = {}
    max_w = COLS // 2 - 2

    for r in range(SHUNT_ROW_FIRST, SHUNT_ROW_LAST + 1):
        strip = strips[r]
        if strip.get("wide"):
            w = strip["chr_count"] // 4
        else:
            w = max(2, (strip["chr_count"] + 1) // 2)
        widths[r] = min(max(2, w), max_w)

    return widths


def scroll_grid_forward(widths: dict[int, int]) -> list[list[int]]:
    """One scroll tick on marker grid — forward (symmetric) shunt only."""
    old = [[0] * COLS for _ in range(ROWS)]
    for r in range(ROWS):
        for c in range(COLS):
            old[r][c] = r * STRIDE + c + 1

    g = row_shift(old)

    for r in range(SHUNT_ROW_FIRST, SHUNT_ROW_LAST + 1):
        g[r] = apply_symmetric_shunt(g[r], widths[r])

    g[0] = left_shunt_row(g[0], FRONT_ROW_LEFT_WIDTH)

    return g


def corridor_depth_offset(col: int) -> int:
    """$15 left of centre, $16 at centre, $17 right — widens as corridor grows per row."""
    if col < CENTER_COL_LO:
        return DEPTH_LEFT
    if col <= CENTER_COL_HI:
        return DEPTH_CENTER
    return DEPTH_RIGHT


def finalize_forward_table(table: list[int]) -> list[int]:
    """Symmetrize zero clears only; corridor pure-depth (+22) -> $15/$16/$17 by column."""
    out = table[:]
    for r in range(SHUNT_ROW_FIRST, SHUNT_ROW_LAST + 1):
        base = (r - SHUNT_ROW_FIRST) * COLS
        for c in range(COLS // 2):
            mc = COLS - 1 - c
            if out[base + c] == 0 or out[base + mc] == 0:
                out[base + c] = 0
                out[base + mc] = 0
        for c in range(COLS):
            if out[base + c] == STRIDE:
                out[base + c] = corridor_depth_offset(c)
    return out


def build_forward_table(widths: dict[int, int]) -> list[int]:
    """Combined offsets for rows 1..13."""
    new = scroll_grid_forward(widths)
    table: list[int] = []

    for r in range(SHUNT_ROW_FIRST, SHUNT_ROW_LAST + 1):
        for c in range(COLS):
            dest = r * STRIDE + c
            mark = new[r][c]
            if mark == 0:
                table.append(0)
            else:
                off = (mark - 1) - dest
                if off < -128 or off > 127:
                    raise ValueError(f"forward row{r} col{c}: off={off} out of range")
                table.append(off)

    return finalize_forward_table(table)


def shift_steer_offset(value: int, delta: int) -> int:
    """Apply sector rotation: 0 stays clear; else offset +/- delta, clamp invalid to 0."""
    if value == 0:
        return 0
    shifted = value + delta
    if shifted < 1 or shifted > 127:
        return 0
    return shifted


def derive_steer_tables(forward: list[int]) -> dict[str, list[int]]:
    left = [shift_steer_offset(v, -STEER_SHIFT) for v in forward]
    right = [shift_steer_offset(v, STEER_SHIFT) for v in forward]
    return {"forward": forward, "left": left, "right": right}


def row_slice(tab: list[int], row: int) -> list[int]:
    i = (row - SHUNT_ROW_FIRST) * COLS
    return tab[i : i + COLS]


def corridor_cols(width: int) -> range:
    """Interior columns that should remain pure +STRIDE after symmetric shunt."""
    return range(width + 1, COLS - width - 1)


def verify_tables(tables: dict[str, list[int]], widths: dict[int, int]) -> None:
    fwd = tables["forward"]

    for r in range(SHUNT_ROW_FIRST, SHUNT_ROW_LAST + 1):
        row = row_slice(fwd, r)
        for c in range(COLS // 2):
            mc = COLS - 1 - c
            if (row[c] == 0) != (row[mc] == 0):
                raise SystemExit(
                    f"forward row {r}: zero asymmetry col{c}={row[c]} col{mc}={row[mc]}"
                )

        w = widths[r]
        for c in corridor_cols(w):
            want = corridor_depth_offset(c)
            if row[c] != want:
                raise SystemExit(
                    f"forward row {r} col {c}: expected {want}, got {row[c]} (w={w})"
                )

    for i, v in enumerate(fwd):
        if tables["left"][i] != shift_steer_offset(v, -STEER_SHIFT):
            raise SystemExit(f"left mismatch at index {i}")
        if tables["right"][i] != shift_steer_offset(v, STEER_SHIFT):
            raise SystemExit(f"right mismatch at index {i}")

    for r in range(SHUNT_ROW_FIRST, SHUNT_ROW_LAST):
        if widths[r] != widths[r + 1] and row_slice(fwd, r) == row_slice(fwd, r + 1):
            raise SystemExit(
                f"forward rows {r} and {r+1} are identical but w differs "
                f"({widths[r]} vs {widths[r+1]})"
            )


def emit_asm(tables: dict[str, list[int]], widths: dict[int, int]) -> str:
    tab_rows = SHUNT_ROW_LAST - SHUNT_ROW_FIRST + 1
    tab_bytes = tab_rows * COLS
    shunt_map_offset = SHUNT_ROW_FIRST * STRIDE

    lines = [
        "; Auto-generated by tools/generate_scroll.py — do not edit",
        ";",
        "; Combined scroll+shunt offsets (22 cols, front row at map_base).",
        "; Forward: row_shift + shunt; corridor $15 / $16 centre / $17.",
        "; Left/right: forward -1 / +1 (right steer pulls right-to-left).",
        "; Rows 1..13 in tables; rows 0..10 and 14..22 depth-only in code.",
        "; Row 23 planted each tick.",
        ";",
        "; Offset 0 = write empty. Positive offset = copy from higher address.",
        "",
        "scroll_cols = " + str(COLS),
        "scroll_rows = " + str(ROWS),
        "scroll_row_stride = " + str(STRIDE),
        "scroll_direct_rows = " + str(SCROLL_DIRECT_ROWS),
        "scroll_deep_row_first = " + str(SCROLL_DEEP_ROW_FIRST),
        "scroll_shunt_row_first = " + str(SHUNT_ROW_FIRST),
        "scroll_shunt_row_last = " + str(SHUNT_ROW_LAST),
        "scroll_shunt_map_offset = " + str(shunt_map_offset),
        "scroll_tab_rows = " + str(tab_rows),
        "scroll_tab_bytes = " + str(tab_bytes),
        "scroll_steer_shift = " + str(STEER_SHIFT),
        "",
    ]

    labels = {
        "forward": "scroll_tab_forward",
        "left": "scroll_tab_left",
        "right": "scroll_tab_right",
    }

    comments = {
        "forward": "straight — zeros symmetric; corridor $15/$16/$17",
        "left": "left steer — forward - 1",
        "right": "right steer — forward + 1",
    }

    for steer, name in labels.items():
        tab = tables[steer]
        lines.append(f"; --- {comments[steer]} ---")
        lines.append(name)
        for r in range(SHUNT_ROW_FIRST, SHUNT_ROW_LAST + 1):
            row = row_slice(tab, r)
            hexes = ", ".join(f"${b & 0xFF:02x}" for b in row)
            w = widths[r]
            lines.append(f"    !byte {hexes}    ; row {r} w={w}")
        lines.append("")

    return "\n".join(lines) + "\n"


def main() -> int:
    widths = load_row_widths()
    forward = build_forward_table(widths)
    tables = derive_steer_tables(forward)
    verify_tables(tables, widths)

    OUT_ASM.write_text(emit_asm(tables, widths), encoding="utf-8")
    print(f"Wrote {OUT_ASM}")
    for steer, tab in tables.items():
        zeros = sum(1 for v in tab if v == 0)
        print(
            f"  {steer}: {len(tab)} bytes, {zeros} zeros, "
            f"offset range {min(tab)}..{max(tab)}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
