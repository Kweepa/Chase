; Chase VIC-20 — 16K tape layout (JSW-Tape pattern)

BLACK  = 0
WHITE  = 1
RED    = 2
CYAN   = 3
PURPLE = 4
GREEN  = 5
BLUE   = 6
YELLOW = 7

screen_cols = 23
screen_rows = 22
tile_bytes  = screen_cols * screen_rows   ; 506
screen_base = $1000

; Tree grid (24 rows × 23 cols) - top of block below $4000
map_cols = 23
map_rows = 24
map_bytes   = map_cols * map_rows
map_base    = $4000 - map_bytes

udg_base    = $1800
color_base  = $9400

RASTERLINE_PAL  = $10
RASTERLINE_NTSC = $62

; Gfx equates (sync with build/gfx_equates.asm from convert_gfx.py)
!source "build/gfx_equates.asm"
