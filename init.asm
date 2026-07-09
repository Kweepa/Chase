!zone init

InitGame
    lda #3
    sta lives

    lda #4
    sta sector

    lda #SPEED_SLOW
    sta speed

    lda #1
    sta bike_moving

    lda #0
    sta steer
    sta frame_tick
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
