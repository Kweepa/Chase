#!/usr/bin/env python3
"""Render baked_pull_grid (or turn grids) as a cell-to-cell arrow diagram.

Offset 0 = clear cell. Positive offset N at flat index i means:
  destination = i, source = i + N  (copy from higher address).

The PNG is flipped so Z=1 (closest) is at the bottom.
"""

from __future__ import annotations

import argparse
import math
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASM_PATH = ROOT / "tree_movement_tables.asm"
OUT_DIR = ROOT / "build"

MAP_COLS = 23
MAP_ROWS = 24

CELL = 28
MARGIN_LEFT = 48
MARGIN_RIGHT = 24
MARGIN_TOP = 36
MARGIN_BOTTOM = 36
ARROW_SHAFT = (40, 90, 140)
ARROW_HEAD = (20, 55, 100)
GRID_LINE = (180, 180, 180)
EMPTY_FILL = (245, 245, 245)
USED_FILL = (230, 238, 245)
FAR_FILL = (255, 248, 220)
BG = (255, 255, 255)
LABEL = (60, 60, 60)
NOTE = (120, 90, 40)

_FONT_CANDIDATES = (
    Path(r"C:\Windows\Fonts\segoeui.ttf"),
    Path(r"C:\Windows\Fonts\arial.ttf"),
    Path(r"C:\Windows\Fonts\calibri.ttf"),
)


def load_font(size: int = 14) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in _FONT_CANDIDATES:
        if path.is_file():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def parse_byte_line(line: str) -> list[int]:
    body = line.split("!byte", 1)[1].split(";", 1)[0]
    return [int(tok.strip(), 0) for tok in body.split(",") if tok.strip()]


def parse_grid(path: Path, label: str) -> list[int]:
    text = path.read_text(encoding="utf-8")
    m = re.search(
        rf"^{re.escape(label)}\s*\n((?:\s*!byte[^\n]*\n?)+)",
        text,
        flags=re.MULTILINE,
    )
    if not m:
        raise SystemExit(f"label {label!r} not found in {path}")
    vals: list[int] = []
    for line in m.group(1).splitlines():
        if "!byte" in line:
            vals.extend(parse_byte_line(line))
    expected = MAP_ROWS * MAP_COLS
    if len(vals) != expected:
        raise SystemExit(f"{label}: expected {expected} bytes, got {len(vals)}")
    return vals


def cell_center(col: int, row_near0: int) -> tuple[float, float]:
    """Pixel center. row_near0=0 is closest (drawn at bottom)."""
    x = MARGIN_LEFT + col * CELL + CELL / 2
    # Flip: near (0) → bottom, far (23) → top
    y = MARGIN_TOP + (MAP_ROWS - 1 - row_near0) * CELL + CELL / 2
    return x, y


def draw_arrow(draw: ImageDraw.ImageDraw, x0: float, y0: float, x1: float, y1: float) -> None:
    """Arrow with tail at (x0,y0) and head at (x1,y1)."""
    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy)
    if length < 1e-6:
        r = 3
        draw.ellipse((x1 - r, y1 - r, x1 + r, y1 + r), fill=ARROW_HEAD)
        return

    ux, uy = dx / length, dy / length
    inset = CELL * 0.22
    sx, sy = x0 + ux * inset, y0 + uy * inset
    ex, ey = x1 - ux * inset, y1 - uy * inset

    draw.line((sx, sy, ex, ey), fill=ARROW_SHAFT, width=2)

    head_len = min(10.0, length * 0.35)
    head_w = 4.5
    px, py = -uy, ux
    tip = (ex, ey)
    left = (ex - ux * head_len + px * head_w, ey - uy * head_len + py * head_w)
    right = (ex - ux * head_len - px * head_w, ey - uy * head_len - py * head_w)
    draw.polygon([tip, left, right], fill=ARROW_HEAD)


def render(grid: list[int], out: Path) -> None:
    width = MARGIN_LEFT + MARGIN_RIGHT + MAP_COLS * CELL
    height = MARGIN_TOP + MARGIN_BOTTOM + MAP_ROWS * CELL
    img = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(img)

    for row in range(MAP_ROWS):
        for col in range(MAP_COLS):
            i = row * MAP_COLS + col
            if row == MAP_ROWS - 1:
                fill = FAR_FILL
            elif grid[i] == 0:
                fill = EMPTY_FILL
            else:
                fill = USED_FILL
            x0 = MARGIN_LEFT + col * CELL
            y0 = MARGIN_TOP + (MAP_ROWS - 1 - row) * CELL
            draw.rectangle((x0, y0, x0 + CELL, y0 + CELL), fill=fill, outline=GRID_LINE)

    # Arrows: tail at source (i+offset), head at destination (i).
    # Skip the far row — it is cleared and planted randomly, not filled by pull.
    for i, offset in enumerate(grid):
        if offset == 0:
            continue
        dr, dc = divmod(i, MAP_COLS)
        if dr == MAP_ROWS - 1:
            continue
        src = i + offset
        if not (0 <= src < len(grid)):
            continue
        sr, sc = divmod(src, MAP_COLS)
        x0, y0 = cell_center(sc, sr)
        x1, y1 = cell_center(dc, dr)
        draw_arrow(draw, x0, y0, x1, y1)

    font = load_font(14)
    grid_bottom = MARGIN_TOP + MAP_ROWS * CELL
    draw.text((MARGIN_LEFT, grid_bottom + 2), "closest (Z=1)", fill=LABEL, font=font)
    draw.text(
        (MARGIN_LEFT, MARGIN_TOP - 20),
        "farthest (Z=24) — populated randomly",
        fill=NOTE,
        font=font,
    )

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"wrote {out} ({width}x{height})")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "grid",
        nargs="?",
        default="baked_pull_grid",
        choices=("baked_pull_grid", "turn_left_grid", "turn_right_grid"),
    )
    p.add_argument("-o", "--output", type=Path, default=None)
    args = p.parse_args()
    out = args.output or (OUT_DIR / f"{args.grid}.png")
    grid = parse_grid(ASM_PATH, args.grid)
    render(grid, out)


if __name__ == "__main__":
    main()
