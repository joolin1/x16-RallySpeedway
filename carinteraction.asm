;*** interaction.asm - when a car outruns the other or cars collides *******************************

.xdist_lo       = ZP0   ;horizontal distance between cars
.xdist_hi       = ZP1
.ydist_lo       = ZP2   ;vertical distance between cars
.ydist_hi       = ZP3
.absxdist_lo    = ZP4   ;absolute horizontal distance between cars
.absxdist_hi    = ZP5
.absydist_lo    = ZP6   ;absolute vertical distance between cars
.absydist_hi    = ZP7
.collisionangle = ZP8   ;angle of collision with yellow car as reference point (= center in coordinate system)
.tableadr       = ZP9   ;(and ZPA) where to read from in atan table

_winner         !byte   0       ;0 = race ended in a draw, 1 = yellow car, 2 = blue car
_isrecord       !byte   0       ;whether winning time is a new record

CheckRaceOver:                          ;check if race is over  
        lda _ycarfinishflag
        bne +
        rts       
+       lda _ycarspeed
        beq +
        rts
+       lda _noofplayers
        cmp #1
        bne +
        lda #ST_FINISH                  ;one player, finish flag is set, speed is 0 -> race over
        sta _gamestatus
        rts
+       lda _bcarfinishflag
        bne +
        rts
+       lda _bcarspeed
        beq +
        rts
+       lda #ST_FINISH                  ;two players, both finish flags set, speed is 0 for both cars - > race over
        sta _gamestatus
        rts

SetWinnerAndRecord:             ;OUT: global variable _winner = 0, 1 or 2. 0 = race ended in a draw, 1 = yellow car has won, 2 = blue car has won
        lda _noofplayers
        cmp #1
        bne +
        lda #1                  ;yellow car is "winner" when only one player
        sta _winner
        bra ++
+       +SetParams _ycartime, _ycartime+1, _ycartime+2, _bcartime, _bcartime+1, _bcartime+2
        jsr AreTimesEqual
        bne +
        lda #0
        sta _winner
        bra ++
+       jsr IsTimeLess          ;is time of blue car less than time of yellow car?
        bcc +
        lda #1
        sta _winner
        bra ++
+       lda #2
        sta _winner

++      jsr .SetWinnerParams
        lda _track
        jsr IsNewLeaderboardRecord
        bcc +
        stz _isrecord
        rts
+       jsr .SetWinnerParams
        lda _track
        jsr SetLeaderboardRecord
        lda #1
        sta _isrecord
        rts

.SetWinnerParams
        lda _winner
        cmp #2
        beq +
        +SetParams _ycartime, _ycartime+1, _ycartime+2
        rts
+       +SetParams _bcartime, _bcartime+1, _bcartime+2
        rts

UpdateStartPosition:                    ;set new start position after collision or outrun
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

CheckInteraction:
        ;calculate horizontal distance      
        lda _bcarxpos_lo                ;bcar pos - ycar pos
        sec
        sbc _ycarxpos_lo
        sta .xdist_lo
        lda _bcarxpos_hi
        sbc _ycarxpos_hi
        sta .xdist_hi

        ;calculate vertical distance
        lda _bcarypos_lo                ;bcar pos - ycar pos
        sec
        sbc _ycarypos_lo
        sta .ydist_lo
        lda _bcarypos_hi
        sbc _ycarypos_hi
        sta .ydist_hi        

        ;calculate absolute horizontal distance
        lda .xdist_lo
        sta .absxdist_lo
        lda .xdist_hi
        sta .absxdist_hi                 ;assume value is positive from beginnning
        bit #$80                
        beq +
        eor #$ff                        ;if not convert from minus to plus
        sta .absxdist_hi
        lda .xdist_lo
        eor #$ff                        
        inc
        sta .absxdist_lo

        ;calculate absolute vertical distance
+       lda .ydist_lo
        sta .absydist_lo
        lda .ydist_hi
        sta .absydist_hi                 ;assume value is positive from beginning
        bit #$80
        beq +
        eor #$ff                        ;if not convert from minus to plus
        sta .absydist_hi                        
        lda .ydist_lo
        eor #$ff
        inc
        sta .absydist_lo

        ;check for car clash - collison between cars
+       lda .absxdist_lo
        cmp #18                         ;low x byte must be 20 or less
        bcs +
        lda .absxdist_hi                         
        bne +                           ;high x byte must be 0
        lda .absydist_lo
        cmp #18                         ;low y byte must be 20 or less 
        bcs +
        lda .absydist_hi
        bne +                           ;high y byte must be 0
        jsr SetClash
        rts                             ;if clash, outrun calculations are unnecessary   

        ;check for horizontal outrun
+       lda .absxdist_lo
        cmp #44                         ;low byte must be 44 or higher
        bcc +
        lda .absxdist_hi
        cmp #1                          ;high byte must be 1 (1 * 256 + 44 = 300)
        beq SetOutrun                   

        ;check for vertical outrun
+       lda .absydist_lo
        cmp #220                        ;low byte must be 220 or higher (high byte is irrelevant)
        bcs SetOutrun
        rts

SetOutrun:                              ;if one car is outrun - decide which and set new game status
        lda _ycarfinishflag             ;if any of the cars have finished the race just abort
        beq +
        rts
+       lda _bcarfinishflag
        beq +
        rts
+       jsr StopCarSounds
        jsr PlayOutrunSound
        lda #ST_OUTRUN
        sta _gamestatus
        lda _ycardistance
        cmp _bcardistance
        bcc +
        lda #1
        sta _bcaroutrun
        jsr ShowPenaltyText
        lda #PENALTY_TIME
        jsr BCar_TimeAddSeconds
        sed
        inc _bcarpenaltycount           ;count number of penalties in decimal mode
        cld
        rts
+       lda #0
        sta _bcaroutrun
        jsr ShowPenaltyText
        lda #PENALTY_TIME
        jsr YCar_TimeAddSeconds
        sed
        inc _ycarpenaltycount           ;count number of penalties in decimal mode
        cld
        rts        

_bcaroutrun     !byte   0       ;1 = blue car outrun, 0 = yellow car outrun

SetClash:
        jsr PlayClashSound

        ;calculate collision angle
        jsr GetClashAngle
        lda .collisionangle        
        sta _bcarclashangle ;set angle in which direction blue car is pushed by yellow car
        clc
        adc #128            ;add 180 deg
        sta _ycarclashangle ;set angle in which direction yellow car is pushed by blue car (the opposite direction)

        ;calculate how much blue car is pushed by yellow car
        lda _ycarspeed
        lsr
        lsr                     ;skip fraction
        tax                     ;yellow car speed in .X
        lda .collisionangle
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
        lda .collisionangle
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
        lda .absydist_lo
        sta .tableadr
        stz .tableadr+1
        +MultiplyBy32 .tableadr
        lda .absxdist_lo
        clc
        adc .tableadr
        sta .tableadr
        lda .tableadr+1
        adc #0
        sta .tableadr+1
        lda #<_atantable
        clc
        adc .tableadr
        sta .tableadr
        lda #>_atantable
        adc .tableadr+1
        sta .tableadr+1
        lda (.tableadr)
        sta .collisionangle

        lda .xdist_lo
        bpl +
        lda #128                ;if x<0
        sec
        sbc .collisionangle
        sta .collisionangle
+       lda .ydist_lo    
        bmi +                   ;turn y-axis upside down by using bmi instead of bpl.
        lda #0                  ;if y<0
        sec
        sbc .collisionangle
        sta .collisionangle
+       rts