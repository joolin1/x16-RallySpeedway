;*** Init screen and sprites ************************************************************************

InitScreenAndSprites:

        stz VERA_CTRL

        ;Display
        jsr VPoke                       ;set horizontal scale to 2:1
        !word DC_HSCALE
        !byte 64
        jsr VPoke                       ;set vertical scale to 2:1
        !word DC_VSCALE
        !byte 64

        jsr VPoke                       ;enable sprites globally           
        !word SPR_CTRL
        !byte 1

        ;Init text sprites
        lda #<TEXT_ADDR 
        sta ZP0
        lda #>TEXT_ADDR
        sta ZP1
        +DivideBy32 ZP0                 ;address of first sprite in ZP0 and ZP1

        lda #<SPR3_ADDR_L               ;low byte of address attribute for first text sprite
        sta ZP2

        ldx #10                         ;number of sprites
-       jsr .VPokeSpriteAddr
        lda ZP0                         ;add 1024/32=32 to get address of next sprite
        clc
        adc #32
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1
        lda ZP2                         ;add 8 to get address attribute of next sprite
        clc
        adc #8
        sta ZP2
        dex
        bne -

        ;Add an extra "N"-sprite due to the fact that "WINNER" i spelled with two n:s
        lda #<TEXT_ADDR      
        sta ZP0
        lda #>TEXT_ADDR
        sta ZP1
        +DivideBy32 ZP0
        lda ZP0                         ;add 64 to get address of "N" sprite
        clc
        adc #64
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1
        jsr .VPokeSpriteAddr

        +VPokeSpritesI SPR3_YPOS_L, 11, 98
        +VPokeSpritesI SPR3_YPOS_H, 11, 0

        +VPokeSpritesI SPR3_ATTR_0, 11, 0         ;disable all text sprites for now
        +VPokeSpritesI SPR3_ATTR_1, 11, %11100000 ;set height to 64 pixels and width to 32
        rts

.VPokeSpriteAddr:                ;set address attributes for sprites
        lda ZP2                 ;which sprite attribute address is in ZP2
        sta VERA_ADDR_LO
        lda #$50
        sta VERA_ADDR_MID
        lda #$1f
        sta VERA_ADDR_HI
        lda ZP0                 ;address of sprite is in ZP0 and ZP1
        sta VERA_DATA0
        lda ZP1
        sta VERA_DATA0
        rts

RestoreScreenAndSprites:        ;Restore screen and sprites when user ends game
        jsr VPoke               ;set horizontal scale to 1:1
        !word DC_HSCALE
        !byte 128

        jsr VPoke               ;set vertical scale to 1:1
        !word DC_VSCALE
        !byte 128

        jsr VPoke               ;disable layer 0
        !word Ln0_CTRL0
        !byte 0

        jsr VPoke               ;enable layer 1 mode 0
        !word Ln1_CTRL0
        !byte 1                 

        jsr VPoke               ;disable sprites globally
        !word SPR_CTRL
        !byte 0

        lda #$8e       
        jsr BSOUT               ;trigger kernal to upload original character set from ROM to VRAM

        lda #147
        jsr BSOUT               ;clear screen

        rts