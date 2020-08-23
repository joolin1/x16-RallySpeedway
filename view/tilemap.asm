;*** Map.asm - Operations on tilemap  **************************************************************
;The tilemap is of size 32x32. We are just interested in the topleftmost 21x16 tiles (= 336 x 256 pixels) that we buffer all information about for use in next frame. 

;*** local variables *******************************************************************************

;The camera is set  on the only car in when one player and exactly in the middle of the two cars when two players.
;World coordinates (12-bit integers 0-4095) can be interpreted like this: ----bbbbbtttpppp
;b = current block (0-31), t = current tile within block (0-7), p = current pixel within tile (0-15)

_camxpos_lo             !byte 0         ;camera position in world coordinates (0-4095)
_camxpos_hi             !byte 0
_camypos_lo             !byte 0         
_camypos_hi             !byte 0

.mapxpos_lo             !byte 0         ;map position in world coordinates (0-4095)
.mapxpos_hi             !byte 0
.mapypos_lo             !byte 0         ;map position in world coordinate (0-4095)
.mapypos_hi             !byte 0
.mapblockxpos           !byte 0         ;x block position (0-31)
.mapblockypos           !byte 0         ;y block position (0-31)
.maptilexpos            !byte 0         ;x tile position (0-7)
.maptileypos            !byte 0         ;y tile position (0-7)
.mappixelxpos           !byte 0         ;x pixel position (0-15) = how many pixels to scroll tile map horizontally
.mappixelypos           !byte 0         ;y pixel position (0-15) = how many pixels to scroll tile map vertically

.oldmaptilexpos         !byte 0         ;x tile position last frame, used to see if tile position has changed
.oldmaptileypos         !byte 0         ;y tile position last frame, used to see if tile position has changed

.displayedBuffer:       !byte 0         ;buffer (part of tilemap) that currently is displayed

.blockchangedflag       = ZP4           ;flag block change (when looping through map, the block will only change every 8th tile)
         
.currentxtile           = ZP7           ;current tile when looping through map      
.currentytile           = ZP8
.currentxblock          = ZP9           ;current block when looping through map
.currentyblock          = ZPA
.block_lo               = ZPB           ;address of current block in block map
.block_hi               = ZPC
.blockdef_lo            = ZPD           ;address of definition of current block
.blockdef_hi            = ZPE
.tileoffset             = ZPF           ;current tile offset in definition of current block

;*** Public subroutines ****************************************************************************

UpdateRaceView:                         ;this subroutine is called at vertical blank to update track, text and sprites. Track is already prepared, all we do is switch buffer.

        ;display the buffer (part of tilemap) that is not currently displayed
        lda .displayedBuffer         
        bne +
        lda #L0_MAP_ADDR>>9
        bra ++
+       lda #L0_MAP_ADDR_2>>9
++      sta L0_MAPBASE

        ;update scroll of tilemap
        lda .mappixelxpos
        sta L0_HSCROLL_L
        stz L0_HSCROLL_H

        lda .mappixelypos
        sta L0_VSCROLL_L
        stz L0_VSCROLL_H

        jsr YCar_UpdateSprite           ;update sprite position and selection for yellow car
        +SetPrintParams 28,1,$01        ;print racetime
        +SetParams _ycartime,_ycartime+1,_ycartime+2
        jsr VPrintTime

        lda _noofplayers
        cmp #1
        beq +
        jsr BCar_UpdateSprite           ;update sprite position and selection for blue car
        +SetPrintParams 28,31,$01       ;print racetime
        +SetParams _bcartime,_bcartime+1,_bcartime+2
        jsr VPrintTime
+       rts

InitMap:                                ;init is like update but we make sure all map calculations are made 
        jsr .SetCameraPosition
        jsr .SetMapPosition
        lda .maptilexpos
        sta .oldmaptilexpos
        lda .maptileypos
        sta .oldmaptileypos
        jsr .UpdateBuffer
        rts

UpdateMap:                              ;prepare the not displayed buffer with tilemap 
        jsr .SetCameraPosition          ;update camera position based on the position/s of the car/cars
        jsr .SetMapPosition             ;update which part of the map (track) that should be displayed
        lda .maptilexpos                ;has tile position changed?
        cmp .oldmaptilexpos
        bne +
        lda .maptileypos
        cmp .oldmaptileypos
        bne +
        bra ++                             
+       jsr .UpdateBuffer               ;only update new buffer (tilemap) with new tiles if postion has changed to a new tile
++      lda .maptilexpos
        sta .oldmaptilexpos
        lda .maptileypos
        sta .oldmaptileypos
        rts

;*** Private subroutines ***************************************************************************

.SetCameraPosition:     
        ;set camera position
        lda _noofplayers
        cmp #1
        beq .FocusOnYCar        ;if one player, simply set camera on yellow car
+       lda _winner             ;if two players, it is more complicated...
        cmp #1
        beq .FocusOnBCar        ;if yellow car has won the race, move camera to blue car
        cmp #2
        beq .FocusOnYCar        ;if blue car has won the race, move camera to yellow car
        
        lda _ycarxpos_lo        ;if race is on, set camera in the middle between the cars by adding coordinates and divide by two
        clc
        adc _bcarxpos_lo
        sta _camxpos_lo
        lda _ycarxpos_hi
        adc _bcarxpos_hi
        sta _camxpos_hi
        lsr _camxpos_hi                
        ror _camxpos_lo

        lda _ycarypos_lo
        clc
        adc _bcarypos_lo
        sta _camypos_lo
        lda _ycarypos_hi
        adc _bcarypos_hi
        sta _camypos_hi
        lsr _camypos_hi
        ror _camypos_lo
        rts

.FocusOnYCar:
        lda _ycarxpos_lo        ;if one player - simply set camera on yellow car
        sta _camxpos_lo
        lda _ycarxpos_hi
        sta _camxpos_hi
        lda _ycarypos_lo
        sta _camypos_lo
        lda _ycarypos_hi
        sta _camypos_hi
        rts

.FocusOnBCar:
        lda _bcarxpos_lo        ;if one player - simply set camera on yellow car
        sta _camxpos_lo
        lda _bcarxpos_hi
        sta _camxpos_hi
        lda _bcarypos_lo
        sta _camypos_lo
        lda _bcarypos_hi
        sta _camypos_hi
        rts

.SetMapPosition:             ;Update all position information (world coordinates, which block, whick tile in block and which pixel in tile)

        ;subtract half screen width an height from camera pos to get tilemap position for topleft corner of screen
        sec                             
        lda _camxpos_lo
        sbc #SCREEN_WIDTH/2
        sta .mapxpos_lo
        lda _camxpos_hi
        sbc #0
        sta .mapxpos_hi
        sec
        lda _camypos_lo
        sbc #SCREEN_HEIGHT/2
        sta .mapypos_lo
        lda _camypos_hi
        sbc #0
        sta .mapypos_hi

        ;get block positon
        lda .mapxpos_lo                            
        sta ZP0
        lda .mapxpos_hi
        sta ZP1
        lda ZP0
        asl
        lda ZP1
        rol                                  
        and #31                      
        sta .mapblockxpos 
        lda .mapypos_lo
        sta ZP0
        lda .mapypos_hi
        sta ZP1
        lda ZP0
        asl
        lda ZP1
        rol   
        and #31
        sta .mapblockypos  

        ;get tile position
        lda .mapxpos_lo
        lsr
        lsr
        lsr
        lsr
        and #7
        sta .maptilexpos
        lda .mapypos_lo
        lsr
        lsr
        lsr
        lsr
        and #7
        sta .maptileypos

        ;get pixel position
        lda .mapxpos_lo
        and #15
        sta .mappixelxpos
        lda .mapypos_lo
        and #15
        sta .mappixelypos
        rts

.UpdateBuffer:                          ;Update buffer (part of tilemap) that is currently not displayed
        
        lda .displayedBuffer            ;init tilemap pointer
        eor $ff
        sta .displayedBuffer
        bne +
        lda #<L0_MAP_ADDR               
        sta VERA_ADDR_L
        lda #>L0_MAP_ADDR
        sta VERA_ADDR_M
        bra ++
+       lda #<L0_MAP_ADDR_2
        sta VERA_ADDR_L
        lda #>L0_MAP_ADDR_2
        sta VERA_ADDR_M
++      lda #$10
        sta VERA_ADDR_H

        ;init row loop
        lda .maptileypos                ;init y tile position
        sta .currentytile
        lda .mapblockypos               ;init y block position
        sta .currentyblock
        ldy #16                         ;loop through 16 map rows
--      phy

        ;init column loop
        lda .maptilexpos                ;init x tile position
        sta .currentxtile
        lda .mapblockxpos               ;init x block position
        sta .currentxblock
        lda #1
        sta .blockchangedflag           ;flag that address of current block needs to be calculated
        ldx #21                         ;loop through 21 map columns

        ;get current tile
-       lda .blockchangedflag
        beq +
        jsr .GetBlockAndTile            ;block has changed, we need both new block and tile data
        stz .blockchangedflag
        bra ++
+       jsr .GetTile                    ;block remains the same, we only need to get new tile data

++      ldy .tileoffset                 ;write tile to the buffer that currently is not displayed
        lda (.blockdef_lo),y
        sta VERA_DATA0
        iny
        lda (.blockdef_lo),y
        sta VERA_DATA0

        ;next column      
        inc .currentxtile               ;increase tile position and wrap around
        lda .currentxtile
        cmp #8
        bne +
        stz .currentxtile
        inc .currentxblock              ;increase block position and wrap around
        lda .currentxblock      
        and #31
        sta .currentxblock
        lda #1
        sta .blockchangedflag           ;new block -> new block address to calculate
+       dex
        bne -                   

        ;next row
        clc                             ;add (32-21)*2 = 22 bytes to VERA pointers to get address for next row in tilemap
        lda #22
        adc VERA_ADDR_L
        sta VERA_ADDR_L
        lda VERA_ADDR_M
        adc #0
        sta VERA_ADDR_M

        inc .currentytile               ;increase tile position and wrap around
        lda .currentytile
        cmp #8
        bne +
        stz .currentytile

        inc .currentyblock              ;increase block position and wrap around
        lda .currentyblock      
        and #31
        sta .currentyblock
        lda #1
        sta .blockchangedflag           ;new block -> new block address to calculate
+       ply
        dey
        bne --                  
        rts

.GetBlockAndTile:                       ;FULL version that first get current block and then current tile.

        ;get address of current block
        lda .currentyblock              ;start with row offset in blockmap
        sta .block_lo
        stz .block_hi
        +MultiplyBy32 .block_lo         ;(32 blocks in each row)

        lda .currentxblock              ;add col offset
        clc
        adc .block_lo
        sta .block_lo
        lda .block_hi
        adc #0
        sta .block_hi
        
        lda _blockmap_lo                ;add base address of blockmap
        clc
        adc .block_lo                 
        sta .block_lo
        lda _blockmap_hi
        adc .block_hi                 
        sta .block_hi

        ;get current block
        lda (.block_lo)                 ;read current block from block map
        lsr
        sta .blockdef_hi
        stz .blockdef_lo
        ror .blockdef_lo                ;multiply by 128 to get offset in block definitions

        lda #<_blocks                   ;add base address of block definitions
        clc
        adc .blockdef_lo                 
        sta .blockdef_lo
        lda #>_blocks
        adc .blockdef_hi                 
        sta .blockdef_hi                ;(continue with .GetTile)

.GetTile:                               ;SHORT version that only get current tile for cases when block hasn't changed.
        ;get address of current tile
        lda .currentytile               ;start with row offset in block definition
        asl
        asl
        asl
        asl                             ;multiply by 16 because every row consists of 8 tiles of 2 bytes each
        sta .tileoffset

        lda .currentxtile               ;add col offset
        asl                             ;multiply by 2 because each tile takes 2 bytes
        clc
        adc .tileoffset
        sta .tileoffset
        rts