; Zero page — game state

frame_tick    = $f0
steer         = $f1      ; -1 left, 0 centre, +1 right
speed         = $f2
sector        = $f3
lives         = $f4
score         = $f5      ; 3 bytes
skycol        = $f6

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

explosiont    = $c4
explosionx    = $c5
explosioncol  = $c6

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