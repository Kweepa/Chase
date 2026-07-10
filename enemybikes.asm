!zone enemybikes

InitBikes
    lda #7
    sta bikedirtimer
    sta bikedirtimer+1

    lda #0
    sta bikedir
    sta bikedir+1
    sta bikedead
    sta bikedead+1

    lda #-1
    sta bikex
    lda #map_cols
    sta bikex+1

    lda #4
    sta bikez
    rts

UpdateEnemyBikes

    jsr MoveBikesInZ

    ; one bike moves per frame
    lda frame_tick
    and #1
    tax
-
    lda bikedead,x
    beq +
    rts
+

    ; change direction
    ldy bikedirtimer,x
    dey
    bpl +++
    jsr GetRandom16
    pha
    lsr ; bits 3-4
    lsr
    lsr
    and #3
    cmp #3 ; keep going in the same direction
    beq ++
    tay     ; 0-2 become -1,0,1
    dey
    sty bikedir,x
++
    pla
    and #7
    tay
+++
    sty bikedirtimer,x

    ; move and clamp bike (columns 0 .. map_cols-1)
    lda bikex,x
    clc
    adc bikedir,x
    sec
    sbc steer
    cmp #128            ; negative
    bcc +
    lda #-2             ; allow for both bikes off screen on the left
    bmi ++
+
    cmp #map_cols+1       ; allow for both bikes off screen on the right
    bcc ++
    lda #map_cols+1
++
    sta bikex,x

    jsr PushBikesApart

    rts

MoveBikesInZ
    ; move z forward and back depending on player speed
    ; z=0 closest; z=4 furthest and invisible

    dec bikeztimer
    bne +
    lda #30
    sta bikeztimer

    lda speed
    cmp #2
    beq get_closer

get_further
    lda bikez
    cmp #4
    beq +
    inc bikez
+
    rts

get_closer
    lda bikez
    beq +
    dec bikez
+
    rts

PushBikesApart
    ; push bikes apart
    lda bikedead
    bne +
    lda bikedead+1
    bne +
    lda bikex
    cmp bikex+1
    bne +
    inc bikex+1
+
    rts

bike_colors
    !byte YELLOW, BLUE
bike_index
    !byte 0
bike_start_udg
    !byte 0

DrawEnemyBikes

    ; skip when bikes are too far away to see
    lda bikez
    cmp #4
    bne +
    rts
+

    ; skip when the tree is big and would obscure the bike
    ldx tree_col
    lda tree_strip_per_column,x
    cmp #9
    bcs +
    rts
+

    ; loop over bikes
    lda #1
    sta bike_index
-
    ; skip if bike is not in this column
    ldx bike_index
    lda bikex,x
    cmp tree_col
    bne +

    ; skip if bike is dead
    lda bikedead,x
    bne +

    jsr DrawEnemyBike

+
    dec bike_index
    bpl -

    rts

DrawEnemyBike

    lda bikez
    bne +
    lda #chr_enemy_large
    jmp DrawBikeLarge ; tail call
+
    cmp #1
    bne +
    lda #chr_enemy_medium
    jmp DrawBikeLarge ; tail call
+
    cmp #2
    bne +
    lda #chr_enemy_small
    jmp DrawBikeSmall ; tail call
+
    lda #chr_enemy_bike
    ; fall into

DrawBikeSmall
    sta bike_start_udg
    ldy bikedir,x
    iny
    tya
    clc
    adc bike_start_udg
    ldx tree_col
    sta screen_base + 9*screen_cols,x
    ldy bike_index
    lda bike_colors,y
    sta color_base + 9*screen_cols,x
    rts

DrawBikeLarge
    sta bike_start_udg
    ldy bikedir,x
    iny
    tya
    asl
    clc
    adc bike_start_udg
    ldx tree_col
    sta screen_base + 9*screen_cols,x
    adc #1
    sta screen_base + 10*screen_cols,x
    ldy bike_index
    lda bike_colors,y
    sta color_base + 9*screen_cols,x
    sta color_base + 10*screen_cols,x
    rts
