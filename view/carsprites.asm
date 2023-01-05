;*** carsprites.asm ********************************************************************************

;Tables for which sprite (0-4) represents the current angle and how it is flipped (0 = no flip, 1 = horizontal flip, 2 vertical flip, 3 = flipped both ways)
_anglespritetable       !byte   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15
                        !byte  16,15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1                       
                        !byte   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15
                        !byte  16,15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1
_anglefliptable         !byte   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        !byte   0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
                        !byte   1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
                        !byte   3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2

YCAR_COLLISION_MASK = %00110000
BCAR_COLLISION_MASK = %01010000
TCAR_COLLISION_MASK = %11100000

YCAR_BCAR_COLLISION = 16
YCAR_TCAR_COLLISION = 32
BCAR_TCAR_COLLISION = 64
TCAR_TCAR_COLLISION = 128

TRAFFIC_SPRITE0_INDEX = 1 + 2 + TEXTSPRITE_COUNT + 2     ;first traffic car sprite is after sprite 0, 2 car sprites, all text sprites and 2 badge sprites) 

TRAFFIC_SPRITE0 = $FC00 + TRAFFIC_SPRITE0_INDEX * 8     
TRAFFIC_SPRITE1 = TRAFFIC_SPRITE0 + 8
TRAFFIC_SPRITE2 = TRAFFIC_SPRITE1 + 8
TRAFFIC_SPRITE3 = TRAFFIC_SPRITE2 + 8
TRAFFIC_SPRITE4 = TRAFFIC_SPRITE3 + 8
TRAFFIC_SPRITE5 = TRAFFIC_SPRITE4 + 8
TRAFFIC_SPRITE6 = TRAFFIC_SPRITE5 + 8
TRAFFIC_SPRITE7 = TRAFFIC_SPRITE6 + 8

YCar_Show:
        +VPokeI SPR1_ATTR_0,YCAR_COLLISION_MASK+8       ;enable sprite and set collision mask
        +VPokeI SPR1_ATTR_1, %10100000 + 1              ;set palette 1 for yellow car
        rts

BCar_Show:
        +VPokeI SPR2_ATTR_0,BCAR_COLLISION_MASK+8       ;enable sprite and set collision mask
        +VPokeI SPR2_ATTR_1, %10100000 + 2              ;set palette 2 for blue car
        rts

.GetRandomTrafficPalette:
-       jsr GetRandomNumber1            ;OUT: .A = attr 1 one for att traffic car = size and palette index
        and #3
        cmp #3
        beq -
        clc
        adc #6                          ;add 6 because palette index 6 is first traffic car palette
        ora #%10100000
        rts

Traffic_Show:
        +VPokeSpritesI TRAFFIC_SPRITE0 + ATTR_0, TRAFFIC_COUNT, TCAR_COLLISION_MASK + 8    ;enable cars and set collision mask

        jsr .GetRandomTrafficPalette
        +VPoke TRAFFIC_SPRITE0 + ATTR_1 ;set sprite size and palette index
        jsr .GetRandomTrafficPalette
        +VPoke TRAFFIC_SPRITE1 + ATTR_1 ;set sprite size and palette index
        jsr .GetRandomTrafficPalette
        +VPoke TRAFFIC_SPRITE2 + ATTR_1 ;set sprite size and palette index
        jsr .GetRandomTrafficPalette
        +VPoke TRAFFIC_SPRITE3 + ATTR_1 ;set sprite size and palette index
        jsr .GetRandomTrafficPalette
        +VPoke TRAFFIC_SPRITE4 + ATTR_1 ;set sprite size and palette index
        jsr .GetRandomTrafficPalette
        +VPoke TRAFFIC_SPRITE5 + ATTR_1 ;set sprite size and palette index
        jsr .GetRandomTrafficPalette
        +VPoke TRAFFIC_SPRITE6 + ATTR_1 ;set sprite size and palette index
        jsr .GetRandomTrafficPalette
        +VPoke TRAFFIC_SPRITE7 + ATTR_1 ;set sprite size and palette index
        rts

HideCars:
        +VPokeI SPR1_ATTR_0,0    ;disable sprite 1
        +VPokeI SPR2_ATTR_0,0    ;disable sprite 2
        jsr HideTraffic
        rts

HideTraffic:
        +VPokeSpritesI TRAFFIC_SPRITE0 + ATTR_0, TRAFFIC_COUNT, 0 ;disable all traffic cars
        rts

!macro SetSprite .index, .base_addr, .collision_mask, .angle {       ;update car sprite to point in right direction, a skidding car will be rotated some extra degrees
        lda .angle            
        lsr                             ;get rid of fraction
        lsr
        pha
        tay
        lda _anglespritetable,y
        sta ZP0
        stz ZP1
        +MultiplyBy16 ZP0               ;multiply with 16 to get actual offset
        
        +Add16 ZP0, <(.base_addr>>5), >(.base_addr>>5) ;add address of first sprite
        lda ZP0
        +VPoke SPR0_ADDR_L+.index*8      
        lda ZP1
        +VPoke SPR0_MODE_ADDR_H+.index*8

        ;flip sprite if necessary
        pla
        tay                                          
        lda _anglefliptable,y
        ora #.collision_mask+8          ;don't forget to set bit 4 to keep a z depth of 2 (= between layers)
        +VPoke SPR0_ATTR_0+.index*8
}

!macro PositionSprite .pos_lo, .pos_hi, .campos_lo, .campos_hi, .screencenter {        
        ;calculate screen coordinates for sprite in relation to camera

        lda .pos_lo                     ;1 - start with car position - camera position
        sec
        sbc .campos_lo
        sta ZP0
        lda .pos_hi
        sbc .campos_hi
        sta ZP1

        lda #.screencenter-16           ;2 - add middle of screen - sprite width/2 to get position for middle of sprite
        clc
        adc ZP0
        sta ZP0
        lda #0
        adc ZP1
        and #15                         ;3 - wrap at 4096 (= width of game world/block map)
        sta ZP1

        cmp #$0f                        ;4 - check high byte to see if sprite position is between -256 and 512, if not hide it 
        bcs +                           ;(a position of for example 1024+50 would display the sprite at pos 50 otherwise...)
        cmp #$02
        bcc +
        stz ZP0                         ;sprite should not be displayed, to achieve this just set pos to 768
        lda #3                          ;when vertically positioned this line is not rendered thus collisions will not be triggered.
        sta ZP1
+       
}

YCar_UpdateSprite:
        +PositionSprite _ycarxpos_lo, _ycarxpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke SPR1_XPOS_L, ZP0
        +VPoke SPR1_XPOS_H, ZP1
        +PositionSprite _ycarypos_lo, _ycarypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke SPR1_YPOS_L, ZP0
        +VPoke SPR1_YPOS_H, ZP1
        +SetSprite 1, CARS_ADDR, YCAR_COLLISION_MASK, _ycardisplayangle
        rts

BCar_UpdateSprite:
        +PositionSprite _bcarxpos_lo, _bcarxpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke SPR2_XPOS_L, ZP0
        +VPoke SPR2_XPOS_H, ZP1
        +PositionSprite _bcarypos_lo, _bcarypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke SPR2_YPOS_L, ZP0
        +VPoke SPR2_YPOS_H, ZP1
        +SetSprite 2, CARS_ADDR, BCAR_COLLISION_MASK, _bcardisplayangle
        rts

Traffic_UpdateSprites:

        ;Car 0
+       +PositionSprite _car0_xpos_lo, _car0_xpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke TRAFFIC_SPRITE0 + XPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE0 + XPOS_H, ZP1
        +PositionSprite _car0_ypos_lo, _car0_ypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke TRAFFIC_SPRITE0 + YPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE0 + YPOS_H, ZP1
        +SetSprite TRAFFIC_SPRITE0_INDEX + 0, TRAFFIC_ADDR, TCAR_COLLISION_MASK, _car0_angle

        ;Car 1
        +PositionSprite _car1_xpos_lo, _car1_xpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke TRAFFIC_SPRITE1 + XPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE1 + XPOS_H, ZP1
        +PositionSprite _car1_ypos_lo, _car1_ypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke TRAFFIC_SPRITE1 + YPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE1 + YPOS_H, ZP1
        +SetSprite TRAFFIC_SPRITE0_INDEX + 1, TRAFFIC_ADDR, TCAR_COLLISION_MASK, _car1_angle

        ;Car 2
        +PositionSprite _car2_xpos_lo, _car2_xpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke TRAFFIC_SPRITE2 + XPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE2 + XPOS_H, ZP1
        +PositionSprite _car2_ypos_lo, _car2_ypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke TRAFFIC_SPRITE2 + YPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE2 + YPOS_H, ZP1
        +SetSprite TRAFFIC_SPRITE0_INDEX + 2, TRAFFIC_ADDR, TCAR_COLLISION_MASK, _car2_angle

        ;Car 3
        +PositionSprite _car3_xpos_lo, _car3_xpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke TRAFFIC_SPRITE3 + XPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE3 + XPOS_H, ZP1
        +PositionSprite _car3_ypos_lo, _car3_ypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke TRAFFIC_SPRITE3 + YPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE3 + YPOS_H, ZP1
        +SetSprite TRAFFIC_SPRITE0_INDEX + 3, TRAFFIC_ADDR, TCAR_COLLISION_MASK, _car3_angle

        ;Car 4
        +PositionSprite _car4_xpos_lo, _car4_xpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke TRAFFIC_SPRITE4 + XPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE4 + XPOS_H, ZP1
        +PositionSprite _car4_ypos_lo, _car4_ypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke TRAFFIC_SPRITE4 + YPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE4 + YPOS_H, ZP1
        +SetSprite TRAFFIC_SPRITE0_INDEX + 4, TRAFFIC_ADDR, TCAR_COLLISION_MASK, _car4_angle

        ;Car 5
        +PositionSprite _car5_xpos_lo, _car5_xpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke TRAFFIC_SPRITE5 + XPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE5 + XPOS_H, ZP1
        +PositionSprite _car5_ypos_lo, _car5_ypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke TRAFFIC_SPRITE5 + YPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE5 + YPOS_H, ZP1
        +SetSprite TRAFFIC_SPRITE0_INDEX + 5, TRAFFIC_ADDR, TCAR_COLLISION_MASK, _car5_angle

        ;Car 6
        +PositionSprite _car6_xpos_lo, _car6_xpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke TRAFFIC_SPRITE6 + XPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE6 + XPOS_H, ZP1
        +PositionSprite _car6_ypos_lo, _car6_ypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke TRAFFIC_SPRITE6 + YPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE6 + YPOS_H, ZP1
        +SetSprite TRAFFIC_SPRITE0_INDEX + 6, TRAFFIC_ADDR, TCAR_COLLISION_MASK, _car6_angle

        ;Car 7
        +PositionSprite _car7_xpos_lo, _car7_xpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke TRAFFIC_SPRITE7 + XPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE7 + XPOS_H, ZP1
        +PositionSprite _car7_ypos_lo, _car7_ypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke TRAFFIC_SPRITE7 + YPOS_L, ZP0
        +VPoke TRAFFIC_SPRITE7 + YPOS_H, ZP1
        +SetSprite TRAFFIC_SPRITE0_INDEX + 7, TRAFFIC_ADDR, TCAR_COLLISION_MASK, _car7_angle
        rts

BlowUpCars:                             ;Blow up one car or both depending on the collision flag of each car
        lda .animationindex             ;load current animation index
        cmp #10                         ;10 sprites in explosion animation
        bne +
        jmp ++    

+       clc
        adc #17                         ;add offset, first sprite in animation is no 17
        sta ZP0
        stz ZP1
        +MultiplyBy16 ZP0               ;multiply with 16 to get actual offset
        lda ZP1                         ;add sprite base address = $8000 ($8000/32 = $400)
        clc
        adc #$04
        sta ZP1
        
        lda _ycarcollisionflag
        beq +
        +VPoke SPR1_ADDR_L, ZP0         ;set low address of next sprite in animation
        +VPoke SPR1_MODE_ADDR_H, ZP1    ;set high address of next sprite in animation
        +VPokeI SPR1_ATTR_1, %10101001  ;palette index 9

+       lda _bcarcollisionflag
        beq +
        +VPoke SPR2_ADDR_L, ZP0         ;set low address of next sprite in animation
        +VPoke SPR2_MODE_ADDR_H, ZP1    ;set high address of next sprite in animation
        +VPokeI SPR2_ATTR_1, %10101001   ;palette index 9

+       inc .animationdelay             ;wait a certain amount of interrupt calls before advancing frame
        lda .animationdelay
        cmp #ANIMATION_DELAY
        beq +
        rts

+       inc .animationindex  
        stz .animationdelay
        rts

++      inc .animationdelay              ;after animation is over, add a short wait
        lda .animationdelay
        cmp #40
        beq +++
        rts

+++     stz .animationindex
        stz .animationdelay
        lda _ycarcollisionflag
        beq +
        +VPokeI SPR1_ATTR_1, %10100001  ;restore palette index 1
        lda #COLLISION_TIME             
        jsr YCar_TimeAddSeconds         ;add extra time for yellow car if just blown up
+       lda _bcarcollisionflag
        beq +
        +VPokeI SPR2_ATTR_1, %10100010  ;restore palette index 2
        lda #COLLISION_TIME
        jsr BCar_TimeAddSeconds         ;add extra time for blue car if just blown up
+       stz _ycarcollisionflag
        stz _bcarcollisionflag
        rts

ANIMATION_COUNT = 10

.animationindex !byte 0         ;current sprite in explosion animation
.animationdelay !byte 0         ;delay counter to slow down animation 

