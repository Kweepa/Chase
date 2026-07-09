; Zero page — game state

frame_tick    = $f0
steer         = $f1      ; -1 left, 0 centre, +1 right
speed         = $f2
sector        = $f3
lives         = $f4

bikedir       = $d0 ; per bike
bikex         = $d2
bikedirtimer  = $d4

bikez         = $d6 ; shared
bikeztimer    = $d7

stickleft     = $37
stickright    = $38
stickup       = $39
stickfire     = $3a

scr_ptr       = $05
col_ptr       = $07
temp_ptr      = $09
map_ptr       = $15
tree_move_ptr = $1b
tree_ptr      = $1d
tree_col_ptr  = $1f
random        = $21
random8       = $23
temp1         = $24
temp2         = $25