;*** interaction.asm - when a car outruns the other or cars collides *******************************

xdist_lo        = ZP0   ;horizontal distance between cars
xdist_hi        = ZP1
ydist_lo        = ZP2   ;vertical distance between cars
ydist_hi        = ZP3
absxdist_lo     = ZP4   ;absolute horizontal distance between cars
absxdist_hi     = ZP5
absydist_lo     = ZP6   ;absolute vertical distance between cars
absydist_hi     = ZP7
collisionangle  = ZP8   ;angle of collision with yellow car as reference point (= center in coordinate system)
tableadr        = ZP9   ;(and ZPA) where to read from in atan table

; DetectOutrun: (NO COLLISION CHECK)
;         ;1 - check horizontal distance      
;         lda _bcarxpos_lo                ;bcar pos - ycar pos
;         sec
;         sbc _ycarxpos_lo
;         tax                             ;low byte in .X
;         lda _bcarxpos_hi
;         sbc _ycarxpos_hi
;         tay                             ;high byte in .Y
;         bcs +
;         txa                             ;if negative result, convert to positive number
;         eor #$ff                        
;         inc
;         tax
;         tya
;         eor #$ff
;         tay
; +       cpx #44                         ;low byte must be 44 or higher
;         bcc +
;         cpy #1                          ;high byte must be 1 (1 * 256 + 44 = 300)
;         beq SetOutrun                   

;         ;2 - check vertical distance
; +       lda _bcarypos_lo                ;bcar pos - ycar pos
;         sec
;         sbc _ycarypos_lo
;         tax                             ;low byte in .X
;         lda _bcarypos_hi
;         sbc _ycarypos_hi
;         txa
;         bcs +
;         eor #$ff                        ;if negative result, convert to positive number
;         inc
; +       cmp #220                        ;low byte must be 220 or higher (high byte is irrelevant)
;         bcs SetOutrun
;         rts

UpdateStartPosition:                       ;set new start position after collision or outrun
        lda _noofplayers
        cmp #1
        bne +
        jsr YCar_UpdateStartPosition    ;if one player simply set last checkpoint of yellow car
        rts
+       lda _ycardistance               ;if two players set last checkpoint of the car which has driven the longest distance
        cmp _bcardistance
        bcc +
        jsr YCar_UpdateStartPosition
        rts
+       jsr BCar_UpdateStartPosition
        rts

DetectClash:
        ;calculate horizontal distance      
        lda _bcarxpos_lo                ;bcar pos - ycar pos
        sec
        sbc _ycarxpos_lo
        sta xdist_lo
        lda _bcarxpos_hi
        sbc _ycarxpos_hi
        sta xdist_hi

        ;calculate vertical distance
        lda _bcarypos_lo                ;bcar pos - ycar pos
        sec
        sbc _ycarypos_lo
        sta ydist_lo
        lda _bcarypos_hi
        sbc _ycarypos_hi
        sta ydist_hi        

        ;calculate absolute horizontal distance
        lda xdist_lo
        sta absxdist_lo
        lda xdist_hi
        sta absxdist_hi                 ;assume value is positive from beginnning
        bit #$80                
        beq +
        eor #$ff                        ;if not convert from minus to plus
        sta absxdist_hi
        lda xdist_lo
        eor #$ff                        
        inc
        sta absxdist_lo

        ;calculate absolute vertical distance
+       lda ydist_lo
        sta absydist_lo
        lda ydist_hi
        sta absydist_hi                 ;assume value is positive from beginning
        bit #$80
        beq +
        eor #$ff                        ;if not convert from minus to plus
        sta absydist_hi                        
        lda ydist_lo
        eor #$ff
        inc
        sta absydist_lo

        ;check for car clash - collison between cars
+       lda absxdist_lo
        cmp #18                         ;low x byte must be 20 or less
        bcs +
        lda absxdist_hi                         
        bne +                           ;high x byte must be 0
        lda absydist_lo
        cmp #18                         ;low y byte must be 20 or less 
        bcs +
        lda absydist_hi
        bne +                           ;high y byte must be 0
        jsr SetClash
        rts                             ;if clash, outrun calculations are unnecessary   

        ;check for horizontal outrun
+       lda absxdist_lo
        cmp #44                         ;low byte must be 44 or higher
        bcc +
        lda absxdist_hi
        cmp #1                          ;high byte must be 1 (1 * 256 + 44 = 300)
        beq SetOutrun                   

        ;check for vertical outrun
+       lda absydist_lo
        cmp #220                        ;low byte must be 220 or higher (high byte is irrelevant)
        bcs SetOutrun
        rts

SetOutrun:                              ;if one car is outrun - decide which and set new game status
        lda #ST_OUTRUN
        sta _gamestatus
        lda _ycardistance
        cmp _bcardistance
        bcc +
        lda #1
        sta _bcaroutrun
        lda #PENALTY_TIME
        jsr BCar_TimeAddSeconds
        rts
+       stz _bcaroutrun
        lda #PENALTY_TIME
        jsr YCar_TimeAddSeconds
        rts        

_bcaroutrun     !byte   0       ;1 = blue car outrun, 0 = yellow car outrun

SetClash:     
        ;calculate collision angle
        jsr GetClashAngle
        lda collisionangle        
        sta _bcarclashangle ;set angle in which direction blue car is pushed by yellow car
        clc
        adc #128            ;add 180 deg
        sta _ycarclashangle ;set angle in which direction yellow car is pushed by blue car (the opposite direction)

        ;calculate how much blue car is pushed by yellow car
        lda _ycarspeed
        lsr
        lsr                     ;skip fraction
        tax                     ;yellow car speed in .X
        lda collisionangle
        sec
        sbc _ycarangle          ;difference between collision angle and movement angle is needed to calculate in which speed yellow car is moving against blue car
        lsr
        lsr                     ;skip fraction, angle is fixed point 6.2
        asl                     ;multiply by two to get right offset for cos value (16 bit words)
        tay
        lda #0
-       clc 
        adc  _anglecos,y        ;add 4 bit fraction
        dex
        bne -
        bit #$80
        beq +
        stz _bcarclashpush      ;if yellow car actually is moving away it is of course not pushing
        bra ++
+       lsr                     ;convert from fixed point 4.4 to fixed point 6.2
        lsr
        sta _bcarclashpush

        ;calculate how much yellow car is pushed by blue car
++      lda _bcarspeed
        lsr
        lsr                     ;skip fraction
        tax                     ;blue car speed in .X
        lda collisionangle
        clc
        adc #128
        sec
        sbc _bcarangle          ;difference between collision angle and movement angle is needed to calculate in which speed blue car is moving against yellow car
        lsr
        lsr                     ;skip fraction, angle is fixed point 6.2
        asl                     ;multiply by two to get right offset for cos value (16 bit words)
        tay
        lda #0
-       clc 
        adc  _anglecos,y        ;add 4 bit fraction
        dex
        bne -
        bit #$80
        beq +
        stz _ycarclashpush      ;if blue car actually is moving away it is of course not pushing
        rts
+       lsr                     ;convert from fixed point 4.4 to fixed point 6.2
        lsr
        sta _ycarclashpush
        rts      

GetClashAngle:                  ;Get collision/clash angle. The yellow car is the reference point (for exemaple if blue car is exactly above yellow, the collision angle is 90 deg)
        lda absydist_lo
        sta tableadr
        stz tableadr+1
        +MultiplyBy32 tableadr
        lda absxdist_lo
        clc
        adc tableadr
        sta tableadr
        lda tableadr+1
        adc #0
        sta tableadr+1
        lda #<.atantable
        clc
        adc tableadr
        sta tableadr
        lda #>.atantable
        adc tableadr+1
        sta tableadr+1
        lda (tableadr)
        sta collisionangle

        lda xdist_lo
        bpl +
        lda #128                ;if x<0
        sec
        sbc collisionangle
        sta collisionangle
+       lda ydist_lo    
        bmi +                   ;turn y-axis upside down by using bmi instead of bpl.
        lda #0                  ;if y<0
        sec
        sbc collisionangle
        sta collisionangle
+       rts

.atantable:     ;rows x = 0 to 31, columns y = 0 to 31
        !byte	-1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte	64,32,19,13,10, 8, 7, 6, 5, 5, 4, 4, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1
        !byte	64,45,32,24,19,16,13,11,10, 9, 8, 7, 7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3
        !byte	64,51,40,32,26,22,19,16,15,13,12,11,10, 9, 9, 8, 8, 7, 7, 6, 6, 6, 6, 5, 5, 5, 5, 5, 4, 4, 4, 4
        !byte	64,54,45,38,32,27,24,21,19,17,16,14,13,12,11,11,10, 9, 9, 8, 8, 8, 7, 7, 7, 6, 6, 6, 6, 6, 5, 5
        !byte	64,56,48,42,37,32,28,25,23,21,19,17,16,15,14,13,12,12,11,10,10,10, 9, 9, 8, 8, 8, 7, 7, 7, 7, 7
        !byte	64,57,51,45,40,36,32,29,26,24,22,20,19,18,16,16,15,14,13,12,12,11,11,10,10,10, 9, 9, 9, 8, 8, 8
        !byte	64,58,53,48,43,39,35,32,29,27,25,23,22,20,19,18,17,16,15,14,14,13,13,12,12,11,11,10,10,10, 9, 9
        !byte	64,59,54,49,45,41,38,35,32,30,27,26,24,22,21,20,19,18,17,16,16,15,14,14,13,13,12,12,11,11,11,10
        !byte	64,59,55,51,47,43,40,37,34,32,30,28,26,25,23,22,21,20,19,18,17,16,16,15,15,14,14,13,13,12,12,12
        !byte	64,60,56,52,48,45,42,39,37,34,32,30,28,27,25,24,23,22,21,20,19,18,17,17,16,16,15,14,14,14,13,13
        !byte	64,60,57,53,50,47,44,41,38,36,34,32,30,29,27,26,25,23,22,21,20,20,19,18,18,17,16,16,15,15,14,14
        !byte	64,61,57,54,51,48,45,42,40,38,36,34,32,30,29,27,26,25,24,23,22,21,20,20,19,18,18,17,16,16,16,15
        !byte	64,61,58,55,52,49,46,44,42,39,37,35,34,32,30,29,28,27,25,24,23,23,22,21,20,20,19,18,18,17,17,16
        !byte	64,61,58,55,53,50,48,45,43,41,39,37,35,34,32,31,29,28,27,26,25,24,23,22,22,21,20,19,19,18,18,17
        !byte	64,61,59,56,53,51,48,46,44,42,40,38,37,35,33,32,31,29,28,27,26,25,24,24,23,22,21,21,20,19,19,18
        !byte	64,61,59,56,54,52,49,47,45,43,41,39,38,36,35,33,32,31,30,29,27,27,26,25,24,23,22,22,21,21,20,19
        !byte	64,62,59,57,55,52,50,48,46,44,42,41,39,37,36,35,33,32,31,30,29,28,27,26,25,24,24,23,22,22,21,20
        !byte	64,62,59,57,55,53,51,49,47,45,43,42,40,39,37,36,34,33,32,31,30,29,28,27,26,25,25,24,23,23,22,21
        !byte	64,62,60,58,56,54,52,50,48,46,44,43,41,40,38,37,35,34,33,32,31,30,29,28,27,26,26,25,24,24,23,22
        !byte	64,62,60,58,56,54,52,50,48,47,45,44,42,41,39,38,37,35,34,33,32,31,30,29,28,27,27,26,25,25,24,23
        !byte	64,62,60,58,56,54,53,51,49,48,46,44,43,41,40,39,37,36,35,34,33,32,31,30,29,28,28,27,26,26,25,24
        !byte	64,62,60,58,57,55,53,51,50,48,47,45,44,42,41,40,38,37,36,35,34,33,32,31,30,29,29,28,27,26,26,25
        !byte	64,62,60,59,57,55,54,52,50,49,47,46,44,43,42,40,39,38,37,36,35,34,33,32,31,30,30,29,28,27,27,26
        !byte	64,62,61,59,57,56,54,52,51,49,48,46,45,44,42,41,40,39,38,37,36,35,34,33,32,31,30,30,29,28,27,27
        !byte	64,62,61,59,58,56,54,53,51,50,48,47,46,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,30,29,28,28
        !byte	64,62,61,59,58,56,55,53,52,50,49,48,46,45,44,43,42,40,39,38,37,36,35,34,34,33,32,31,30,30,29,28
        !byte	64,62,61,59,58,57,55,54,52,51,50,48,47,46,45,43,42,41,40,39,38,37,36,35,34,34,33,32,31,31,30,29
        !byte	64,63,61,60,58,57,55,54,53,51,50,49,48,46,45,44,43,42,41,40,39,38,37,36,35,34,34,33,32,31,31,30
        !byte	64,63,61,60,58,57,56,54,53,52,50,49,48,47,46,45,43,42,41,40,39,38,38,37,36,35,34,33,33,32,31,31
        !byte	64,63,61,60,59,57,56,55,53,52,51,50,48,47,46,45,44,43,42,41,40,39,38,37,37,36,35,34,33,33,32,31
        !byte	64,63,61,60,59,57,56,55,54,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,36,35,34,33,33,32