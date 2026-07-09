!zone util

ClearScreen
    ldx #0
-
    lda #0
    sta screen_base,x
    sta screen_base + $100,x
    inx
    bne -

    rts

WaitForRaster
    ; wait for raster below sync band (inlined WaitForRasterLineLessThan)
-
    lda $9004
    and #$fe
    cmp #RASTERLINE_PAL
    bcs -
    ; fall through

WaitForRasterLine
    lda $9004
    and #$fe
    cmp #RASTERLINE_PAL
    bne WaitForRasterLine
    rts

WaitForKeypress
    ldx #$ef
-
    jsr ScanKeyRow
    bne -
-
    jsr ScanKeyRow
    beq -
    rts

    ; from Stephen Judd's the Fridge rand1.s, corrected with a clc
    ; basically new = 5 * old + $3611
GetRandom16
    lda random+1     
    sta temp1        
    lda random       
    asl              
    rol temp1        
    asl              
    rol temp1        
    clc              
    adc random       
    pha              
    lda temp1        
    adc random+1     
    sta random+1     
    pla              
    clc             ; added this instruction - kweepa
    adc #$11         
    sta random       
    lda random+1     
    adc #$36         
    sta random+1     
    rts 

    ; from my post in More Random Questions on the denial forum
    ; basically new = 9 * old + 193
GetRandom8
    lda random8
    asl
    asl
    asl
    clc
    adc random8
    clc
    adc #193
    sta random8
    rts
