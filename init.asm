!zone init

; Port of $65B3 new-game setup (simplified; no title / Kempston choice)

InitGame
    lda #3
    sta lives

    lda #1
    sta sector

    lda #SPEED_SLOW
    sta speed

    lda #1
    sta bike_moving

    lda #0
    sta steer
    sta frame_tick
    rts

DrawHudStub
    lda #chr_digit_0 + 3
    sta hud_lives_scr
    lda #(YELLOW << 4) | WHITE
    sta hud_lives_col
    rts
