!zone bolt

InitBolt
    lda #$ff
    sta bolty
    lda #200
    sta boltsound
    rts

UpdateBoltSound
    lda boltsound
    cmp #200
    beq +
    sta $900c
    dec boltsound
    rts
+
    lda #0
    sta $900c
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
    jsr InitBolt

    jsr TryKillBonus

!if 0 {
    ; SUPER TEMP!!!
    lda #1
    sta bikedead
    sta bikedead+1
    jsr SpawnExplosion
}

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

    lda #255
    sta boltsound
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
    ; kill the alive bike in this column (dead bike X can linger)
    ldx #0
    lda bikex
    cmp tree_col
    bne +
    lda bikedead
    beq mark_bike_dead
+
    ldx #1
    lda bikex+1
    cmp tree_col
    bne +
    lda bikedead+1
    bne +
mark_bike_dead
    lda #1
    sta bikedead,x

    jsr SpawnExplosion
    jsr Add1000ToScore
+
bolt_hit_tree
    jsr InitBolt
    rts

boltudg
    !byte chr_bolt, chr_bolt+1, chr_bolt+2, chr_bolt+3, chr_bolt+4, chr_bolt+5