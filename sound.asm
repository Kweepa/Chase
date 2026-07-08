!zone sound

; Bass voice ($900A): bit 7 = on, bits 6-0 = pitch

UpdateEngineSound
    lda bike_moving
    beq .silence

    lda speed
    beq .fast
    lda #140                  ; slow engine pitch
    bne .set
.fast
    lda #160
.set
    ora #$80
    sta $900a
    rts

.silence
    lda #0
    sta $900a
    rts
