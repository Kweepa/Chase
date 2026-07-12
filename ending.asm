!zone ending

DoEnding

    lda #$c2
    sta $9005

    lda #LIGHT_BLUE<<4
    sta skycol

    lda #32
    jsr ClearScreenWithA
    lda #BLACK
    jsr ClearColoursWithA

    lda #<ending_text
    sta temp_ptr
    lda #>ending_text
    sta temp_ptr+1

    jsr SetBlockDestUpper
    jsr WriteTextBlock

    jsr SetBlockDestLower
    jsr WriteTextBlock

    jsr WaitForKeypress

    lda #$ce
    sta $9005

    lda #1
    sta sector
    jsr InitSector

    jsr Add1000ToScore
    jsr Add1000ToScore
    jsr Add1000ToScore
    jsr Add1000ToScore
    jsr Add1000ToScore
    jsr Add1000ToScore
    jsr Add1000ToScore
    jsr Add1000ToScore

    rts

ending_text
    !scr 0
    !scr "   CONGRATULATIONS!",0
    !scr 0
    !scr "   You have cleared",0
    !scr "  all eight sectors",0
    !scr " in this region, and",0
    !scr "    weakened the",0
    !scr "   local warlord!",0
    !scr 0
    !scr 0


    !scr "   You are rewarded",0
    !scr "  handsomely for your",0
    !scr "   skill and valour!",0
    !scr 0
    !scr "       + $8000",0
    !scr 0
    !scr "   You are sent to",0
    !scr "  the next region...",0
    !scr 0
    !scr "        Press SPACE...",0
