;*** View.asm *****************************************************************

scrollxoffs_lo  = $10
scrollxoffs_hi  = $11
scrollyoffs_lo  = $12
scrollyoffs_hi  = $13

InitView:
        ;Set start scroll offset for tilemap. If start position is on block 5, tile map will initially be drawn from block 4.
        ;Cam will have an inital position of 5x128+160 (160=half screen) and this is where the scrolling of the tile map starts.
        ;scrollxoffs and scrollyoffs is what we subtract from the cam coordinates to calculate how much the tile map window should be scrolled. 

        stz scrollxoffs_lo 
        stz scrollxoffs_hi
        ldx _xstartblock
        dex
-       lda #128                ;start with 128 x (start position-1)
        clc
        adc scrollxoffs_lo
        sta scrollxoffs_lo
        lda scrollxoffs_hi
        adc #0
        sta scrollxoffs_hi
        dex
        bne -
        lda scrollxoffs_lo
        clc
        adc #160                ;add screen width/2
        sta scrollxoffs_lo
        lda scrollxoffs_hi
        adc #0
        sta scrollxoffs_hi

        stz scrollyoffs_lo 
        stz scrollyoffs_hi
        ldx _ystartblock
        dex
-       lda #128                ;start with 128 x (start position-1)
        clc
        adc scrollyoffs_lo
        sta scrollyoffs_lo
        lda scrollyoffs_hi
        adc #0
        sta scrollyoffs_hi
        dex
        bne -
        lda scrollyoffs_lo
        clc
        adc #120                ;add screen height/2
        sta scrollyoffs_lo
        lda scrollyoffs_hi
        adc #0
        sta scrollyoffs_hi   
        rts

UpdateView:
        ;First thing to do when interrupt is triggered is always to update the view, then the rest of the time before next interrupt is used to calculate new data.
        
        ;set x and y scroll of tile map from cam position
        lda .camxpos_lo
        sec
        sbc scrollxoffs_lo
        sta L0_HSCROLL_L
        lda .camxpos_hi
        sbc scrollxoffs_hi
        sta L0_HSCROLL_H

        lda .camypos_lo
        sec
        sbc scrollyoffs_lo        
        sta L0_VSCROLL_L
        lda .camypos_hi
        sbc scrollyoffs_hi
        sta L0_VSCROLL_H

        ;Set position and select sprite for yellow car
        lda _ycarxpos_lo                ;sprite x pos = 160-16 + (car pos-cam pos)
        sec
        sbc .camxpos_lo
        sta ZP0
        lda _ycarxpos_hi
        sbc .camxpos_hi
        sta ZP1
        lda #160-16                     ;160 is middle of screen, 16 is half sprite width
        clc
        adc ZP0
        sta ZP0
        lda #0
        adc ZP1
        sta ZP1

        lda _ycarypos_lo                ;sprite x pos = 120-16 + (car pos-cam pos)
        sec
        sbc .camypos_lo
        sta ZP2
        lda _ycarypos_hi
        sbc .camypos_hi
        sta ZP3
        lda #120-16                     ;120 is middle of screen, 16 is half sprite width
        clc
        adc ZP2
        sta ZP2
        lda #0
        adc ZP3
        sta ZP3

        +VPoke SPR1_XPOS_L, ZP0
        +VPoke SPR1_XPOS_H, ZP1
        +VPoke SPR1_YPOS_L, ZP2
        +VPoke SPR1_YPOS_H, ZP3

        jsr YCar_UpdateSprite
        lda #$01                        ;bg color = transparent, fg = white
        ldx #1                          ;column
        ldy #28                         ;row
        jsr YCar_DisplayTime

        ;Set position and select sprite for blue car
        lda _noofplayers
        cmp #1
        bne +
        rts

+       lda _bcarxpos_lo                ;sprite x pos = 160-16 + (car pos-cam pos)
        sec
        sbc .camxpos_lo
        sta ZP0
        lda _bcarxpos_hi
        sbc .camxpos_hi
        sta ZP1
        lda #160-16                     ;160 is middle of screen, 16 is half sprite width
        clc
        adc ZP0
        sta ZP0
        lda #0
        adc ZP1
        sta ZP1

        lda _bcarypos_lo                ;sprite x pos = 120-16 + (car pos-cam pos)
        sec
        sbc .camypos_lo
        sta ZP2
        lda _bcarypos_hi
        sbc .camypos_hi
        sta ZP3
        lda #120-16                     ;120 is middle of screen, 16 is half sprite width
        clc
        adc ZP2
        sta ZP2
        lda #0
        adc ZP3
        sta ZP3

        +VPoke SPR2_XPOS_L, ZP0
        +VPoke SPR2_XPOS_H, ZP1
        +VPoke SPR2_YPOS_L, ZP2
        +VPoke SPR2_YPOS_H, ZP3
        
        jsr BCar_UpdateSprite
        lda #$01        ;bg color = transparent, fg color = white
        ldx #31         ;column
        ldy #28         ;row
        jsr BCar_DisplayTime     
        rts

