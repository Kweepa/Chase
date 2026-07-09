!zone playerbike

bike_bars_col
    !byte BLACK, BLACK, WHITE, WHITE, WHITE, BLACK, BLACK

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

    rts