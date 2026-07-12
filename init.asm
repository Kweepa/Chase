!zone init

InitGame

    lda #3
    sta lives

    lda #1
    sta sector

    lda #0
    sta night

    lda #0
    sta frame_tick

    jsr InitTrees
    jsr InitPlayerBike
    jsr InitSector

    lda #BG_TOP
    sta skycol

    jsr ResetScore

    rts

InitSector
    jsr InitBikes
    jsr InitBolt
    jsr InitExplosion
    jsr InitBonus
    jsr InitPlayerBike
    jsr DrawUIFrame
    jsr DrawBikeHandlebars
    jsr DrawHiScore

    rts

InitAfterCrash
    jsr InitTrees
    jsr InitBolt
    jsr InitExplosion
    jsr InitPlayerBike

    rts