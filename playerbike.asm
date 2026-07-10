!zone playerbike

InitPlayerBike
    lda #1
    sta speed
    lda #0
    sta steer
    rts

bike_bars_col
    !byte BLACK, BLACK, WHITE, WHITE, WHITE, BLACK, BLACK

bike_bars_fwd
    !byte $00, $00, $00, $03, $0f, $3f, $ff, $ff    ; chr 235 — handlebar_fwd_1 0
    !byte $00, $00, $00, $e0, $fc, $ff, $ff, $ff    ; chr 236 — handlebar_fwd_1 1
    !byte $00, $00, $01, $03, $03, $07, $9f, $cf    ; chr 237 — handlebar_fwd_1 2
    !byte $3c, $ff, $ff, $ef, $ef, $ef, $ef, $ef    ; chr 238 — handlebar_fwd_1 3
    !byte $00, $00, $80, $c0, $c0, $e0, $f1, $fb    ; chr 239 — handlebar_fwd_1 4
    !byte $00, $00, $00, $07, $1f, $7f, $ff, $ff    ; chr 240 — handlebar_fwd_1 5
    !byte $00, $00, $00, $e0, $f0, $fc, $ff, $ff    ; chr 241 — handlebar_fwd_1 6
    !byte $ff, $ff, $ff, $29, $2f, $7f, $ff, $ff    ; chr 242 — handlebar_fwd_2 0
    !byte $ff, $ff, $ff, $7f, $3f, $be, $ce, $f4    ; chr 243 — handlebar_fwd_2 1
    !byte $e7, $f0, $f8, $fd, $fd, $7d, $3d, $1d    ; chr 244 — handlebar_fwd_2 2
    !byte $ff, $10, $00, $bb, $bb, $bb, $bb, $81    ; chr 245 — handlebar_fwd_2 3
    !byte $cf, $1f, $3f, $7f, $7f, $7f, $7e, $7c    ; chr 246 — handlebar_fwd_2 4
    !byte $ff, $ff, $ff, $ff, $ff, $7e, $3b, $13    ; chr 247 — handlebar_fwd_2 5
    !byte $ff, $ff, $ff, $d7, $52, $7e, $fe, $ff    ; chr 248 — handlebar_fwd_2 6
bike_bars_left
    !byte $00, $00, $00, $00, $00, $00, $00, $07    ; chr 249 — handlebar_left_1 0
    !byte $00, $00, $00, $00, $00, $00, $00, $f0    ; chr 250 — handlebar_left_1 1
    !byte $00, $05, $0c, $0e, $0f, $1f, $1f, $1f    ; chr 251 — handlebar_left_1 2
    !byte $00, $c0, $f8, $7c, $7e, $3f, $9f, $df    ; chr 252 — handlebar_left_1 3
    !byte $00, $00, $00, $00, $00, $02, $87, $cf    ; chr 253 — handlebar_left_1 4
    !byte $07, $1f, $3f, $ff, $ff, $ff, $ff, $fe    ; chr 254 — handlebar_left_1 5
    !byte $e0, $f0, $fc, $fe, $fe, $ff, $ff, $0e    ; chr 255 — handlebar_left_1 6
    !byte $0f, $1f, $3f, $ff, $ff, $ff, $ff, $ff    ; chr 256 — handlebar_left_2 0
    !byte $f8, $fa, $fe, $fe, $ff, $ff, $ff, $ff    ; chr 257 — handlebar_left_2 1
    !byte $3f, $3f, $7f, $1f, $c6, $f0, $fe, $ff    ; chr 258 — handlebar_left_2 2
    !byte $ff, $ff, $f8, $80, $01, $cb, $e1, $f5    ; chr 259 — handlebar_left_2 3
    !byte $c7, $0f, $1f, $7e, $fc, $b0, $a0, $a0    ; chr 260 — handlebar_left_2 4
    !byte $fc, $f1, $e7, $6f, $6f, $6f, $7f, $2f    ; chr 261 — handlebar_left_2 5
    !byte $f2, $f8, $fe, $fe, $fe, $ff, $ff, $ff    ; chr 262 — handlebar_left_2 6
bike_bars_right
    !byte $07, $0f, $3f, $7f, $7f, $ff, $ff, $70    ; chr 263 — handlebar_right_1 0
    !byte $e0, $f8, $fc, $ff, $ff, $ff, $ff, $7f    ; chr 264 — handlebar_right_1 1
    !byte $00, $00, $00, $00, $00, $40, $e1, $f3    ; chr 265 — handlebar_right_1 2
    !byte $00, $03, $1f, $3e, $7e, $fc, $f9, $fb    ; chr 266 — handlebar_right_1 3
    !byte $00, $a0, $30, $70, $f0, $f8, $f8, $f8    ; chr 267 — handlebar_right_1 4
    !byte $00, $00, $00, $00, $00, $00, $00, $0f    ; chr 268 — handlebar_right_1 5
    !byte $00, $00, $00, $00, $00, $00, $00, $e0    ; chr 269 — handlebar_right_1 6
    !byte $4f, $1f, $7f, $7f, $7f, $ff, $ff, $ff    ; chr 270 — handlebar_right_2 0
    !byte $3f, $8f, $e7, $f6, $f6, $f6, $fe, $f4    ; chr 271 — handlebar_right_2 1
    !byte $e3, $f0, $f8, $7e, $3f, $0d, $05, $05    ; chr 272 — handlebar_right_2 2
    !byte $ff, $ff, $1f, $01, $80, $d3, $87, $af    ; chr 273 — handlebar_right_2 3
    !byte $fc, $fc, $fe, $f8, $63, $0f, $7f, $ff    ; chr 274 — handlebar_right_2 4
    !byte $1f, $5f, $7f, $7f, $ff, $ff, $ff, $ff    ; chr 275 — handlebar_right_2 5
    !byte $f0, $f8, $fc, $ff, $ff, $ff, $ff, $ff    ; chr 276 — handlebar_right_2 6

bike_bars_table
    !word bike_bars_left
    !word bike_bars_fwd
    !word bike_bars_right

DrawBikeHandlebars

    ldx #6
-
    txa
    clc
    adc #chr_handlebar_fwd
    sta screen_base + 16 * screen_cols + 8,x
    adc #7
    sta screen_base + 17 * screen_cols + 8,x
    lda bike_bars_col,x
    sta color_base + 16 * screen_cols + 8,x
    sta color_base + 17 * screen_cols + 8,x
    dex
    bpl -

    rts

TurnBikeHandlebars

    ; copy down UDGs based on steering - don't need to write these every frame

    ldx steer
    inx
    txa
    asl
    tax
    lda bike_bars_table,x
    sta temp_ptr
    lda bike_bars_table+1,x
    sta temp_ptr+1

    ldy #(14 * 8 - 1)
-
    lda (temp_ptr),y
    sta udg_base + 8*chr_handlebar_fwd,y
    dey
    bpl -

    rts