!zone gameloop

BootGame
    jsr ClearScreen
    jsr InitTrees
    jsr InitGame

    jsr DrawBikeBody
    jsr DrawBikeHandlebars

    ; fall through to main_loop for now

main_loop
    jsr ReadInput
    jsr ScrollTrees

    lda #214
    sta screen_base
    lda #0
    sta color_base

    jsr WaitForKeypress

    jsr FindClosestTrees
    jsr DrawTrees

    lda #216
    sta screen_base
    lda #0
    sta color_base

    jsr WaitForKeypress

    jsr DrawBikeHandlebars
    jsr DrawHudStub
    jsr UpdateEngineSound

    inc frame_tick

    jsr WaitForRaster

    jmp main_loop
