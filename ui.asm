!zone ui

DrawUIFrame

    ldx #4 * screen_cols - 1
-
    lda ui_frame_chr,x
    sta screen_base + 18 * screen_cols,x
    lda ui_frame_col,x
    sta color_base + 18 * screen_cols,x
    dex
    bpl -

    jsr DrawMen

    lda #chr_ui_score
    sta screen_base + 19 * screen_cols + 2
    lda #chr_ui_lives
    sta screen_base + 20 * screen_cols + 12
    lda #chr_ui_range
    sta screen_base + 20 * screen_cols + 9

    jsr DrawScore

    rts

DrawMen
    lda #chr_digit_0
    clc
    adc lives
    sta screen_base + 20 * screen_cols + 13
    lda #BLACK
    sta color_base + 20 * screen_cols + 13
    rts

UpdateUI
    ldx #BLACK
    lda bikez
    bne +
    lda frame_tick
    and #1
    bne +
    ldx #WHITE
+
    stx color_base + 20 * screen_cols + 9
    rts

; score is represented by 6 digits
; for simplicity each digit is a byte
; so no need to divide when drawing
; eg to add 1000, just start at the 1000s digit

Add1000ToScore
    ldx #2
    bne AddToScore
    ; done

Add1ToScore
    ldx #5
AddToScore
-
    lda score,x
    clc
    adc #1
    sta score,x
    cmp #10
    bne +
    lda #0
    sta score,x
    dex
    bpl -
+
    ; fall through to draw

DrawScore
    ldx #5
-
    lda score,x
    clc
    adc #chr_digit_0
    sta screen_base + 20 * screen_cols + 1,x
    dex
    bpl -

    ; update hiscore
    ldx #0
--
    lda score,x
    cmp hiscore,x
    beq +  ; digit equal, move to next
    bcc ++
-
    lda score,x
    sta hiscore,x
    clc
    adc #chr_digit_0
    sta screen_base + 20 * screen_cols + 16,x
    inx
    cpx #6
    bne -
+
    inx
    cpx #6
    bne --
++
    rts

DrawHiScore
    ldx #5
-
    lda hiscore,x
    clc
    adc #chr_digit_0
    sta screen_base + 20 * screen_cols + 16,x
    dex
    bpl -
    rts

ResetScore
    ldx #5
    lda #0
-
    sta score,x
    dex
    bpl -

    jsr DrawScore
    rts