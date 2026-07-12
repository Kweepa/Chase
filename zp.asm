; Zero page — game state

frame_tick    = $f0
steer         = $f1      ; -1 left, 0 centre, +1 right
speed         = $f2
sector        = $f3
night         = $f4
lives         = $f5
skycol        = $f6
score         = $f7      ; 6 bytes, one per digit
hiscore       = $e7

bikedir       = $d0 ; per bike
bikex         = $d2
bikedirtimer  = $d4
bikedead      = $d6

bikez         = $d8 ; shared
bikeztimer    = $d9

boltx         = $c0
bolty         = $c1
boltoff       = $c2 ; an offset from the horizon so we can quickly render without using a lookup table
boltfired     = $c3
boltsound     = $c4

explosiont    = $c5
explosionx    = $c6
explosioncol  = $c7

bonusdelay    = $c8
bonusx        = $c9
bonusy        = $ca
bonusdead     = $cb
bonusexp      = $cc ; bonus explosion draw timer
bonusvis      = $cd
bonustime     = $ce

stickleft     = $37
stickright    = $38
stickup       = $39
stickfire     = $3a

tree_row      = $40
tree_col      = $41
tree_tmp      = $42
first_tree_per_column = $43
tree_strip_per_column = $5a

scr_ptr       = $05
col_ptr       = $07
temp_ptr      = $09
udg_src_ptr   = $0b
udg_mix_ptr   = $0d
udg_dst_ptr   = $0f
bonus_ptr     = $11
map_ptr       = $15
tree_move_ptr = $1b
tree_ptr      = $1d
tree_col_ptr  = $1f
random        = $21
random8       = $23
temp1         = $24
temp2         = $25