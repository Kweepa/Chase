!zone sectorchange

TrySectorChange
    lda bikedead
    bne +
    rts
+
    lda bikedead+1
    bne +
    rts
+
    lda explosiont
    bmi +
    rts
+

DoSectorChange

    lda #0
    sta $900a

    lda night
    asl
    asl
    sta sector_change_count
--
    ldx sector_change_count
    lda sky_colors_day_to_night,x
    sta skycol

    ldy #50
-
    jsr WaitForRaster
    tya
    clc
    adc #127
    sta $900b     ; play sound
    dey
    bpl -

    inc sector_change_count
    lda sector_change_count
    and #3
    bne --

    lda #$c2
    sta $9005

    lda night
    eor #1
    sta night

    lda #32
    jsr ClearScreenWithA
    lda night
    jsr ClearColoursWithA

    lda night
    bne +
    inc sector
+

    lda sector
    cmp #9
    bne +
    jmp DoEnding
+

    lda sector
    clc
    adc #48
    sta screen_base + 5 * screen_cols + 14

    lda #<sector_text
    sta temp_ptr
    lda #>sector_text
    sta temp_ptr+1

    ldx #7
    jsr PrintSectorChangeString

    lda #<night_patrol
    sta temp_ptr
    lda #>night_patrol
    sta temp_ptr+1

    lda night
    bne +

    lda #<day_patrol
    sta temp_ptr
    lda #>day_patrol
    sta temp_ptr+1

+
    ldx #3 * screen_cols + 5
    jsr PrintSectorChangeString

    lda lives
    clc
    adc #48
    sta screen_base + 12 * screen_cols + 3

    lda #<bikes_remaining
    sta temp_ptr
    lda #>bikes_remaining
    sta temp_ptr+1

    ldx #7 * screen_cols + 5
    jsr PrintSectorChangeString

    ldy #127
-
    jsr WaitForRaster
    dey
    bpl -

    jsr InitSector

    lda #$ce
    sta $9005

    rts

PrintSectorChangeString

    ldy #0
-
    lda (temp_ptr),y
    beq +
    sta screen_base + 5 * screen_cols,x
    inx
    iny
    bne -
+
    rts

sector_change_count
    !byte 0

sky_colors_day_to_night
    !byte PURPLE<<4, RED<<4, BLUE<<4, BLACK<<4
sky_colors_night_to_day
    !byte RED<<4, YELLOW<<4, PURPLE<<4, LIGHT_BLUE<<4

sector_text
    !scr "SECTOR",0

night_patrol
    !scr "NIGHT  PATROL",0

day_patrol
    !scr " DAY PATROL",0

bikes_remaining
    !scr "BIKES REMAINING",0