;*** Map.asm - Operations on map (track) ***************************************

InitMap:
        lda #<.blockdestaddresses
        sta ZP2
        lda #>.blockdestaddresses
        sta ZP3                 ;ZP2 and ZP3 = address of table with destination addresses in tilemap
        stz .tableindex         ;reset index for table with destination addresses

        lda _xstartblock
        dec                     ;draw map with top left corner one block above and one block to the left of car(s)                     
        and #31
        tax
        lda _ystartblock
        dec                     ;draw map with top left corner one block above and one block to the left of car(s)
        and #31
        tay

        ;Draw 16 blocks to tile map
        ;1 - get address of current block
-       sty ZP0
        stz ZP1                 ;store blockmap row
        phy
        +MultiplyBy32 ZP0       ;multiply row*32 because there is 32 blocks in each row
        txa
        clc
        adc ZP0                 ;add blockmap column
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1
        
        lda _blockmap_lo
        clc
        adc ZP0                 ;add base address of blockmap
        sta ZP0
        lda _blockmap_hi
        adc ZP1                 ;now ZP0 and ZP1 = address of current block
        sta ZP1

        ;2 - get destination address from predefined table and set VERA registers
        lda #$10
        sta VERA_ADDR_H        ;Auto increment one when writing to VERA RAM
        lda .tableindex         ;counter for the blocks that will be drawn on tile map       
        asl                     ;multiply block counter with 2 (dest addresses are 2 bytes each)
        tay
        lda (ZP2),y             ;read where in tile map to put block (low byte)
        sta VERA_ADDR_L
        iny
        lda (ZP2),y             ;read where in tile map to put block (high byte)
        sta VERA_ADDR_M 
        inc .tableindex

        ;3 - read current block and copy it to tilemap
        lda (ZP0)               ;read current block
        phx
        jsr CopyMapBlock
        plx

        ;4 - get column and row in blockmap for next block to copy
        ply                     
        inx                     ;increase column
        txa
        and #31                 ;wrap around if bigger than 31
        tax
        inc .colcounter         
        lda .colcounter 
        cmp #4                  ;four columns copied?
        bne -                   ;next column
        stz .colcounter
        txa                     
        clc
        adc #28                 ;yes - row is completed, return to start column by adding 32-4 = 28 and wrap around
        and #31
        tax
        iny                     ;increase row
        tya
        and #31                 ;wrap around if bigger than 31
        tay
        inc .rowcounter
        lda .rowcounter
        cmp #4                  ;four rows copied?
        bne -                   ;next row
        stz .rowcounter
        rts

.colcounter     !byte 0
.rowcounter     !byte 0
.tableindex     !byte 0

.blockdestaddresses     !word L0_MAP_ADDR     , L0_MAP_ADDR+ $10, L0_MAP_ADDR+ $20, L0_MAP_ADDR+ $30
                        !word L0_MAP_ADDR+$200, L0_MAP_ADDR+$210, L0_MAP_ADDR+$220, L0_MAP_ADDR+$230
                        !word L0_MAP_ADDR+$400, L0_MAP_ADDR+$410, L0_MAP_ADDR+$420, L0_MAP_ADDR+$430
                        !word L0_MAP_ADDR+$600, L0_MAP_ADDR+$610, L0_MAP_ADDR+$620, L0_MAP_ADDR+$630
                        
UpdateMapColumn:                        ;IN: column offset in .A (0 = update for scrolling left, 3 = update for scrolling right)
        sta .columnoffset               

        lda .newcamblockxpos            ;tile map is always drawn with topleft corner one block above and one block left of camera position
        dec
        and #31
        sta .blockxpos
        lda .newcamblockypos
        dec
        and #31
        sta .blockypos

        lda #$10
        sta VERA_ADDR_H                ;Auto increment one when writing to VERA RAM

        ;Loop through the 4 blocks in column
        ldx #0                          ;counter for the 4 blocks that will be drawn on tile map 
        ldy .blockypos                  ;current row to copy from
        
        ;Calculate source address in block map
-       sty ZP0                         ;calculate row offset in block map and store address in ZP0 and ZP1
        stz ZP1
        +MultiplyBy32 ZP0               

        lda .blockxpos                  ;add column offset
        clc
        adc .columnoffset               ;add 0 or 3 to x offset depending on column to the left or 3 columns to the right should be updated
        and #31                         ;wrap around, tile map width is 32
        adc ZP0                         
        sta ZP0 
        lda ZP1
        adc #0
        sta ZP1
        
        lda ZP0                         ;add base address of block map
        clc
        adc _blockmap_lo
        sta ZP0
        lda ZP1
        adc _blockmap_hi
        sta ZP1                         ;finally address of current block to copy is in ZP0 and ZP1

        ;Calculate destination address
        lda .columnoffset
        beq +
        lda .blockxpos                  ;calculate column offset in tile map and store address in ZP2 and ZP3
        sec 
        sbc _xstartblock
        bra ++
+       lda .blockxpos
        sec
        sbc _xstartblock
        inc
++      and #3                          ;wrap around, there are only 4 block columns in map
        sta ZP2
        stz ZP3
        +MultiplyBy16 ZP2

        txa                             ;calculate y offset in tile map (always 0-3).
        clc                             
        adc .blockypos
        sec
        sbc _ystartblock                ;start copy on block x pos - (x start block + 1)
        inc           
        and #3                          
        asl                             ;multiply row by 2 and store in high byte (a row in the tile map is $200 bytes)
        sta ZP3                         

        clc
        adc #>L0_MAP_ADDR
        sta ZP3                         ;finally destination address in tile map is in ZP2 and ZP3

        ;Copy block
        lda ZP2
        sta VERA_ADDR_L
        lda ZP3
        sta VERA_ADDR_M               ;set tile map destination address        
        lda (ZP0)                       ;read block index from block map
        phx
        phy
        jsr CopyMapBlock               
        ply
        plx

        iny                             ;increase block row
        tya
        and #31                         ;wrap around vertically (after row 31 comes row 0)
        tay
        inx
        cpx #4
        beq +
        jmp -
+       rts

.columnoffset   !byte 0

UpdateMapRow:                           ;IN: row offset in .A (0 = update for scrolling up, 3 = update for scrolling down)
        sta .rowoffset

        lda .newcamblockxpos            ;tile map is always drawn with topleft corner one block above and one block left of camera position
        dec
        and #31
        sta .blockxpos
        lda .newcamblockypos
        dec
        and #31
        sta .blockypos

        lda #$10
        sta VERA_ADDR_H                ;Auto increment one when writing to VERA RAM

        ;Loop through the 4 blocks in column
        ldx #0                          ;counter for the 4 blocks that will be drawn on tile map 
        ldy .blockxpos                  ;current column to copy to

        ;Calculate source address in block map
-       lda .blockypos                  ;add row offset
        clc
        adc .rowoffset                  ;add 0 or 3 to x offset depending on column to the left or 3 columns to the right should be updated
        and #31                         ;wrap around, tile map width is 32
        sta ZP0
        stz ZP1 
        +MultiplyBy32 ZP0

        tya                             ;add column offset
        clc
        adc ZP0
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1

        lda ZP0                         ;add base address of block map
        clc
        adc _blockmap_lo
        sta ZP0
        lda ZP1
        adc _blockmap_hi
        sta ZP1                         ;finally address of current block to copy is in ZP0 and ZP1

        ;Calculate destination address in tile map
        txa                             ;.X i simply counting which column to copy to (0-3)...
        clc
        adc .blockxpos                  ;but we must start copying to the right column. This depends on horizontal movement.
        sec
        sbc _xstartblock                ;start copy on block x pos - (x start block + 1)
        inc
        and #3                          ;wrap around, map is 4 blocks wide
        sta ZP2
        stz ZP3
        +MultiplyBy16 ZP2               ;multiply by 16 (each block column in tilemap is 16 bytes)

        lda .rowoffset                  ;now decide which row in tile map to copy to
        beq +
        lda .blockypos
        sec
        sbc _ystartblock
        bra ++
+       lda .blockypos
        sec
        sbc _ystartblock
        inc
++      and #3
        asl
        clc
        adc ZP3
        sta ZP3

        clc
        adc #>L0_MAP_ADDR
        sta ZP3                         ;finally destination address in tile map is in ZP2 and ZP3

        ;Copy block

        lda ZP2
        sta VERA_ADDR_L
        lda ZP3
        sta VERA_ADDR_M               ;set tile map destination address        
        lda (ZP0)                       ;read block index from block map
        phx
        phy
        jsr CopyMapBlock               
        ply
        plx

        iny                             ;increase block column
        tya
        and #31                         ;wrap around vertically (after column 31 comes column 0)
        tay
        inx
        cpx #4
        beq +
        jmp -
+       rts

.rowoffset      !byte 0
.blockxpos      !byte 0
.blockypos      !byte 0

CopyMapBlock:           ;IN: Block index in .A, Destination in VERA_ADDR_L and VERA_ADDR_M
        stz ZP4         ;use ZP4 and ZP5 for block index * 128
        lsr             ;interpret block index as the high byte, that means index * 256, shift right to get index * 128 which gives the address of the block
        sta ZP5         ;store high byte result
        ror ZP4         ;calculate low byte result

        lda #<_blocks   ;use ZP6 and ZP7 for base address of blocks
        clc             
        adc ZP4         ;add block offset to base address
        sta ZP6
        lda #>_blocks
        adc ZP5
        sta ZP7

        ldx #0
-       ldy #0
--      lda (ZP6),y        
        sta VERA_DATA0
        iny
        cpy #16         ;8 columns in a block, 2 bytes each
        bne --

        clc             ;add 16 bytes to source pointer (8 columns * 2 bytes = 16)
        lda ZP6
        adc #16
        sta ZP6
        lda ZP7
        adc #0
        sta ZP7

        clc             ;add 48 bytes to destination pointer (64 minus the 16 we just wrote) to jump to next row
        lda VERA_ADDR_L 
        adc #48         
        sta VERA_ADDR_L
        lda VERA_ADDR_M
        adc #0
        sta VERA_ADDR_M

        inx
        cpx #8          ;8 rows in a block
        bne -

        rts