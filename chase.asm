; Chase VIC-20 — 16K cassette port (first pass)
; PRG @ $1201; screen $1000; map $5DF0; charset $1800

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
!source "playerbike.asm"

low_bank_end = *
!if low_bank_end > udg_base {
!error "low bank overflow past udg_base by ", low_bank_end - udg_base
}
!fill udg_base - low_bank_end, 0

*= udg_base
!source "build/gfx_pool.asm"
!source "build/tree_strips.asm"
!source "scroll.asm"

prg_end = *

; Warn once assembly has converged (skip early passes where low_bank_end may change).
low_bank_free = udg_base - low_bank_end
!ifdef low_bank_end_prev {
!if low_bank_end = low_bank_end_prev {
!ifndef low_bank_warned {
!warn "low bank free before udg_base: ", low_bank_free
low_bank_warned = 1
}
}
}
low_bank_end_prev = low_bank_end
