;*** screen.asm - handle graphic modes and sprites *************************************************

COLLISION_MASK = %00010000

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
        +VPokeSprites SPR3_ATTR_1, 11           ;set color for all text sprites
        
        ;enable all letters in the word "winner" and place them in front of both layers
        +VPokeI  SPR4_ATTR_0, 12                ;enable "E"
        +VPokeI  SPR5_ATTR_0, 12                ;enable "N"
        +VPokeI SPR10_ATTR_0, 12                ;enable "W"
        +VPokeI SPR11_ATTR_0, 12                ;enable "R"
        +VPokeI SPR12_ATTR_0, 12                ;enable "I"
        +VPokeI SPR13_ATTR_0, 12                ;enable the second "N"

        +VPokeI SPR10_XPOS_L, 52                ;distribute in a row in the middle of the screen
        +VPokeI SPR11_XPOS_L, 52 + 32
        +VPokeI  SPR5_XPOS_L, 52 + 64
        +VPokeI SPR13_XPOS_L, 52 + 104
        +VPokeI  SPR4_XPOS_L, 52 + 144
        +VPokeI SPR12_XPOS_L, 52 + 184
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
        +VPokeSpritesI SPR3_ATTR_0, 11, 0       ;disable all text sprites
        rts




