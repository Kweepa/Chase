!zone trees

InitTrees
    lda #0
    sta scroll_tick

    ldx #0
    txa
-
    sta map_base,x
    sta map_base+$100,x
    inx
    bne -

    ; just write a few into the map

    lda #1
    sta map_base + $47
    sta map_base + $101
    sta map_base + $7
    sta map_base + $177

    rts

ScrollTrees

    ; uses tables to scroll and perspective shunt at the same time

    ; choose forward, left or right as steering dictates
    lda #<scroll_tab_forward
    sta scroll_ptr
    lda #>scroll_tab_forward
    sta scroll_ptr + 1

    lda #<map_base
    sta map_ptr
    lda #>map_base
    sta map_ptr+1

-
    ldy #0
    lda (scroll_ptr),y
    beq +
    tay
    lda (map_ptr),y
+
    ldy #0
    sta (map_ptr),y
    inc map_ptr
    bne +
    inc map_ptr+1
+
    inc scroll_ptr
    bne +
    inc scroll_ptr+1
+
    lda map_ptr
    cmp #<(map_base + scroll_tab_bytes)
    bne -
    lda map_ptr+1
    cmp #>(map_base + scroll_tab_bytes)
    bne -

    ; direct copy forward of the last 11 lines
    ldx #0
-
    lda map_base + scroll_row_stride * 14,x
    sta map_base + scroll_row_stride * 13,x
    inx
    cpx #220
    bne -

    rts

map_row_tab
    !word map_base + 0
    !word map_base + row_stride * 1
    !word map_base + row_stride * 2
    !word map_base + row_stride * 3
    !word map_base + row_stride * 4
    !word map_base + row_stride * 5
    !word map_base + row_stride * 6
    !word map_base + row_stride * 7
    !word map_base + row_stride * 8
    !word map_base + row_stride * 9
    !word map_base + row_stride * 10
    !word map_base + row_stride * 11
    !word map_base + row_stride * 12
    !word map_base + row_stride * 13
    !word map_base + row_stride * 14
    !word map_base + row_stride * 15
    !word map_base + row_stride * 16
    !word map_base + row_stride * 17
    !word map_base + row_stride * 18
    !word map_base + row_stride * 19
    !word map_base + row_stride * 20
    !word map_base + row_stride * 21
    !word map_base + row_stride * 22
    !word map_base + row_stride * 23

FindClosestTrees
    ; go through the map for each column and find the first tree, going front to back
    ; record the depth for each tree column, from 0-24 (24 means no tree)

    lda #21
    sta tree_col

---
    lda #0
    sta tree_row

    lda #<map_base
    clc
    adc tree_col
    sta map_ptr
    lda #>map_base
    adc #0
    sta map_ptr+1
-
    ldy #0
    lda (map_ptr),y
    bne ++
    lda map_ptr
    clc
    adc #22
    sta map_ptr
    bcc +
    inc map_ptr+1
+
    inc tree_row
    lda tree_row
    cmp #24
    bne -

++
    lda tree_row
    ldx tree_col
    sta first_tree_per_column,x

    dec tree_col
    bpl ---

    rts

DrawTrees

    lda #0
    sta tree_col
---
    ; draw trees based on first_tree_per_column
    jsr DrawTreeStrip
    jsr WaitForKeypress
    inc tree_col
    lda tree_col
    cmp #22
    bne ---

    rts

DrawTreeStrip
    ldx tree_col
    lda first_tree_per_column,x
    tax

    ; draw empty column until we reach the top of the tree
    lda #>screen_base
    sta scr_ptr+1
    lda tree_col
    sta scr_ptr

    lda tree_strip_y,x
    tax
    beq tree_skip_first_clear
    ldy #0
-
    tya
    sta (scr_ptr),y
    lda scr_ptr
    clc
    adc #22
    sta scr_ptr
    bcc +
    inc scr_ptr+1
+
    dex
    bne -

tree_skip_first_clear

    lda scr_ptr
    sta col_ptr
    lda scr_ptr+1
    eor #$84
    sta col_ptr+1

draw_single_or_double_strip

    ; resolve tree_strip_ptr[depth] / tree_strip_fg_ptr[depth] -> chr/fg data
    ldx tree_col
    lda first_tree_per_column,x
    cmp #24
    bcc +
    rts
+
    tax
    asl
    tay
    lda tree_strip_ptr,y
    sta tree_ptr
    lda tree_strip_ptr+1,y
    sta tree_ptr+1
    lda tree_strip_fg_ptr,y
    sta tree_col_ptr
    lda tree_strip_fg_ptr+1,y
    sta tree_col_ptr+1

    lda tree_strip_len,x
    sta tree_tmp

    ; check for huge trees
    cpx #2
    bcs draw_single_strip

draw_double_strip

    lda tree_tmp
    asl
    sta tree_tmp

    ldx #0
-
    txa
    tay
    lda (tree_ptr),y
    ldy #0
    sta (scr_ptr),y
    lda #PURPLE
    sta (col_ptr),y    
    inx
    txa
    tay
    lda (tree_ptr),y
    ldy #1
    sta (scr_ptr),y
    lda #RED
    sta (col_ptr),y
    inx

    lda scr_ptr
    clc
    adc #22
    sta scr_ptr
    sta col_ptr
    bcc +
    inc scr_ptr+1
    inc col_ptr+1
+
    cpx tree_tmp
    bne -

    cpx #36  ; check for full height tree
    beq +

    ; fill in the last two bits
    lda #0
    tay
    sta (scr_ptr),y
    iny
    sta (scr_ptr),y

+
    rts

draw_single_strip

    ldx #0
-
    txa
    tay
    lda (tree_ptr),y
    ldy #0
    sta (scr_ptr),y
    txa
    tay
    lda (tree_col_ptr),y
    ldy #0
    sta (col_ptr),y

    lda scr_ptr
    clc
    adc #22
    sta scr_ptr
    sta col_ptr
    bcc +
    inc scr_ptr+1
    inc col_ptr+1
+
    inx
    cpx tree_tmp
    bne -

    ; now finish with empty tiles until we reach screen row 18

    ldx tree_col
    lda first_tree_per_column,x
    tax

    lda #18
    sec
    sbc tree_tmp
    sbc tree_strip_y,x
    beq ++

    tax
    ldy #0
-
    tya
    sta (scr_ptr),y
    lda scr_ptr
    clc
    adc #22
    sta scr_ptr
    bcc +
    inc scr_ptr+1
+
    dex
    bne -

++
    rts


tree_row        !byte 0
tree_shunt_n    !byte 0
tree_rows_left  !byte 0
tree_cell       !byte 0
tree_trees_left !byte 0
tree_srow       !byte 0
tree_depth      !byte 0
tree_slice      !byte 0
tree_sr_anchor  !byte 0
tree_col        !byte 0
tree_plot_chr   !byte 0
tree_off        !byte 0
tree_mark_save  !byte 0
tree_mi_row     !byte 0
tree_mi_col     !byte 0
tree_plant_try  !byte 0
tree_tmp        !byte 0

first_tree_per_column
    !fill 22, 0