;*** Set up screen and sprites ************************************************************************

SCREEN_WIDTH = 320
SCREEN_HEIGHT = 240

EnableLayers:
        jsr EnableLayer0
        jsr EnableLayer1
        rts

DisableLayers:
        jsr DisableLayer0
        jsr DisableLayer1
        rts

EnableLayer0:
        lda DC_VIDEO
        ora #16
        sta DC_VIDEO
        rts

EnableLayer1:
        lda DC_VIDEO
        ora #32
        sta DC_VIDEO
        rts

DisableLayer0:
        lda DC_VIDEO
        and #255-16
        sta DC_VIDEO
        rts

DisableLayer1:
        lda DC_VIDEO
        and #255-32
        sta DC_VIDEO
        rts

InitScreenAndSprites:
        jsr DisableLayers       ;Disable layers while setting up start screen

        stz VERA_CTRL           ;R-----DA (R=RESET, D=DCSEL, A=ADDRSEL)

        ;Display (DCSEL=0)
        lda DC_VIDEO
        ora #64
        sta DC_VIDEO            ;enable sprites
        lda #64
        sta DC_HSCALE           ;set horizontal and vertical scale to 2:1
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

        ldx #15                 ;number of sprites
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

        lda ZP2                 
        clc
        adc #8                  ;add 8 to get address attribute of next sprite
        sta ZP2

        ;Add an extra "O"-sprite due to the fact that "OFFROAD" is spelled with two O:s
        lda #<TEXT_ADDR      
        sta ZP0
        lda #>TEXT_ADDR
        sta ZP1
        +DivideBy32 ZP0
        inc ZP1                 ;add 32 * 8 (= index for sprite) = 256 to get address of "O" sprite, in other words add 1 to high byte
        jsr .VPokeSpriteAddr

        lda ZP2                 
        clc
        adc #8                  ;add 8 to get address attribute of next sprite
        sta ZP2

        ;Add an extra "F"-sprite due to the fact that "OFFROAD" is spelled with two F:s
        lda #<TEXT_ADDR      
        sta ZP0
        lda #>TEXT_ADDR
        sta ZP1
        +DivideBy32 ZP0
        lda ZP0                         
        clc
        adc #96                ;add 32 * 3 (= index for sprite) = 224 to get address of "N" sprite
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1
        jsr .VPokeSpriteAddr

        +VPokeSpritesI SPR3_ATTR_0, TEXTSPRITE_COUNT, 0         ;disable all text sprites for now
        +VPokeSpritesI SPR3_ATTR_1, TEXTSPRITE_COUNT, %11100000 ;set height to 64 pixels and width to 32
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

SetLayer0ToTileMode:
        lda #2                          ;set map size to 32x32, color depth 4bpp
        sta L0_CONFIG 
        lda #L0_MAP_ADDR>>9             ;set map base address
        sta L0_MAPBASE
        lda #TILE_ADDR>>9               ;set tile address and tile size to 16x16
        ora #%00000011
        sta L0_TILEBASE
        rts

SetLayer0ToTextMode:                    ;Layer 0 serves as a text mode background in shifting colors for start screen and menus
        lda #%00100000                  ;set map size to 128x32 (128 columns = 256 bytes/row which is practical, 32 rows because screen holds 30 rows at 320x200), color depth 1bpp    
        sta L0_CONFIG
        lda #L0_MAP_ADDR>>9             ;set map base address
        sta L0_MAPBASE
        lda #CHAR_ADDR>>9               ;set tile (char) address and tile (char) size to 8x8
        and #%11111100
        sta L0_TILEBASE
        lda #$fc                        ;set vertical scroll to -4, this is a necessary alignment because of text layout in layer 1
        sta L0_VSCROLL_L
        lda #$0f
        sta L0_VSCROLL_H
        stz L0_HSCROLL_L
        stz L0_HSCROLL_H
        rts

ClearTextLayer:				;IN: .X, .Y = address of layer
	stx VERA_ADDR_L
	tya
	clc
	adc #30
	sta VERA_ADDR_M
	lda #$10			;increment 1
	sta VERA_ADDR_H
	lda #S_SPACE
	ldy #$01			;bg = black (transparent), fg = white
--	ldx #40
-	sta VERA_DATA0			;print space						
	sty VERA_DATA0			;set color
	dex
	bne -
	stz VERA_ADDR_L
	dec VERA_ADDR_M
	bpl --
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