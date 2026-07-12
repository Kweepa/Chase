; Stable VIC-20 raster IRQ — dual background split at playfield row 10.
;
; Adapted from Marko Makela's auxiliary-timer scheme for the VIC-20
; (PAL 6561-101: 71 cycles/line, 312 lines/frame).  $9004 holds the upper
; 8 bits of the raster counter and changes only on every second line.
;
; Reference:
;   http://codebase64.net/doku.php?id=interrupts:making_stable_raster_routines
;
; Chase uses two IRQs per frame:
;   VIA2 Timer A (periodic) - top of frame: restore light-blue sky ($900F)
;   VIA2 Timer B (one-shot, re-armed each frame) - row 10: green grass ($900F)
; VIA2 ($9120-$912F) register map on the VIC-20:
;   $912D  IFR - interrupt flags (read; write 1 to clear a bit)
;   $912E  IER - interrupt enable (write $80|mask to enable, $00|mask to disable)

!zone raster

; Raster split
LIGHT_BLUE          = 14
BG_TOP              = (LIGHT_BLUE << 4) | 8
BG_BOTTOM           = (GREEN << 4) | 8

; Raster split timing — PAL 6561-101 (71 CPU cycles/scanline, 312 lines/frame).
; See raster.asm (Marko Makela / Codebase64 stable-raster routine).
;
; RASTER_SYNC_DOUBLE — $9004 value waited on at InitRasterSplit; each step is
;   one double raster line (2 scanlines). Positions the per-frame top IRQ.
; FRAME_TIMER_PAL — VIA2 Timer A reload: one IRQ per frame (312×71 − 2).
; ROW10_DELAY_PAL — VIA2 Timer B one-shot: CPU cycles from top IRQ (light blue)
;   to green split at playfield row 10 horizon. Tune on hardware.
RASTER_SYNC_DOUBLE  = 27
SCANLINE_CYCLES     = 71
FRAME_TIMER_PAL     = 312 * SCANLINE_CYCLES - 2
ROW10_DELAY_PAL     = 83 * SCANLINE_CYCLES + 40


InitRasterSplit
    lda #$7f
    sta $912e                   ; disable and acknowledge VIA2 interrupts
    sta $912d
    sta $911e                   ; disable NMIs (Restore key)

; synchronize with the screen
.sync
    ldx #RASTER_SYNC_DOUBLE       ; wait for this raster line (times 2)
.sync_wait
    cpx $9004
    bne .sync_wait              ; at this stage, the inaccuracy is 7 clock cycles
                                ; the processor is in this place 2 to 9 cycles
                                ; after $9004 has changed
    ldy #9
    bit $24
.sync_loop
    ldx $9004
    txa
    bit $24
    ldx #24                     ; PAL: spend time so the whole loop is 2 raster lines
    dex
    bne *-1
    cmp $9004
    bcs *+2                     ; save one cycle if $9004 changed too late
    dey
    bne .sync_loop
                                ; now it is fully synchronized
                                ; 6 cycles have passed since last $9004 change

; initialize the timers
.timers
    lda #$40                    ; enable Timer A free run of both VIAs
    sta $911b
    sta $912b

    lda #<FRAME_TIMER_PAL
    ldx #>FRAME_TIMER_PAL
    sta $9116                   ; load the timer low byte latches
    sta $9126

    ldy #7                      ; PAL: little delay to place the raster effect
    dey
    bne *-1
    nop
    nop

    stx $9125                   ; start the IRQ timer A (VIA2)
                                ; 6561-101: 77 cycles from $9004 change
    ldy #10                     ; spend some time (1+5*9+4=55 cycles)
    dey                           ; before starting the reference timer
    bne *-1
    stx $9115                   ; start the reference timer (VIA1)

.pointers
    lda #<RasterDispatcher
    sta $0314
    lda #>RasterDispatcher
    sta $0315
    lda #$c0
    sta $912e                   ; enable Timer A underflow interrupts on VIA2 IER
    cli
    rts

; IRQ entry — dispatch VIA2 Timer A (top) vs Timer B (row 10).
RasterDispatcher
    lda $912d
    and #$40
    bne TopIrq
    lda $912d
    and #$20
    bne Row10Irq

    jmp DummyIRQ

; Top of frame: light-blue sky, then arm row-10 one-shot.
TopIrq
    lda #$40
    sta $912d                   ; acknowledge VIA2 Timer A

    jsr RasterSync

    lda $900f
    and #$0f
    ora skycol
    sta $900f

    lda #<ROW10_DELAY_PAL
    ldx #>ROW10_DELAY_PAL
    sta $9128                   ; load Timer B latch low (T2L-L)
    stx $9129                   ; write T2C-H — starts Timer B one-shot
    lda #$a0
    sta $912e                   ; enable Timer B underflow interrupt on VIA2 IER

    jsr UpdateBoltSound

    jmp DummyIRQ

; Row 10 horizon: green grass background.
Row10Irq
    lda #$20
    sta $912d                   ; acknowledge VIA2 Timer B

    jsr RasterSync

    lda $900f
    and #$0f
    ora #BG_BOTTOM
    sta $900f

    lda #$20
    sta $912e                   ; disable Timer B in VIA2 IER until re-armed next frame

    jmp DummyIRQ

; Auxiliary-timer NOP-slide — removes up-to-7-cycle IRQ entry jitter.
; (Marko Makela / Codebase64 stable raster routine.)
RasterSync
    lda $9114                   ; get the reference timer A value
                                ; (42 to 49 cycles delay at this stage)
    cmp #8                      ; are we more than 7 cycles ahead of time?
    bcc .rs0
    pha                         ; yes, spend 8 extra cycles
    pla
    and #7                      ; and reset the high bit
.rs0
    cmp #4
    bcc .rs1
    bit $24                     ; waste 4 cycles
    and #3
.rs1
    cmp #2                        ; spend the rest of the cycles
    bcs *+2
    bcs *+2
    lsr
    bcs *+2                     ; now it has taken 82 cycles from the beginning of the IRQ
    rts


DummyIRQ ; replacement for $eabf
    pla
    tay
    pla
    tax
    pla
    rti