!zone gameloop

BootGame
    jsr ClearScreen
    jsr InitTrees
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
    jmp main_loop
