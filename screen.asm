;*** screen.asm - handle graphic modes and sprites *************************************************

SetLayer0ToTileMode:
        jsr VPoke                       ;enable layer 0 in mode 3 (=tile mode with 4 bits per pixel)
        !word Ln0_CTRL0
        !byte %01100001            
 
        jsr VPoke                       ;map width and height = 32, tiles width and height = 16
        !word Ln0_CTRL1
        !byte %00110000

        jsr VPoke                       ;set base address of maps to $4000 ($4000/4=$1000)
        !word Ln0_MAP_BASE_L
        !byte $00
        jsr VPoke
        !word Ln0_MAP_BASE_H
        !byte >MAP_ADDR/4

        jsr VPoke                       ;set base address of tiles to $6000 ($6000/4=$1800)
        !word Ln0_TILE_BASE_L
        !byte $00
        jsr VPoke
        !word Ln0_TILE_BASE_H
        !byte >TILE_ADDR/4
        rts

SetLayer0ToTextMode:                    ;Layer 0 serves as a text mode background in shifting colors for start screen and menus
        jsr VPoke                       ;enable layer 0 in mode 0 (=text mode 1 bit per pixel)
        !word Ln0_CTRL0
        !byte %00000001            
 
        jsr VPoke                       ;128 cols and 64 rows
        !word Ln0_CTRL1
        !byte %00000110

        jsr VPoke                       ;set base address of maps to $4000 ($4000/4=$1000)
        !word Ln0_MAP_BASE_L
        !byte $00
        jsr VPoke
        !word Ln0_MAP_BASE_H
        !byte >MAP_ADDR/4

        jsr VPoke                       ;set base address of characters to$F800 ($F800/4=$3E00)
        !word Ln0_TILE_BASE_L
        !byte $00
        jsr VPoke
        !word Ln0_TILE_BASE_H
        !byte >CHAR_ADDR/4

        jsr VPoke                       ;set vertical scroll to -4, this is a necessary alignment because of text layout in layer 1
        !word Ln0_VSCROLL_L
        !byte $fc
        jsr VPoke
        !word Ln0_VSCROLL_H
        !byte $0f
        rts

ShowCars:
        jsr VPoke                       ;set palette offset to 1 (yellow car colors), when car explodes palette 0 is used
        !word SPR1_ATTR_1               
        !byte %10100001                 
        jsr VPoke                       ;set palette offset to 2 (blue car colors)
        !word SPR2_ATTR_1
        !byte %10100010                 

        jsr VPoke                       ;always enable sprite 1 (yellow car)
        !word SPR1_ATTR_0
        !byte COLLISION_MASK + 8 

        lda _noofplayers                ;disable blue car if only one player
        cmp #1
        bne +
        jsr VPoke                       ;one player - disable sprite 2 (blue car)
        !word SPR2_ATTR_0
        !byte 0                         
        rts

+       jsr VPoke                       ;two players - enable sprite 2 (blue car)
        !word SPR2_ATTR_0
        !byte COLLISION_MASK + 8
        rts

HideCars:
        jsr VPoke                       ;disable sprite 1 (yellow car)
        !word SPR1_ATTR_0
        !byte 0
        jsr VPoke                       ;disable sprite 2 (blue car)
        !word SPR2_ATTR_0
        !byte 0
        rts

ShowPenaltyText:                                ;.A = text color. 0 = yellow, 1 = blue
        clc
        adc #224 + 1                            ;add width and height specification
        +VPokeSprites SPR3_ATTR_1, 10           ;set color for all text sprites
        +VPokeSpritesI SPR3_ATTR_0, 7, 12       ;enable all letters in thew word "penalty" and place them in front of both layers

        +VPokeI SPR3_XPOS_L, 24                 ;distribute in a row in the middle of the screen
        +VPokeI SPR4_XPOS_L, 24 + 40
        +VPokeI SPR5_XPOS_L, 24 + 80
        +VPokeI SPR6_XPOS_L, 24 + 120
        +VPokeI SPR7_XPOS_L, 24 + 160
        +VPokeI SPR8_XPOS_L, 24 + 200
        +VPokeI SPR9_XPOS_L, 24 + 240 - 256        
        +VPokeSpritesI SPR3_XPOS_H, 6, 0
        +VPokeI SPR9_XPOS_H, 1           
        
        jsr TextDelay
        rts

ShowWinnerText:                                 ;.A = text color. 0 = yellow, 1 = blue
        clc
        adc #224 + 1                            ;add width and height specification
        +VPokeSprites SPR3_ATTR_1, 10           ;set color for all text sprites
        
        ;enable all letters in the word "winner" and place them in front of both layers
        +VPokeI  SPR4_ATTR_0, 12          ;enable "E"
        +VPokeI  SPR5_ATTR_0, 12          ;enable "N"
        +VPokeI SPR10_ATTR_0, 12          ;enable "W"
        +VPokeI SPR11_ATTR_0, 12          ;enable "R"
        +VPokeI SPR12_ATTR_0, 12          ;enable "I"

        +VPokeI SPR10_XPOS_L, 44                 ;distribute in a row in the middle of the screen
        +VPokeI SPR12_XPOS_L, 44 + 40
        +VPokeI  SPR5_XPOS_L, 44 + 80
        +VPokeI  SPR5_XPOS_L, 44 + 120
        +VPokeI  SPR4_XPOS_L, 44 + 160
        +VPokeI SPR11_XPOS_L, 44 + 200
        +VPokeSpritesI SPR3_XPOS_H, 10, 0

        jsr TextDelay        
        rts

TextDelay:
        inc .textdelay                          ;display text for a certain amount of ticks before changing game status
        lda .textdelay
        cmp #80
        beq +
        rts
+       jsr HideText
        lda #ST_SETUPRACE
        sta _gamestatus
        stz .textdelay
        rts

.textdelay      !byte 0

HideText:
        +VPokeSpritesI SPR3_ATTR_0, 10, 0        ;disable all text sprites
        rts




