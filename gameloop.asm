!zone gameloop

BootGame
    lda #0
    jsr ClearScreenWithA
    jsr DoTitleScreen

    jsr InitGame

    ; fall through to main_loop for now

main_loop
    jsr ReadInput
    jsr TurnBikeHandlebars
    jsr ClearDistantTrees
    jsr PlantTrees
    jsr MoveTrees
    jsr FindClosestTrees
    jsr UpdateEnemyBikes
    jsr UpdateBolt
    jsr UpdateBonus
    jsr DrawTrees
    jsr DrawExplosion
    jsr UpdateExplosion
    jsr UpdateEngineSound
    jsr UpdatePlayer
    inc frame_tick
    jsr TryCrash
    jsr TrySectorChange
    lda lives
    bne main_loop
    beq BootGame
