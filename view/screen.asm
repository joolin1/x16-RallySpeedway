;*** Set up screen and sprites ************************************************************************

SCREEN_WIDTH = 320
SCREEN_HEIGHT = 240

!macro CopyPalettesToVRAM .source,.deststart, .count {      ;IN .deststart = first palette index to copy to, .count = number of palettes (max 7!)
        lda #<PALETTE+.deststart*32
        sta VERA_ADDR_L
        lda #>PALETTE+.deststart*32           
        sta VERA_ADDR_M
        lda #$11                
        sta VERA_ADDR_H                 ;increment = 1

        ldy #0           
-       lda .source,y        ;loop through number of palettes * 16 colors * 2 bytes
        sta VERA_DATA0     
        iny
        cpy #.count*32             
        bne -
}

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

        lda L1_MAPBASE
        sta .original_l1_mapbase
        lda #0                  ;WARNING hard coded address, should be L1_MAP_ADDR>>9
        sta L1_MAPBASE          ;relocate text layer

        lda #0                  ;init char set
        ldx #<_charset
        ldy #>_charset
        jsr screen_set_charset

        +CopyPalettesToVRAM .palettes, 0, 6
        +CopyPalettesToVRAM .trafficpalettes, 6, 4

        ;init badge sprites
        jsr InitBadgeSprites

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

        +VPokeSpritesI SPR3_ATTR_0, TEXTSPRITE_COUNT, 0                                      ;disable all text sprites for now
        +VPokeSpritesI SPR3_ATTR_1, TEXTSPRITE_COUNT, %11100000 + SPRITETEXTPALETTEINDEX     ;set height = 64, width 32 and palette index 
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
        lda #TILES_ADDR>>9               ;set tile address and tile size to 16x16
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

SetLayer0ToBitmapMode:
        lda #%00000110                  ;Bitmap mode, 4 bpp = 16 colors
        sta L0_CONFIG
        lda #IMAGE_ADDR>>9              ;set bitmap address and width 320 pixels
        and #%11111100
        sta L0_TILEBASE 
        lda #5                          ;set palette index                
        sta L0_HSCROLL_H
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

        +CopyPalettesToVRAM .originalpalette, 0, 1

        lda #%01100000
        sta L1_CONFIG           ;enable layer 1 in 16 color text mode 

        lda .original_l1_mapbase ;set map base of text layer to original location
        sta L1_MAPBASE

        lda #$8e       
        jsr BSOUT               ;trigger kernal to upload original character set from ROM to VRAM

-       jsr GETIN
        cmp #0
        bne -

        lda #147
        jsr BSOUT               ;clear screen

        rts

.original_l1_mapbase    !byte 0

.palettes                                       
        !word $0000, $0fff, $0800, $0afe, $0c4c, $0080, $046f, $0fd2, $0d85, $0640, $0f77, $0000, $0777, $0af6, $008f, $0bbb    ;user interface (C64 palette but blue and yellow adjusted and 11 = black instead of dark grey)
.carspritepalettes
        !word $0000, $0FA0, $0000, $0333, $0FD2, $0666, $000a, $0ee7, $0d85, $0640, $0f77, $0333, $0777, $0af6, $008f, $0bbb    ;yellow car
        !word $0000, $046F, $0000, $0333, $06AF, $0666, $000a, $0ee7, $0d85, $0640, $0f77, $0333, $0777, $0af6, $008f, $0bbb    ;blue car
.spritetextpalette
        !word $0000, $0000, $0666, $0afe, $0c4c, $00c5, $000a, $0ee7, $0d85, $0640, $0f77, $0333, $0777, $0af6, $008f, $0bbb    ;sprite text (C64 palette but 1 = black, 2 = grey)
.trackpalette
        !word $000f, $0BBB, $0FFF, $0A33, $05A0, $0AF0, $0555, $0470, $0DF8, $0FE0, $0931, $0744, $0358, $038D, $0453, $029E    ;tiles
.titleimagepalette
        !word $0011, $0000, $0122, $0333, $0555, $0677, $0889, $0BBA, $0BB9, $0DCC, $0FFF, $0762, $0B93, $0FE7, $0FD4, $0431
.trafficpalettes
        !word $0000, $0b13, $0e46, $0555, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000    ;red
        !word $0000, $0d85, $0e92, $0555, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000    ;yellow
        !word $0000, $046f, $06af, $0555, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000    ;blue
.explosionpalette
        !word $0000, $0B13, $0E50, $0FA0, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
.originalpalette
        !word $0000, $0fff, $0800, $0afe, $0c4c, $00c5, $000a, $0ee7, $0d85, $0640, $0f77, $0333, $0777, $0af6, $008f, $0bbb    ;original colors, used for restoring colors when quitting game

;colors used for sprite texts
SPRITETEXT_GREY    = $0666
SPRITETEXT_YELLOW  = $0FD2
SPRITETEXT_BLUE    = $046F
SPRITETEXT_BLACK   = $0000

SPRITETEXT_FG = SPRITETEXT_PALETTE + 4  ;color 2 is main color of text sprites
SPRITETEXT_BG = SPRITETEXT_PALETTE + 2  ;color 1 is shadow of text sprites

SPRITETEXTPALETTEINDEX = 3