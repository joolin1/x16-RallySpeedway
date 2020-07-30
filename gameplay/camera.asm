;*** camera.asm ************************************************************************************

;The camera is set on the only car in one player mode and between the two cars in two player mode.
;Camera position is directly corresponding to how much the track (map) is scrolled/moved both horizontally and vertically.
;Therefore movement of the camera causes the need of updating the hardware tile map with new blocks. This is also done here. 

InitCamera:
        ;set initial cam BLOCK position (0-31)
        lda _xstartblock
        sta .camblockxpos
        sta .newcamblockxpos
        lda _ystartblock
        sta .camblockypos
        sta .newcamblockypos

        ;set initial cam position (0-4095)
        stz .camxpos_lo
        lda _xstartblock
        sta .camxpos_hi
        lsr .camxpos_hi                 ;start block in high byte divided by 2 = 128 * block.        
        ror .camxpos_lo
        lda .camxpos_lo
        clc 
        adc #64                         ;add 64 (a half block) to center cam
        sta .camxpos_lo
        lda .camxpos_hi
        adc #0
        sta .camxpos_hi

        stz .camypos_lo
        lda _ystartblock
        sta .camypos_hi
        lsr .camypos_hi
        ror .camypos_lo
        lda .camypos_lo
        clc
        adc #64                         ;add 64 (a half block) to center cam
        sta .camypos_lo
        lda .camypos_hi
        adc #0
        sta .camypos_hi
        rts

UpdateCamera:     

        ;Set camera position
        lda _noofplayers
        cmp #1
        bne +
        lda _ycarxpos_lo                ;if one player - simply set camera on yellow car
        sta .camxpos_lo
        lda _ycarxpos_hi
        sta .camxpos_hi
        lda _ycarypos_lo
        sta .camypos_lo
        lda _ycarypos_hi
        sta .camypos_hi
        bra ++

+       lda _ycarxpos_lo                ;if two players - set camera in the middle between the cars by adding coordinates and divide by two
        clc
        adc _bcarxpos_lo
        sta .camxpos_lo
        lda _ycarxpos_hi
        adc _bcarxpos_hi
        sta .camxpos_hi
        lsr .camxpos_hi                
        ror .camxpos_lo

        lda _ycarypos_lo
        clc
        adc _bcarypos_lo
        sta .camypos_lo
        lda _ycarypos_hi
        adc _bcarypos_hi
        sta .camypos_hi
        lsr .camypos_hi
        ror .camypos_lo

        ;Update map window if necessary (block map is 32x32 blocks = 4096x4096 pixels, but hardware map is just 512x512 pixels)
++      lda .camxpos_lo                 
        sec
        sbc #64                         ;subtract 64 (a half block) from camera x position to adjust when updating of tile map is triggered
        sta ZP0
        lda .camxpos_hi
        sbc #0
        sta ZP1
        lda ZP0                         ;convert cam x position (0-4095) to block x position (0-31)
        asl
        lda ZP1
        rol                                  
        and #31                      
        sta .newcamblockxpos
 
        lda .camypos_lo
        sec
        sbc #64                         ;subtract 64 (a half block) from camera y position to adjust when updating of tile map is triggered
        sta ZP0
        lda .camypos_hi
        sbc #0
        sta ZP1
        lda ZP0
        asl
        lda ZP1
        rol                             ;convert cam y position (0-4095) to block y position (0-31)     
        and #31
        sta .newcamblockypos         

        ;check if leftmost or rightmost column needs to be updated
        lda .camblockxpos
        cmp .newcamblockxpos
        beq ++                          ;nothing has changed - no column updating
        inc                             ;increase old position for testing
        and #31                         ;wrap around
        cmp .newcamblockxpos               
        bne +                           ;not same means camera is moving to the left
        lda #3
        jsr UpdateMapColumn
        bra ++
+       lda #0
        jsr UpdateMapColumn

        ;check if top or bottom column needs to be updated
++      lda .camblockypos
        cmp .newcamblockypos
        beq ++
        inc                             ;increase old position for testing
        and #31                         ;wrap around
        cmp .newcamblockypos
        bne +                           ;not same means camera is moving upwards
        lda #3
        jsr UpdateMapRow
        bra ++
+       lda #0
        jsr UpdateMapRow

++      lda .newcamblockxpos               ;save new position as current positon
        sta .camblockxpos
        lda .newcamblockypos
        sta .camblockypos
        rts

;camera position
.camxpos_lo             !byte 0         ;an integer value locating camera horizontally on block map that is 4096 pixels wide (bits 12-15 are ignored)
.camxpos_hi             !byte 0
.camypos_lo             !byte 0         ;an integer value locating camera vertickally on block map that is 4096 pixels wide (bits 12-15 are ignored)
.camypos_hi             !byte 0
.camblockxpos           !byte 0         ;which horizontal block (0-31) cam is set on (0-31)
.camblockypos           !byte 0         ;which vertical block (0-31) cam is set on (0-31)
.newcamblockxpos        !byte 0         ;where cam is set next frame
.newcamblockypos        !byte 0         ;where cam is set next frame