!zone trees

InitTrees
    ldx #0
    txa
-
    sta map_base,x
    sta map_base+$100,x
    sta map_base+$200,x
    inx
    bne -

    ; just write a few into the map

    lda #1
    sta map_base + $47
    sta map_base + $101
    sta map_base + $7
    sta map_base + $177

    rts

ClearDistantTrees
    ; clear distant row
    ldx #map_cols - 1
    lda #0
-
    sta map_base + map_cols * (map_rows - 1),x
    dex
    bpl -

    rts

PlantTrees

    ; every other frame
    lda frame_tick
    and #1
    bne ++

    ; fill with random trees based on density
    ldy sector
    ldx #(map_cols - 1)
-
    jsr GetRandom16 ; with random8 we see the patterns easily
    cmp tree_density-1,y
    bcs +
    lda #1
    sta map_base + map_cols * (map_rows - 1),x
    dex ; no two trees together
+
    dex
    bpl -

++

    rts

MoveTrees

    ; uses tables to move forward and perspective shunt at the same time

    ; choose forward, left or right as steering dictates

    ; every other frame, merge in turning
    lda frame_tick
    and #1
    bne + ; if it's 1, we use the center table
    ldx steer
    inx
    txa
+
    asl
    tax
    lda tree_movement_tables,x
    sta tree_move_ptr
    lda tree_movement_tables+1,x
    sta tree_move_ptr+1

    lda #<map_base
    sta map_ptr
    lda #>map_base
    sta map_ptr+1

-
    ldy #0
    lda (tree_move_ptr),y
    beq +
    tay
    lda (map_ptr),y
+
    ldy #0
    sta (map_ptr),y
    sta temp2
    inc map_ptr
    bne +
    inc map_ptr+1
+
    inc tree_move_ptr
    bne +
    inc tree_move_ptr+1
+
    lda map_ptr
    cmp #<(map_base + tree_move_tab_bytes)
    bne -
    lda map_ptr+1
    cmp #>(map_base + tree_move_tab_bytes)
    bne -

    rts

tree_depth_to_strip_index
    !byte 0, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 25, 25, 25

max_height_per_column
    !byte 18, 18, 18, 18, 18, 18, 18, 18, 16, 16, 16, 16, 16, 16, 16, 18, 18, 18, 18, 18, 18, 18, 18

FindClosestTrees
    ; go through the map for each column and find the first tree, going front to back
    ; record the depth for each tree column, from 0-24 (24 means no tree)

    lda #screen_cols-1
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
    adc #screen_cols
    sta map_ptr
    bcc +
    inc map_ptr+1
+
    inc tree_row
    lda tree_row
    cmp #map_rows
    bne -

++
    ldx tree_col
    lda tree_row
    sta first_tree_per_column,x
    tay
    lda tree_depth_to_strip_index,y
    sta tree_strip_per_column,x

    dec tree_col
    bpl ---

    ; fatten the huge trees (expand to the right)
    ldx #screen_cols-2 ; tree_col
-
    ; for a 0 or 2 in the left column, add 1 or 3 to the right column
    lda tree_strip_per_column,x
    cmp #4
    bcs +
    adc #1 ; carry clear
    sta tree_strip_per_column+1,x
+
    ; for a 0 or 1 in the left column, extend to the right column
    lda first_tree_per_column,x
    cmp #2
    bcs +
    sta first_tree_per_column+1,x
+
    dex
    bpl -

    rts

DrawTrees

    lda #0
    sta tree_col
---
    ; draw trees based on first_tree_per_column
    jsr DrawTreeStrip
    inc tree_col
    lda tree_col
    cmp #screen_cols
    bne ---

    rts

DrawTreeStrip
    ldx tree_col
    lda tree_strip_per_column,x
    tax

    ; draw empty column until we reach the top of the tree
    lda #>screen_base
    sta scr_ptr+1
    lda tree_col
    sta scr_ptr

    lda tree_strip_y,x

    ldy tree_col
    cmp max_height_per_column,y  ; min(tree_strip_y, max_height_per_column)
    bcc +
    lda max_height_per_column,y
+

    tax
    beq tree_skip_first_clear
    ldy #0
-
    tya
    sta (scr_ptr),y
    lda scr_ptr
    clc
    adc #screen_cols
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

    ; resolve tree_strip_ptr[depth] / tree_strip_fg_ptr[depth] -> chr/fg data
    ldx tree_col
    lda tree_strip_per_column,x
    cmp #25
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

    ldy tree_col
    cmp max_height_per_column,y ; avoid drawing over the handlebars, this only needs to work for the huge trees
    bcc +
    lda max_height_per_column,y
+
    sta tree_tmp

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
    adc #screen_cols
    sta scr_ptr
    sta col_ptr
    bcc +
    inc scr_ptr+1
    inc col_ptr+1
+
    inx
    cpx tree_tmp
    bne -

    ; now finish with empty tiles until we reach screen row 18 (or 16 when over the handlebars)

    ldx tree_col
    lda tree_strip_per_column,x
    tax

    ldy tree_col    
    lda max_height_per_column,y
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
    adc #screen_cols
    sta scr_ptr
    bcc +
    inc scr_ptr+1
+
    dex
    bne -

++
    rts


tree_row        !byte 0
tree_col        !byte 0
tree_tmp        !byte 0

first_tree_per_column
    !fill screen_cols
tree_strip_per_column
    !fill screen_cols
