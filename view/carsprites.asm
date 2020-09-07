;*** carsprites.asm ********************************************************************************

COLLISION_MASK = %00010000

YCar_Show:
        +VPokeI SPR1_ATTR_0,COLLISION_MASK+8    ;enable sprite and set collision mask
        +VPokeI SPR1_ATTR_1, %10100000 + 1      ;set palette 1 for yellow car
        rts

BCar_Show:
        +VPokeI SPR2_ATTR_0,COLLISION_MASK+8    ;enable sprite and set collision mask
        +VPokeI SPR2_ATTR_1, %10100000 + 2      ;set palette 2 for blue car
        rts

HideCars:
        +VPokeI SPR1_ATTR_0,0    ;disable sprite 1
        +VPokeI SPR2_ATTR_0,0    ;disable sprite 2
        rts

!macro SetSprite .index, .angle {       ;update car sprite to point in right direction, a skidding car will be rotated some extra degrees
        lda .angle            
        lsr                             ;get rid of fraction
        lsr
        pha
        tay
        lda _anglespritetable,y
        sta ZP0
        stz ZP1
        +MultiplyBy16 ZP0               ;multiply with 16 to get actual offset
        lda ZP0
        +VPoke SPR0_ADDR_L+.index*8      
        lda ZP1
        clc
        adc #$04                        ;add base address of sprites (sprite 1 located at $8000 and $8000/32=$400)
        +VPoke SPR0_MODE_ADDR_H+.index*8

        ;flip sprite if necessary
        pla
        tay                                          
        lda _anglefliptable,y
        ora #COLLISION_MASK+8          ;don't forget to set bit 4 to keep a z depth of 2 (= between layers)
        +VPoke SPR0_ATTR_0+.index*8
}

; !macro PositionSprite .index, .xpos_lo, .xpos_hi, .ypos_lo, .ypos_hi {  ;position sprite in relation to camera

;         ;calculate x position
;         lda .xpos_lo                    ;start with car pos - cam pos
;         sec
;         sbc _camxpos_lo
;         sta ZP0
;         lda .xpos_hi
;         sbc _camxpos_hi
;         sta ZP1

;         lda #(SCREEN_WIDTH/2)-16        ;add middle of screen minus half sprite width to get pos for middle of sprite
;         clc
;         adc ZP0
;         sta ZP0
;         lda #0
;         adc ZP1
;         and #15                         ;wrap around at 4096 (width of game world)
;         sta ZP1

;         cmp #$0f                        ;check high byte to see if sprite position is between -256 and 512), if not hide it 
;         beq +                           ;(a position of for example 1024+50 would display the sprite at pos 50 otherwise...)
;         cmp #$02
;         bcc +
;         stz ZP0                         ;sprite should not be displayed, to achieve this just set xpos to 512
;         lda #2
;         sta ZP1

;         ;calculate y position
; +       lda .ypos_lo                    ;start with car pos - cam pos
;         sec
;         sbc _camypos_lo
;         sta ZP2
;         lda .ypos_hi
;         sbc _camypos_hi
;         sta ZP3
        
;         lda #(SCREEN_HEIGHT/2)-16       ;add middle of screen minus half sprite height
;         clc
;         adc ZP2
;         sta ZP2
;         lda #0
;         adc ZP3
;         and #15                         ;wrap around at 4096 (width of game world)
;         sta ZP3
        
;         cmp #$0f                        ;check high byte to see if sprite position is between -256 and 512), if not hide it  
;         bcs +                           ;(a position of for example 1024+50 would display the sprite at pos 50 otherwise...)
;         cmp #$02
;         bcc +
;         stz ZP2                         ;sprite should not be displayed, to achieve this just set ypos to 512
;         lda #2
;         sta ZP3

; +       +VPoke SPR0_XPOS_L+.index*8, ZP0
;         +VPoke SPR0_XPOS_H+.index*8, ZP1
;         +VPoke SPR0_YPOS_L+.index*8, ZP2
;         +VPoke SPR0_YPOS_H+.index*8, ZP3
; }

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
        stz ZP0                         ;sprite should not be displayed, to achieve this just set xpos to 512
        lda #2
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
        +SetSprite 1, _ycardisplayangle
        rts

BCar_UpdateSprite:
        +PositionSprite _bcarxpos_lo, _bcarxpos_hi, _camxpos_lo, _camxpos_hi, SCREEN_WIDTH/2
        +VPoke SPR2_XPOS_L, ZP0
        +VPoke SPR2_XPOS_H, ZP1
        +PositionSprite _bcarypos_lo, _bcarypos_hi, _camypos_lo, _camypos_hi, SCREEN_HEIGHT/2
        +VPoke SPR2_YPOS_L, ZP0
        +VPoke SPR2_YPOS_H, ZP1
        +SetSprite 2, _bcardisplayangle
        rts

; YCar_UpdateSprite:
;         +PositionSprite 1, _ycarxpos_lo, _ycarxpos_hi, _ycarypos_lo, _ycarypos_hi
;         +SetSprite 1, _ycardisplayangle
;         rts

; BCar_UpdateSprite
;         +PositionSprite 2, _bcarxpos_lo, _bcarxpos_hi, _bcarypos_lo, _bcarypos_hi
;         +SetSprite 2, _bcardisplayangle
;         rts

BlowUpCars:                             ;Blow up one car or both depending on the collision flag of each car
        lda .animationindex             ;load current animation index
        cmp #12                         ;12 sprites in explosion animation
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
        +VPokeI SPR1_ATTR_1, %10100000  ;set palette offset to 0 (explosion colors)

+       lda _bcarcollisionflag
        beq +
        +VPoke SPR2_ADDR_L, ZP0         ;set low address of next sprite in animation
        +VPoke SPR2_MODE_ADDR_H, ZP1    ;set high address of next sprite in animation
        +VPokeI SPR2_ATTR_1, %10100000  ;set palette offset to 0 (explosion colors)

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
        cmp #30
        beq +++
        rts

+++     stz .animationindex
        stz .animationdelay
        lda #COLLISION_TIME             
        ldx _ycarcollisionflag
        beq +
        jsr YCar_TimeAddSeconds         ;add extra time for yellow car if just blown up
+       ldx _bcarcollisionflag
        beq +
        jsr BCar_TimeAddSeconds         ;add extra time for blue car if just blown up
+       stz _ycarcollisionflag
        stz _bcarcollisionflag
        rts

.animationindex !byte 0         ;current sprite in explosion animation
.animationdelay !byte 0         ;delay counter to slow down animation 
