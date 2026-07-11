; Forest Chase VIC-20 — 16K port
; PRG @ $1201; screen $1000; charset $1800; map at mem top

!source "zp.asm"
!source "defines.asm"

!source "header.asm"
!source "warm.asm"
!source "util.asm"
!source "raster.asm"
!source "input.asm"
!source "init.asm"
!source "trees.asm"
!source "gameloop.asm"
!source "sound.asm"

low_bank_end = *

!ifdef pass2 {
    free_space_in_low_bank = udg_base - low_bank_end
    !warn "Free space in low bank: ", free_space_in_low_bank
}

!fill udg_base - low_bank_end, 0

*= udg_base
!source "build/gfx_pool.asm"
!source "build/tree_strips.asm"
!source "tree_movement_tables.asm"
!source "playerbike.asm"
!source "enemybikes.asm"
!source "bolt.asm"
!source "explosion.asm"
!source "bonusenemy.asm"
!source "title.asm"

prg_end = *

!ifdef pass2 {
    free_space_in_high_bank = map_base - prg_end
    !warn "Free space in high bank: ", free_space_in_high_bank
}

pass2 = 1