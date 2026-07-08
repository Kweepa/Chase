; Zero page — game state

frame_tick    = $f0
steer         = $f1      ; -1 left, 0 centre, +1 right
bike_moving   = $f2
speed         = $f3
sector        = $f4
lives         = $f5
scroll_tick   = $f6
scroll_phase  = $f8      ; flip-flop like Spectrum $64F3

stickleft     = $37
stickright    = $38
stickup       = $39
stickfire     = $3a

scr_ptr       = $05
col_ptr       = $07
map_ptr       = $15
cm_ptr        = $17
col_map_ptr   = $19
scroll_ptr    = $1b
tree_ptr      = $1d
tree_col_ptr  = $1f