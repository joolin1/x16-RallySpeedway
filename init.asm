;*** Init screen and sprites ************************************************************************

InitScreenAndSprites:

        stz VERA_CTRL           ;R-----DA (R=RESET, D=DCSEL, A=ADDRSEL)

        ;Display (DCSEL=0)
        lda DC_VIDEO
        ora #%01110000
        sta DC_VIDEO            ;enable sprites, layer 1 and layer 0
        lda #64
        sta DC_HSCALE           ;set horizontal scale to 2:1
        sta DC_VSCALE

        lda #0
       	+VPoke PALETTE+22	;change dark grey to black in first palette, otherwise we cannot show black because orginal black is transparent
	+VPoke PALETTE+23

        ;Init text sprites
        lda #<TEXT_ADDR 
        sta ZP0
        lda #>TEXT_ADDR
        sta ZP1
        +DivideBy32 ZP0         ;address of first sprite in ZP0 and ZP1

        lda #<SPR3_ADDR_L       ;low byte of address attribute for first text sprite
        sta ZP2

        ldx #14                 ;number of sprites
-       jsr .VPokeSpriteAddr
        lda ZP0                 ;add 1024/32=32 to get address of next sprite
        clc
        adc #32
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1
        lda ZP2                 ;add 8 to get address attribute of next sprite
        clc
        adc #8
        sta ZP2
        dex
        bne -

        ;Add an extra "I"-sprite due to the fact that "FINISHED" is spelled with two n:s
        lda #<TEXT_ADDR      
        sta ZP0
        lda #>TEXT_ADDR
        sta ZP1
        +DivideBy32 ZP0
        lda ZP0                 
        clc
        adc #160                ;add 32 * 5 (= index for sprite) = 160 to get address of "I" sprite
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1
        jsr .VPokeSpriteAddr

        lda ZP2                 
        clc
        adc #8                  ;add 8 to get address attribute of next sprite
        sta ZP2

        ;Add an extra "N"-sprite due to the fact that "WINNER" is spelled with two n:s
        lda #<TEXT_ADDR      
        sta ZP0
        lda #>TEXT_ADDR
        sta ZP1
        +DivideBy32 ZP0
        lda ZP0                         
        clc
        adc #224                ;add 32 * 7 (= index for sprite) = 224 to get address of "N" sprite
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1
        jsr .VPokeSpriteAddr

        +VPokeSpritesI SPR3_ATTR_0, 16, 0         ;disable all text sprites for now
        +VPokeSpritesI SPR3_ATTR_1, 16, %11100000 ;set height to 64 pixels and width to 32
        rts

.VPokeSpriteAddr:               ;set address attributes for sprites
        lda ZP2                 ;which sprite attribute address is in ZP2
        sta VERA_ADDR_L
        lda #>SPR_ADDR
        sta VERA_ADDR_M
        lda #$11
        sta VERA_ADDR_H
        lda ZP0                 ;address of sprite is in ZP0 and ZP1
        sta VERA_DATA0
        lda ZP1
        sta VERA_DATA0
        rts

RestoreScreenAndSprites:        ;Restore screen and sprites when user ends game
        
        stz VERA_CTRL           ;R-----DA (R=RESET, D=DCSEL, A=ADDRSEL)

        ;Display (DCSEL=0)
        lda DC_VIDEO
        and #%10101111          
        sta DC_VIDEO            ;disable sprites and layer 0
        
        lda #128
        sta DC_HSCALE           ;set horizontal scale to 1:1
        sta DC_VSCALE           ;set vertical scale to 1:1

       	lda #$33
	+VPoke PALETTE+22	;restore black to dark grey
	lda #$03
	+VPoke PALETTE+23

        lda #%01100000
        sta L1_CONFIG           ;enable layer 1 in 16 color text mode 

        lda #$8e       
        jsr BSOUT               ;trigger kernal to upload original character set from ROM to VRAM

        lda #147
        jsr BSOUT               ;clear screen

        rts