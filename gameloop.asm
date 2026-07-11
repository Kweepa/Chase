!zone gameloop

BootGame
    lda #0
    jsr ClearScreenWithA
    jsr DoTitleScreen

    jsr InitGame

    jsr DrawUIFrame
    jsr DrawBikeHandlebars

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
    jsr DrawUIStub
    jsr UpdateEngineSound
    inc frame_tick
    jsr TryCrash
    jmp main_loop
