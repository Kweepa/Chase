!zone input

;
; ScanKeyRow
;
; call with the row in .X ($fe,$fd,$fb,$f7,$ef,$df,$bf,$7f)
; Z set = no key pressed, Z clear = key pressed
;
; left to right is LSB-MSB
; fe -> 1,3,5,7,9,-,DEL,
; fd ->  ,W,R,Y,I,P,],RET
; fb ->  ,A,D,G,J,L,',
; f7 -> LSH,X,V,N,<,/,
; ef -> SPC,Z,C,B,M,>,RSH,
; df -> CTL,S,F,H,K,;,
; bf -> Q,E,T,U,O,[,
; 7f -> 2,4,6,8,0,=,
;


ScanKeyRow
    ldy #$ff    ; restore DDR for VIA2
    sty $9122
    iny ; set to 0
    sty $9123   ; set data direction for $9121
    stx $9120   ; request row
    lda $9121   ; read
    eor #$ff    ; $ff is no keys pressed
    rts

; Passive $9111 read (do not touch $9113 — IEC/cassette sensitive).
ScanJoystick
    lda #$7f
    sta $9122
    lda $9111
    eor #$ff
    lsr
    lsr
    tay
    and #1
    sta stickup
    tya
    lsr
    lsr
    tay
    and #1
    sta stickleft
    tya
    lsr
    and #1
    sta stickfire
    lda $9120
    eor #$ff
    and #$80                    ; bit 7 = right
    clc
    rol
    rol
    sta stickright
    rts

; JSW-Tape controls: row $bf / stick left, row $fd / stick right
ReadInput
    lda #0
    sta steer

    jsr ScanJoystick

    lda #1
    sta speed
    ldx #$ef
    jsr ScanKeyRow
    ora stickup
    beq +
    lda #2
    sta speed
+

    ldx #$fb
    jsr ScanKeyRow
    ora stickfire
    sta boltfired

    ldx #$bf
    jsr ScanKeyRow
    ora stickleft
    beq .try_right
    lda #$ff
    sta steer
    rts

.try_right
    ldx #$fd
    jsr ScanKeyRow
    ora stickright
    beq .done
    lda #1
    sta steer
.done
    rts
