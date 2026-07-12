!zone title

title_text
    !scr 0
    !scr "  MICROMEGA presents",0
    !scr 0
    !scr "      DEATHCHASE",0
    !scr 0
    !scr "  by MJ Estcourt 1983",0
    !scr 0
    !scr "    VIC-20 port by",0
    !scr "   Steve McCrea 2026",0
    !scr 0

help_text_1
    !scr " 2501. 100 years after",0
    !scr " the Great War. Mighty",0
    !scr "  warlords fight over", 0
    !scr "   forest territory.",0
    !scr " As an elite mercenary,",0
    !scr " you patrol the forest",0
    !scr " shooting enemy Riders",0
    !scr "   for $1000 a time.",0
    !scr 0
    !scr "        Press SPACE...",0

help_text_2

    !scr "  You may find tanks",0
    !scr " and helicopters too -",0
    !scr "  your masters reward",0
    !scr " you particularly well",0
    !scr " if you destroy these.",0
    !scr 0
    !scr 0
    !scr 0
    !scr 0
    !scr "        Press SPACE...",0

help_text_3

    !scr " You can only fire at",0
    !scr " the other Riders when",0
    !scr " at top speed and can",0
    !scr "  only hit them when",0
    !scr "   close. Your range",0
    !scr " indicator will flash",0
    !scr "and your purse increase",0
    !scr " while in hot pursuit.",0
    !scr 0
    !scr "        Press SPACE...",0

help_text_4
    !scr "  It is said that the",0
    !scr "  greatest reward is",0
    !scr "kept for the Rider who",0
    !scr "  can penetrate eight",0
    !scr "sectors - you will need",0
    !scr "every ounce of skill to",0
    !scr "      find out...",0
    !scr 0
    !scr 0
    !scr "        Press SPACE...",0

help_text_5
    !scr "Controls",0
    !scr "The keys for play are:",0
    !scr 0
    !scr "Q,E,T,U,O... left",0
    !scr "W,R,Y,I,P... right",0
    !scr "A,D,G,J,L... fire",0
    !scr "Z,C,B,M,Spc..accelerate",0
    !scr 0
    !scr 0
    !scr "        Press SPACE...",0

DoTitleScreen

    lda #$c2
    sta $9005 ; normal text screen

    lda #BG_TOP
    sta skycol

    lda #32
    jsr ClearScreenWithA
    lda #BLACK
    jsr ClearColoursWithA

    lda #<title_text
    sta temp_ptr
    lda #>title_text
    sta temp_ptr+1

    jsr SetBlockDestUpper
    jsr WriteTextBlock

    lda #4
    sta title_loop
-
    jsr SetBlockDestLower
    jsr WriteTextBlock
    jsr WaitForKeypress

    dec title_loop
    bpl -

    lda #$ce
    sta $9005

    rts

SetBlockDestUpper
    lda #0
    sta scr_ptr
    lda #>screen_base
    sta scr_ptr+1
    rts

SetBlockDestLower
    lda #<screen_base + 11 * screen_cols
    sta scr_ptr
    lda #>screen_base + 11 * screen_cols
    sta scr_ptr+1
    rts


WriteTextBlock

    lda #0
    sta title_x

    ldx #9
---
    ; clear the line before writing new line
    ldy #22
-
    lda #32
    sta (scr_ptr),y
    dey
    bpl -    
--

    ldy #0
    lda (temp_ptr),y
    inc temp_ptr
    bne +
    inc temp_ptr+1
+
    cmp #0
    beq +

    ldy title_x
    sta (scr_ptr),y
    inc title_x
    bne --
+
    lda #0
    sta title_x

    lda scr_ptr
    clc
    adc #screen_cols
    sta scr_ptr
    bcc +
    inc scr_ptr+1
+
    dex
    bpl ---

    rts

title_loop
    !byte 0
title_x
    !byte 0