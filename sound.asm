!zone sound

; Bass voice ($900A): bit 7 = on, bits 6-0 = pitch

UpdateEngineSound

    lda speed
    asl
    asl
    asl
    asl
    asl
    adc #96
    sta $900a
    rts
