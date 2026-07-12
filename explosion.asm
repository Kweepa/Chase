!zone explosion

InitExplosion
    lda #$ff
    sta explosiont
    rts

SpawnExplosion
    lda tree_col
    sta explosionx
    lda #15
    sta explosiont
    lda #140
    sta $900d
    rts

UpdateExplosion
    lda explosiont
    bpl +
    rts
+
    lsr
    tax
    lda explosion_colors,x
    sta explosioncol
    dec explosiont

    lda explosiont
    bpl +
    ; explosion ended
    lda #0
    sta $900d
+
    
    lda frame_tick
    and #1
    beq +
    rts
+
    lda explosionx
    sec
    sbc steer
    sta explosionx
    rts

DrawExplosion
    lda explosiont
    bpl +
    rts
+

    ldx #8
-
    lda explosion_offsets,x
    clc
    adc explosionx
    tay
    lda screen_base + 8 * screen_cols - 1,y
    beq +
    cmp #128 ; don't draw on top of large trees
    bcc ++
+
    txa
    clc
    adc #chr_explosion
    sta screen_base + 8 * screen_cols - 1,y
    lda explosioncol
    sta color_base + 8 * screen_cols - 1,y
++
    dex
    bpl -

    rts

explosion_offsets
    !byte 0, screen_cols + 0, 2 * screen_cols + 0
    !byte 1, screen_cols + 1, 2 * screen_cols + 1
    !byte 2, screen_cols + 2, 2 * screen_cols + 2

explosion_colors
    !byte BLACK, BLUE, RED, PURPLE, GREEN, CYAN, YELLOW, WHITE