; One-shot boot: VIC init, start game (no title screen).

!zone warm

WarmStart
    lda #$7f
    sta $911d
    sta $911e

    cld
    ldx #$ff
    txs

    jsr $fdf9                   ; IOINIT — VIC screen defaults ($1000, 22×23)
    sei

    ldy #10
-
    ldx .vic_offset,y
    lda .vic_val,y
    sta $9000,x
    dey
    bpl -

    jsr InitRasterSplit         ; stable raster IRQ: light blue top, green from row 10

    jmp BootGame

; charset $1800 ($9005=$CE); silence voices; set border to light blue
.vic_offset
    !byte 0, 1, 2, 3, 5, $a, $b, $c, $d, $e, $f
.vic_val
    !byte 11, 40, 23, 44, $ce, 0, 0, 0, 0, 10, (14<<4)|8
