!zone bonusenemy

SetInitialBonusY
    ; tank y=9; heli y = rnd(8)
    lda #9
    sta bonusy
    lda sector
    and #1
    bne +
    jsr GetRandom16
    and #7
    sta bonusy
+
    rts

InitBonus
    lda #3
    sta bonusdelay
    lda #$fe
    sta bonusx
    lda #0
    sta bonusdead
    sta bonusvis
    sta bonustime
    jsr SetInitialBonusY
    rts

TryKillBonus
    lda bonusdead
    beq +
    rts
+
    lda bonusy
    cmp #9
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
    jsr Add1000ToScore
    jsr Add1000ToScore

    lda #160
    sta $900d

    rts

UpdateHelicopter
    ; for helicopter, rise and fall
    lda sector
    and #1
    beq +
    rts
+
    ; rotate the blades
    lda udg_base + 8 * chr_heli + 1
    eor #$2a
    sta udg_base + 8 * chr_heli + 1
    lda udg_base + 8 * chr_heli + 9
    eor #$2a
    sta udg_base + 8 * chr_heli + 9

    lda bonustime
    cmp #9          ; ensure it reaches the ground level
    bcs ++
    ldy bonusy
    cpy #9
    beq +
    inc bonusy
+   
    rts
++
    cmp #14
    bcc +
    dec bonusy
+
    rts

UpdateBonus

    lda frame_tick
    and #1
    beq +
    rts
+

    lda bonusdelay
    bmi +
    dec bonusdelay
    rts

+
    ldx bonusx
    lda bonusdead
    bne +

    ; advance
    lda frame_tick ; go slow
    and #2
    beq +
    inx ; bonusx

    jsr UpdateHelicopter
    inc bonustime
    lda bonusy
    bmi bonus_reset

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
    bmi ++
    dec bonusexp
    lda bonusexp
    bmi +
    lda #0
    sta $900d
+
    rts
++
    lda #0
    sta bonusvis
    rts

bonus_reset
    lda #20
    sta bonusdelay
    lda #$fe
    sta bonusx
    lda #0
    sta bonusvis
    sta bonustime
    jsr SetInitialBonusY

    rts

screen_rows_low
    !byte <screen_base
    !byte <screen_base + screen_cols
    !byte <screen_base + screen_cols * 2
    !byte <screen_base + screen_cols * 3
    !byte <screen_base + screen_cols * 4
    !byte <screen_base + screen_cols * 5
    !byte <screen_base + screen_cols * 6
    !byte <screen_base + screen_cols * 7
    !byte <screen_base + screen_cols * 8
    !byte <screen_base + screen_cols * 9

screen_rows_hi
    !byte >screen_base
    !byte >screen_base + screen_cols
    !byte >screen_base + screen_cols * 2
    !byte >screen_base + screen_cols * 3
    !byte >screen_base + screen_cols * 4
    !byte >screen_base + screen_cols * 5
    !byte >screen_base + screen_cols * 6
    !byte >screen_base + screen_cols * 7
    !byte >screen_base + screen_cols * 8
    !byte >screen_base + screen_cols * 9

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
    sta temp2
    tay

    ldx bonusy
    lda screen_rows_low,x
    clc
    adc tree_col
    sta scr_ptr
    sta col_ptr
    lda screen_rows_hi,x
    adc #0
    sta scr_ptr+1
    eor #$84
    sta col_ptr+1

    ; write white if not obscured
    ldy #0
    lda (scr_ptr),y
    bne +
    lda #WHITE
    sta (col_ptr),y
+
    ldy temp2
    jsr GetBonusUDGAddr
    
    ; get UDG to mix in (get screen UDG, * 8, + udg_base)
    lda #0
    sta udg_mix_ptr+1
    ldy #0
    lda (scr_ptr),y
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

    lda temp2
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
    ldy #0
    sta (scr_ptr),y
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
