!zone init

InitGame

    lda #3
    sta lives

    lda #2
    sta sector

    lda #0
    sta frame_tick

    jsr InitTrees
    jsr InitPlayerBike
    jsr InitSector

    lda #BG_TOP
    sta skycol

    rts

InitSector
    jsr InitBikes
    jsr InitBolt
    jsr InitExplosion
    jsr InitBonus

    rts

DrawUIStub
    lda #chr_digit_0 + 3
    ; sta hud_lives_scr
    lda #(YELLOW << 4) | WHITE
    sta hud_lives_col
    rts

DrawUIFrame

    ldx #4 * screen_cols - 1
-
    lda ui_frame_chr,x
    sta screen_base + 18 * screen_cols,x
    lda ui_frame_col,x
    sta color_base + 18 * screen_cols,x
    dex
    bpl -
    rts
