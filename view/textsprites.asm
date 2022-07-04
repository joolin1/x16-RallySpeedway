;*** textsprites.asm - handle texts built up by sprites *********************************************

PENALTY_TEXT_POSITION = 98
FINISH_TEXT_POSITION = 44

SPR_ATTR_0 = SPR3_ATTR_0
SPR_ATTR_1 = SPR3_ATTR_1
SPR_XPOS_L = SPR3_XPOS_L
SPR_XPOS_H = SPR3_XPOS_H
SPR_YPOS_L = SPR3_YPOS_L
SPR_YPOS_H = SPR3_YPOS_H

TEXTSPRITE_COUNT = 15 + 4       ;15 letters + 4 duplicates

SPR_A  = 0
SPR_D  = 8
SPR_E  = 16
SPR_F  = 24
SPR_H  = 32
SPR_I  = 40
SPR_L  = 48
SPR_N  = 56
SPR_O  = 64
SPR_P  = 72
SPR_R  = 80
SPR_S  = 88
SPR_T  = 96
SPR_W  = 104
SPR_Y  = 112
SPR_I2 = 120
SPR_N2 = 128
SPR_O2 = 136
SPR_F2 = 144

ShowPenaltyText:                ;.A = text color. 0 = yellow, 1 = blue
        ;set palette
        clc
        adc #224 + 1
        +VPokeSprites SPR_ATTR_1, TEXTSPRITE_COUNT

        ;enable letters
        +VPokeI SPR_ATTR_0 + SPR_P, 12
        +VPokeI SPR_ATTR_0 + SPR_E, 12
        +VPokeI SPR_ATTR_0 + SPR_N, 12
        +VPokeI SPR_ATTR_0 + SPR_A, 12
        +VPokeI SPR_ATTR_0 + SPR_L, 12
        +VPokeI SPR_ATTR_0 + SPR_T, 12
        +VPokeI SPR_ATTR_0 + SPR_Y, 12

        ;distribute in a row in the middle of the screen       
        +VPokeI SPR_XPOS_L + SPR_P, 24                 
        +VPokeI SPR_XPOS_L + SPR_E, 24 + 40
        +VPokeI SPR_XPOS_L + SPR_N, 24 + 80
        +VPokeI SPR_XPOS_L + SPR_A, 24 + 120
        +VPokeI SPR_XPOS_L + SPR_L, 24 + 160
        +VPokeI SPR_XPOS_L + SPR_T, 24 + 200
        +VPokeI SPR_XPOS_L + SPR_Y, 24 + 240 - 256 

        +VPokeSpritesI SPR_XPOS_H, TEXTSPRITE_COUNT, 0
        +VPokeI SPR_XPOS_H + SPR_Y, 1

        ;set vertical position
        +VPokeSpritesI SPR_YPOS_L, TEXTSPRITE_COUNT, PENALTY_TEXT_POSITION
        +VPokeSpritesI SPR_YPOS_H, TEXTSPRITE_COUNT, 0

        lda #140
        sta .textdelay                
        rts

ShowOffroadText:
        ;set palette 3 = sprite text palette
        lda #224 + 3
        +VPokeSprites SPR_ATTR_1, TEXTSPRITE_COUNT

        ;enable letters
        +VPokeI SPR_ATTR_0 + SPR_O , 12
        +VPokeI SPR_ATTR_0 + SPR_F , 12
        +VPokeI SPR_ATTR_0 + SPR_F2, 12
        +VPokeI SPR_ATTR_0 + SPR_R , 12
        +VPokeI SPR_ATTR_0 + SPR_O2, 12
        +VPokeI SPR_ATTR_0 + SPR_A , 12
        +VPokeI SPR_ATTR_0 + SPR_D , 12

        ;distribute in a row in the middle of the screen       
        +VPokeI SPR_XPOS_L + SPR_O , 24                 
        +VPokeI SPR_XPOS_L + SPR_F , 24 + 40
        +VPokeI SPR_XPOS_L + SPR_F2, 24 + 80
        +VPokeI SPR_XPOS_L + SPR_R , 24 + 120
        +VPokeI SPR_XPOS_L + SPR_O2, 24 + 160
        +VPokeI SPR_XPOS_L + SPR_A , 24 + 200
        +VPokeI SPR_XPOS_L + SPR_D , 24 + 240 - 256  

        +VPokeSpritesI SPR_XPOS_H, TEXTSPRITE_COUNT, 0
        +VPokeI SPR_XPOS_H + SPR_D, 1

        ;set vertical position
        +VPokeSpritesI SPR_YPOS_L, TEXTSPRITE_COUNT, PENALTY_TEXT_POSITION
        +VPokeSpritesI SPR_YPOS_H, TEXTSPRITE_COUNT, 0

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

ShowRaceOverText:
        ldx _noofplayers
        cpx #1
        bne +
        jsr .ShowFinishedText
        rts
+       lda _winner
        cmp #3                  ;3 = race ended in a draw
        bne +
        jsr .ShowFinishedText
        rts
+       jsr .ShowWinnerText
        rts

.ShowFinishedText:              ;show "FINISHED" text in yellow when one player
        ;set palette
        lda #224 + 1
        +VPokeSprites SPR_ATTR_1, TEXTSPRITE_COUNT
        
        ;enable letters
        +VPokeI SPR_ATTR_0 + SPR_F , 12         
        +VPokeI SPR_ATTR_0 + SPR_I , 12
        +VPokeI SPR_ATTR_0 + SPR_N , 12
        +VPokeI SPR_ATTR_0 + SPR_I2, 12
        +VPokeI SPR_ATTR_0 + SPR_S , 12
        +VPokeI SPR_ATTR_0 + SPR_H , 12
        +VPokeI SPR_ATTR_0 + SPR_E , 12
        +VPokeI SPR_ATTR_0 + SPR_D , 12

        ;distribute in a row in the middle of the screen
        +VPokeI SPR_XPOS_L + SPR_F , 20
        +VPokeI SPR_XPOS_L + SPR_I , 20 + 32
        +VPokeI SPR_XPOS_L + SPR_N , 20 + 64
        +VPokeI SPR_XPOS_L + SPR_I2, 20 + 96
        +VPokeI SPR_XPOS_L + SPR_S , 20 + 128
        +VPokeI SPR_XPOS_L + SPR_H , 20 + 168
        +VPokeI SPR_XPOS_L + SPR_E , 20 + 208
        +VPokeI SPR_XPOS_L + SPR_D , 20 + 248 - 256

        +VPokeSpritesI SPR_XPOS_H, TEXTSPRITE_COUNT, 0
        +VPokeI SPR_XPOS_H + SPR_D, 1  
        
        ;set vertical position        
        +VPokeSpritesI SPR_YPOS_L, TEXTSPRITE_COUNT, FINISH_TEXT_POSITION 
        +VPokeSpritesI SPR_YPOS_H, TEXTSPRITE_COUNT, 0          
        rts

.ShowWinnerText:                ;show "WINNER" text in yellow or blue color depending on winner
        ;set palette
        lda _winner         
        dec
        clc
        adc #224 + 1
        +VPokeSprites SPR_ATTR_1, TEXTSPRITE_COUNT
        
        ;enable letters
        +VPokeI SPR_ATTR_0 + SPR_W , 12
        +VPokeI SPR_ATTR_0 + SPR_I , 12
        +VPokeI SPR_ATTR_0 + SPR_N , 12
        +VPokeI SPR_ATTR_0 + SPR_N2, 12
        +VPokeI SPR_ATTR_0 + SPR_E , 12
        +VPokeI SPR_ATTR_0 + SPR_R , 12

        ;distribute in a row in the middle of the screen
        +VPokeI SPR_XPOS_L + SPR_W , 52
        +VPokeI SPR_XPOS_L + SPR_I , 52 + 32
        +VPokeI SPR_XPOS_L + SPR_N , 52 + 64
        +VPokeI SPR_XPOS_L + SPR_N2, 52 + 104
        +VPokeI SPR_XPOS_L + SPR_E , 52 + 144
        +VPokeI SPR_XPOS_L + SPR_R , 52 + 184

        +VPokeSpritesI SPR_XPOS_H, TEXTSPRITE_COUNT, 0 

        ;set vertical position
        +VPokeSpritesI SPR_YPOS_L, TEXTSPRITE_COUNT, FINISH_TEXT_POSITION 
        +VPokeSpritesI SPR_YPOS_H, TEXTSPRITE_COUNT, 0          
        rts

HideText:
        +VPokeSpritesI SPR_ATTR_0, TEXTSPRITE_COUNT, 0  ;disable all text sprites
        rts