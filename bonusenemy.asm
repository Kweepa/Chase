!zone bonusenemy

InitBonus
    lda #3
    sta bonustimer
    lda #$fe
    sta bonusx
    lda #0
    sta bonusdead
    sta bonusvis
    rts

TryKillBonus
    lda bonusdead
    beq +
    rts
+
    ldx boltx
    cpx bonusx
    beq +
    dex
    cpx bonusx
    beq +
    rts
+
    lda #1
    sta bonusdead
    lda #10
    sta bonusexp
    rts

UpdateBonus

    lda frame_tick
    and #1
    beq +
    rts
+

    lda bonustimer
    bmi +
    dec bonustimer
    rts

+
    ldx bonusx
    lda bonusdead
    bne +

    ; advance
    lda frame_tick ; go slow
    and #2
    beq +
    inx
+
    lda #1
    sta bonusvis
    txa
    sec
    sbc steer
    sta bonusx
    cmp #screen_cols
    beq bonus_reset
    cmp #screen_cols+1
    beq bonus_reset

    lda bonusdead
    bne +
    rts
+

    lda bonusexp
    bmi +
    dec bonusexp
    rts
+
    lda #0
    sta bonusvis
    rts

bonus_reset
    lda #20
    sta bonustimer
    lda #$fe
    sta bonusx
    lda #0
    sta bonusvis

    rts

DrawBonus
    lda bonusvis
    bne +
    rts
+
    ldy #0
    ldx bonusx
    cpx tree_col
    beq +
    inx
    iny
    cpx tree_col
    beq +
    rts
+
    ; udg definition offset (0 or 8)
    sty temp1
    tya
    asl
    asl
    asl
    tay

    ; write white if not obscured
    ldx tree_col
    lda screen_base + 9 * screen_cols,x
    bne +
    lda #WHITE
    sta color_base + 9 * screen_cols,x
+
    jsr GetBonusUDGAddr
    
    ; get UDG to mix in (get screen UDG, * 8, + udg_base)
    lda #0
    sta udg_mix_ptr+1
    lda screen_base + 9 * screen_cols,x
    asl
    rol udg_mix_ptr+1
    asl
    rol udg_mix_ptr+1
    asl
    rol udg_mix_ptr+1
    adc #<udg_base
    sta udg_mix_ptr
    lda udg_mix_ptr+1
    adc #>udg_base
    sta udg_mix_ptr+1

    tya
    clc
    adc #<udg_base + 8 * chr_bonus
    sta udg_dst_ptr
    lda #0
    adc #>udg_base + 8 * chr_bonus
    sta udg_dst_ptr+1

    ; copy down the UDG definition
    ldy #7
-
    lda (udg_src_ptr),y
    ora (udg_mix_ptr),y
    sta (udg_dst_ptr),y
    dey
    bpl -

    ; finally write the udg to the screen
    ldy temp1
    lda bonus_enemy_dest_udg,y
    sta screen_base + 9*screen_cols,x
    rts

bonus_enemy_dest_udg
    !byte chr_bonus, chr_bonus+1

GetBonusUDGAddr
    lda bonusdead
    beq +

    tya
    clc
    adc #<udg_base + 8 * chr_bonus_explode
    sta udg_src_ptr
    lda #0
    adc #>udg_base + 8 * chr_bonus_explode
    sta udg_src_ptr+1
    rts
+
    lda sector
    and #1
    beq +

    tya
    clc
    adc #<udg_base + 8 * chr_tank
    sta udg_src_ptr
    lda #0
    adc #>udg_base + 8 * chr_tank
    sta udg_src_ptr+1
    rts

+
    tya
    clc
    adc #<udg_base + 8 * chr_heli
    sta udg_src_ptr
    lda #0
    adc #>udg_base + 8 * chr_heli
    sta udg_src_ptr+1
    rts
