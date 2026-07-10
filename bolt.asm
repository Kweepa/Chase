!zone bolt

InitBolt
    lda #$ff
    sta bolty
    rts

UpdateBolt
    lda bolty
    bmi try_fire_bolt

    lda frame_tick
    and #1
    bne +
    rts
+

    inc bolty
    lda bolty
    cmp #6
    bne +
    lda #$ff
    sta bolty

    jsr TryKillBonus

    rts

+
    lda boltx
    sec
    sbc steer
    sta boltx

    lda boltoff
    sec
    sbc #screen_cols
    sec
    sbc steer
    sta boltoff

    rts

try_fire_bolt
    lda boltfired
    bne +
    rts
+
    lda speed
    cmp #2
    beq +
    rts
+
    lda #11
    sta boltx
    inc bolty ; was ff, now 0
    lda #5 * screen_cols + 11
    sta boltoff
    rts

DrawBolt
    lda boltx
    cmp tree_col
    beq +
    rts
+
    lda bolty
    bpl +
    rts
+
    ldx boltoff
    lda screen_base + 10 * screen_cols,x
    cmp #0
    beq bolt_path_clear
    cmp #chr_enemy_bike
    bcc bolt_hit_tree
    cmp #chr_enemy_large
    bcc bolt_path_clear
    cmp #chr_enemy_large + 6
    bcc bolt_hit_bike

bolt_path_clear
    ldy bolty
    lda boltudg,y
    sta screen_base + 10 * screen_cols,x
    lda #WHITE
    sta color_base + 10 * screen_cols,x
    rts

bolt_hit_bike
    ldx #0
    lda bikex
    cmp tree_col
    beq +
    inx
+
    lda #1
    sta bikedead,x

    jsr SpawnExplosion
    rts

bolt_hit_tree
    lda #$ff
    sta bolty
    rts

boltudg
    !byte chr_bolt, chr_bolt+1, chr_bolt+2, chr_bolt+3, chr_bolt+4, chr_bolt+5