; One-shot boot: VIC init, start game (no title screen).

!zone warm

WarmStart
    lda #$7f
    sta $911d
    sta $911e

    cld
    ldx #$ff
    txs

    sei

    ldy #10
-
    ldx .vic_offset,y
    lda .vic_val,y
    sta $9000,x
    dey
    bpl -

    jsr InitRasterSplit         ; stable raster IRQ

    ; copy down the digit chr definitions
    ldx #79
-
    lda $8000 + 8 * 48, x
    sta udg_base + 8 * chr_digit_0, x
    dex
    bpl -

    ; reset hiscore
    ldx #5
    lda #0
-
    sta hiscore,x
    dex
    bpl -

    jmp BootGame

; charset $1800 ($9005=$CE); silence voices; set border to light blue
.vic_offset
    !byte 0, 1, 2, 3, 5, $a, $b, $c, $d, $e, $f
.vic_val
    !byte 11, 40, 23, 44, $ce, 0, 0, 0, 0, 10, (14<<4)|8
