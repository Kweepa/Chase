!zone playerbike

DrawBikeBody

    ldx #8
-
    lda bike_body_chr,x
    sta screen_base + 19 * screen_cols + 7,x
    lda bike_body_chr+9,x
    sta screen_base + 20 * screen_cols + 7,x
    lda bike_body_col,x
    sta color_base + 19 * screen_cols + 7,x
    sta color_base + 20 * screen_cols + 7,x
    dex
    bpl -
    rts

bike_body_col
    !byte BLACK, BLACK, BLACK, BLUE, BLUE, BLUE, BLACK, BLACK, BLACK
bike_bars_col
    !byte BLACK, BLACK, WHITE, WHITE, WHITE, BLACK, BLACK

; copy down UDGs later based on steering - don't need to write these every frame

DrawBikeHandlebars

    ldx #6
-
    txa
    clc
    adc #chr_handlebar_fwd
    sta screen_base + 17 * screen_cols + 8,x
    adc #7
    sta screen_base + 18 * screen_cols + 8,x
    lda bike_bars_col,x
    sta color_base + 17 * screen_cols + 8,x
    sta color_base + 18 * screen_cols + 8,x
    dex
    bpl -
    rts