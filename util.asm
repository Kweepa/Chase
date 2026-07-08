!zone util

ConvertTileXYToScreenAddr
    tya
    asl
    tay
    lda x22rowtab,y
    sta scr_ptr
    lda x22rowtab + 1,y
    sta scr_ptr + 1
    txa
    clc
    adc scr_ptr
    sta scr_ptr
    bcc +
    inc scr_ptr + 1
+
    lda scr_ptr
    sta col_ptr
    lda scr_ptr + 1
    eor #>(color_base ^ screen_base)
    sta col_ptr + 1
    rts

ClearScreen
    ldx #0
-
    lda #0
    sta screen_base,x
    sta screen_base + $100,x
    inx
    bne -

    rts

WaitForRaster
    ; wait for raster below sync band (inlined WaitForRasterLineLessThan)
-
    lda $9004
    and #$fe
    cmp #RASTERLINE_PAL
    bcs -
    ; fall through

WaitForRasterLine
    lda $9004
    and #$fe
    cmp #RASTERLINE_PAL
    bne WaitForRasterLine
    rts

WaitForKeypress
    ldx #$ef
-
    jsr ScanKeyRow
    bne -
-
    jsr ScanKeyRow
    beq -
    rts

x22rowtab
    !word screen_base + screen_cols * 0
    !word screen_base + screen_cols * 1
    !word screen_base + screen_cols * 2
    !word screen_base + screen_cols * 3
    !word screen_base + screen_cols * 4
    !word screen_base + screen_cols * 5
    !word screen_base + screen_cols * 6
    !word screen_base + screen_cols * 7
    !word screen_base + screen_cols * 8
    !word screen_base + screen_cols * 9
    !word screen_base + screen_cols * 10
    !word screen_base + screen_cols * 11
    !word screen_base + screen_cols * 12
    !word screen_base + screen_cols * 13
    !word screen_base + screen_cols * 14
    !word screen_base + screen_cols * 15
    !word screen_base + screen_cols * 16
    !word screen_base + screen_cols * 17
    !word screen_base + screen_cols * 18
    !word screen_base + screen_cols * 19
    !word screen_base + screen_cols * 20
    !word screen_base + screen_cols * 21
    !word screen_base + screen_cols * 22

hud_lives_scr = screen_base + tile_bytes - screen_cols + 10
hud_lives_col = color_base + tile_bytes - screen_cols + 10
