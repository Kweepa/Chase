; Chase VIC-20 — 16K tape layout (JSW-Tape pattern)

BLACK  = 0
WHITE  = 1
RED    = 2
CYAN   = 3
PURPLE = 4
GREEN  = 5
BLUE   = 6
YELLOW = 7

screen_base = $1000
color_base  = $9400
; Logic grid — full-byte RAM at top of block below $6000 ($5df0..$5fff)
map_base    = $5df0

screen_cols = 22
screen_rows = 23
tile_bytes  = screen_cols * screen_rows   ; 506

; Tree grid (Spectrum $7CA1 analogue — 24 rows × 22 cols)
; we can use the same multiplication table?
logic_cols  = 22
logic_rows  = 24
row_stride  = logic_cols
map_bytes   = logic_cols * logic_rows

udg_base    = $1800
udg_slots   = 256

; Game state (Spectrum $5DC0+ analogue)
status_base = $0340

SPEED_SLOW  = 2
SPEED_FAST  = 0

RASTERLINE_PAL  = $70
RASTERLINE_NTSC = $62

; Raster split — horizon at playfield row 10 (sync with convert_gfx.py)
SCREEN_BG_ROW       = 10
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
FRAME_TIMER_PAL     = 312 * 71 - 2
ROW10_DELAY_PAL     = 5575

; Gfx equates (sync with build/gfx_equates.asm from convert_gfx.py)
!source "build/gfx_equates.asm"
