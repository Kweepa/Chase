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

; Tree grid (24 rows × 23 cols) - top of block below $6000
map_cols = 23
map_rows = 24
map_bytes   = map_cols * map_rows
map_base    = $6000 - map_bytes

udg_base    = $1800
color_base  = $9400

SPEED_SLOW  = 2
SPEED_FAST  = 0

RASTERLINE_PAL  = $70
RASTERLINE_NTSC = $62

; Raster split
LIGHT_BLUE          = 14
BG_TOP              = (LIGHT_BLUE << 4) | 8
BG_BOTTOM           = (GREEN << 4) | 8

; Raster split timing — PAL 6561-101 (71 CPU cycles/scanline, 312 lines/frame).
; See raster.asm (Marko Makela / Codebase64 stable-raster routine).
;
; RASTER_SYNC_DOUBLE — $9004 value waited on at InitRasterSplit; each step is
;   one double raster line (2 scanlines). Positions the per-frame top IRQ.
; FRAME_TIMER_PAL — VIA2 Timer A reload: one IRQ per frame (312×71 − 2).
; ROW10_DELAY_PAL — VIA2 Timer B one-shot: CPU cycles from top IRQ (light blue)
;   to green split at playfield row 10 horizon. Tune on hardware.
RASTER_SYNC_DOUBLE  = 27
SCANLINE_CYCLES     = 71
FRAME_TIMER_PAL     = 312 * SCANLINE_CYCLES - 2
ROW10_DELAY_PAL     = 83 * SCANLINE_CYCLES + 50

hud_lives_scr = screen_base + 20 * screen_cols + 4
hud_lives_col = color_base + 20 * screen_cols + 4

; Gfx equates (sync with build/gfx_equates.asm from convert_gfx.py)
!source "build/gfx_equates.asm"
