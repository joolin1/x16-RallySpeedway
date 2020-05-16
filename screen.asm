;*** screen.asm - handle graphic modes and sprites *************************************************

PENALTY_TEXT_POSITION = 98
FINISH_TEXT_POSITION = 44

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

ShowPenaltyText:                                ;.A = text color. 0 = yellow, 1 = blue
        clc
        adc #224 + 1                            ;add width and height specification
        +VPokeSprites SPR3_ATTR_1, 16           ;set color for all text sprites

        ;enable all letters in thew word "penalty" and place them in front of both layers
        +VPokeI SPR11_ATTR_0, 12
        +VPokeI  SPR5_ATTR_0, 12
        +VPokeI SPR10_ATTR_0, 12
        +VPokeI  SPR3_ATTR_0, 12
        +VPokeI  SPR9_ATTR_0, 12
        +VPokeI SPR14_ATTR_0, 12
        +VPokeI SPR16_ATTR_0, 12  

        ;distribute in a row in the middle of the screen       
        +VPokeI SPR11_XPOS_L, 24                 
        +VPokeI  SPR5_XPOS_L, 24 + 40
        +VPokeI SPR10_XPOS_L, 24 + 80
        +VPokeI  SPR3_XPOS_L, 24 + 120
        +VPokeI  SPR9_XPOS_L, 24 + 160
        +VPokeI SPR14_XPOS_L, 24 + 200
        +VPokeI SPR16_XPOS_L, 24 + 240 - 256        

        +VPokeSpritesI SPR3_XPOS_H, 16, 0
        +VPokeI SPR16_XPOS_H, 1

        +VPokeSpritesI SPR3_YPOS_L, 16, PENALTY_TEXT_POSITION
        +VPokeSpritesI SPR3_YPOS_H, 16, 0

        lda #140
        sta .textdelay                
        rts

TextDelay:
        dec .textdelay          ;display text for a certain amount of ticks before changing game status. OUT: .A = jiffies left (0 = delay finished)
        lda .textdelay
        beq +
        rts
+       jsr HideText
        lda #0
        rts

.textdelay      !byte 0

ShowRaceOverText:                               ;.A = text color. 0 = yellow, 1 = blue (ignored if one player)
        ldx _noofplayers
        cpx #1
        bne +
        jsr .ShowFinishedText
        rts
+       jsr .ShowWinnerText
        rts

.ShowFinishedText:                              ;show "FINISHED" text in yellow when one player
        lda #224 + 1
        +VPokeSprites SPR3_ATTR_1, 16           ;set yellow color for all text sprites
        
        +VPokeI  SPR6_ATTR_0, 12                ;enable "F"
        +VPokeI  SPR8_ATTR_0, 12                ;enable "I"
        +VPokeI SPR10_ATTR_0, 12                ;enable "N"
        +VPokeI SPR17_ATTR_0, 12                ;enable "I" (second instance)
        +VPokeI SPR13_ATTR_0, 12                ;enable "S"
        +VPokeI  SPR7_ATTR_0, 12                ;enable "H"
        +VPokeI  SPR5_ATTR_0, 12                ;enable "E"
        +VPokeI  SPR4_ATTR_0, 12                ;enable "D"

        +VPokeI  SPR6_XPOS_L, 20                ;distribute in a row in the middle of the screen
        +VPokeI  SPR8_XPOS_L, 20 + 32
        +VPokeI SPR10_XPOS_L, 20 + 64
        +VPokeI SPR17_XPOS_L, 20 + 96
        +VPokeI SPR13_XPOS_L, 20 + 128
        +VPokeI  SPR7_XPOS_L, 20 + 168
        +VPokeI  SPR5_XPOS_L, 20 + 208
        +VPokeI  SPR4_XPOS_L, 20 + 248 - 256

        +VPokeSpritesI SPR3_XPOS_H, 16, 0
        +VPokeI SPR4_XPOS_H, 1  
        
        +VPokeSpritesI SPR3_YPOS_L, 16, FINISH_TEXT_POSITION 
        +VPokeSpritesI SPR3_YPOS_H, 16, 0          
        rts

.ShowWinnerText:                                ;show "WINNER" text in yellow or blue color depending on winner
        clc
        adc #224 + 1                            ;add width and height specification
        +VPokeSprites SPR3_ATTR_1, 16           ;set color for all text sprites depending on winner
        
        ;enable all letters in the word "winner" and place them in front of both layers
        +VPokeI SPR15_ATTR_0, 12                ;enable "W"
        +VPokeI  SPR8_ATTR_0, 12                ;enable "I"
        +VPokeI SPR10_ATTR_0, 12                ;enable "N"
        +VPokeI SPR18_ATTR_0, 12                ;enable "N" (second instance)
        +VPokeI  SPR5_ATTR_0, 12                ;enable "E"
        +VPokeI SPR12_ATTR_0, 12                ;enable "R"

        +VPokeI SPR15_XPOS_L, 52                ;distribute in a row in the middle of the screen
        +VPokeI  SPR8_XPOS_L, 52 + 32
        +VPokeI SPR10_XPOS_L, 52 + 64
        +VPokeI SPR18_XPOS_L, 52 + 104
        +VPokeI  SPR5_XPOS_L, 52 + 144
        +VPokeI SPR12_XPOS_L, 52 + 184
        +VPokeSpritesI SPR3_XPOS_H, 16, 0 

        +VPokeSpritesI SPR3_YPOS_L, 16, FINISH_TEXT_POSITION 
        +VPokeSpritesI SPR3_YPOS_H, 16, 0          
        rts

HideText:
        +VPokeSpritesI SPR3_ATTR_0, 16, 0       ;disable all text sprites
        rts
                            
