;*** interaction.asm - when a car outdistances the other or cars collide with each other ***********

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

_winner         !byte   0       ;winner of race (0 = no winner yet, 1 = yellow car has won, 2 = blue car has won, 3 = race ended in a draw)
_isrecord       !byte   0       ;whether winner time is a new record

InitCarInteraction:
        stz _isrecord
        stz _winner
        rts

CheckIfRaceOver:                       ;check if race over (= cars have crossed finish line and stopped)
        lda _ycarfinishflag
        beq ++
        lda _ycarspeed
        bne ++
        lda _noofplayers
        cmp #1
        bne +
        lda #1
        sta _winner             ;yellow car always wins when one player...
        lda #ST_FINISH
        sta _gamestatus
        rts
+       lda _bcarfinishflag
        beq ++
        lda _bcarspeed
        bne ++
        jsr .SetWinner
        lda #ST_FINISH
        sta _gamestatus
++      rts   

.SetWinner:
        +SetParams _ycartime, _ycartime+1, _ycartime+2, _bcartime, _bcartime+1, _bcartime+2
        jsr AreTimesEqual
        bne +
        lda #3
        sta _winner     ;race ended in a draw
        rts
+       jsr IsTimeLess
        bcc +
        lda #1
        sta _winner
        rts
+       lda #2
        sta _winner
        rts

CheckForRecord:
        jsr .SetWinnerParams
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

SetStartPosition:                                       ;if two players, set new start position after collision or outdistancing
        lda _noofplayers
        cmp #1
        bne +
        rts
+       lda _winner
        cmp #1
        bne +
        jsr .SetStartToYellowCarCheckpoint              ;if yellow car has won, its last checkpoint will be used. this will be just before the finish.
        rts
+       cmp #2
        bne +
        jsr .SetStartPositionToBlueCarCheckpoint        ;if blue car has won, its last checkpoint will be used. this will be just before the finish.
        rts
+       +Cmp16 _ycardistance_lo, _bcardistance_lo       ;set startpoint to the last checkpoint for the car which has driven the longest distance
        bcc +
        jsr .SetStartToYellowCarCheckpoint
        rts
+       jsr .SetStartPositionToBlueCarCheckpoint
        rts

.SetStartToYellowCarCheckpoint:
        lda _ycar_checkpoint_xpos                       ;set startpoint to checkpoint of yellow car
        sta _bcar_checkpoint_xpos
        lda _ycar_checkpoint_ypos
        sta _bcar_checkpoint_ypos
        lda _ycar_checkpoint_direction
        sta _bcar_checkpoint_direction
        lda _ycardistance_lo                            ;also set same distance, it's get more competitive if distances do not differ too much :)
        sta _bcardistance_lo
        lda _ycardistance_lo+1
        sta _bcardistance_lo+1
        rts

.SetStartPositionToBlueCarCheckpoint:
        lda _bcar_checkpoint_xpos                       ;set startpoint to checkpoint of blue car
        sta _ycar_checkpoint_xpos
        lda _bcar_checkpoint_ypos
        sta _ycar_checkpoint_ypos
        lda _bcar_checkpoint_direction
        sta _ycar_checkpoint_direction
        lda _bcardistance_lo                            ;also set same distance, it's get more competitive if distances do not differ too much :)
        sta _ycardistance_lo
        lda _bcardistance_lo+1
        sta _ycardistance_lo+1
        rts

!macro CalculateDistance .ycarpos_lo, .bcarpos_lo, .dist_lo, .absdist_lo {

        ;calculate vertical distance
        +Sub16 .bcarpos_lo, .ycarpos_lo       ;bcar pos - ycar pos
        stx .dist_lo
        sty .dist_lo+1
        +Cmp16  .ycarpos_lo, .bcarpos_lo      
        bcs +

        ;bcar pos > ycar pos        
        lda .dist_lo+1
        bit #8                  ;if distance > 2048 cars are closer if we see them as positioned on different maps
        beq ++
        ora #240                ;result has wrapped correctly if we look att 12 bits, now simply extend negative value to 16 bit
        sta .dist_lo+1          
        bra ++

        ;ycar pos > bcar pos
+       lda .dist_lo+1
        bit #8                  ;if distance < -2048 cars are closer if we see them as positioned on different maps
        bne ++
        and #15                 ;result has wrapped correctly if we look att 12 bits, now simply extend negative value to 16 bit
        sta .dist_lo+1

++      lda .dist_lo
        sta .absdist_lo
        lda .dist_lo+1
        sta .absdist_lo+1
        +Abs16 .absdist_lo     ;get absolute values
}

CheckInteraction:
        +CalculateDistance _ycarxpos_lo, _bcarxpos_lo, .xdist_lo, .absxdist_lo
        +CalculateDistance _ycarypos_lo, _bcarypos_lo, .ydist_lo, .absydist_lo  

        ;check for horizontal outdistancing
+       lda .absxdist_lo
        cmp #44                         ;low byte must be 44 or higher
        bcc +
        lda .absxdist_hi
        cmp #1                          ;high byte must be 1 (1 * 256 + 44 = 300)
        beq SetOutdistanced                   

        ;check for vertical outdistancing
+       lda .absydist_lo
        cmp #220                        ;low byte must be 220 or higher (high byte is irrelevant)
        bcs SetOutdistanced
        rts

SetOutdistanced:                        ;if one car is outdistanced - decide which and set new game status                                  
        jsr StopCarSounds
        jsr PlayOutrunSound
        lda #ST_OUTDISTANCED
        sta _gamestatus
        
        lda _winner
        bne +++                         ;if one car has won no outdistancing can occur, the other car will always be considered off road

        ;set info about if cars are driving off road or not
        stz .outdistancetemp
        lda _ycar_routedirection
        cmp #ROUTE_OFFROAD
        bne +
        lda #1
        sta .outdistancetemp
+       lda _bcar_routedirection
        cmp #ROUTE_OFFROAD
        bne +
        lda #2 
        ora .outdistancetemp
        sta .outdistancetemp

        ;use info to decide which car is outdistanced of if both will have a penalty
+       lda .outdistancetemp
        cmp #1
        beq +                                   ;yellow car is off route while blue is on route which means yellow car is outdistanced 
        cmp #2
        beq ++                                  ;blue car is off route while blue is on route which means blue car is outdistanced
        cmp #3
        beq +++                                 ;both cars are off route, both cars will pay a penalty
        +Cmp16 _ycardistance_lo, _bcardistance_lo
        bcs ++                                  ;both cars are on route but yellow car has driven a longer (or equal) distance than the blue car

        ;yellow car has been outdistanced
+       lda #0
        jsr ShowPenaltyText
        lda #PENALTY_TIME
        jsr YCar_TimeAddSeconds
        inc _ycarpenaltycount
        rts        

        ;blue car has been outdistanced
++      lda #1
        jsr ShowPenaltyText
        lda #PENALTY_TIME
        jsr BCar_TimeAddSeconds
        inc _bcarpenaltycount
        rts

+++     ;both cars are off route (no penalty)
        jsr ShowOffroadText
        rts

.outdistancetemp         !byte 0

SetClash:
        jsr PlayClashSound      
        ;calculate collision angle
        jsr GetClashAngle
        lda .collisionangle        
        sta _bcarclashangle     ;set angle in which direction blue car is pushed by yellow car
        clc
        adc #128                ;add 180 deg
        sta _ycarclashangle     ;set angle in which direction yellow car is pushed by blue car (the opposite direction)

        ;calculate how much blue car is pushed by yellow car
        lda _ycarspeed
        lsr
        lsr                     ;skip fraction
        tax                     ;yellow car speed in .X
        lda _bcarclashangle
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
        sta ZP0
        lsr
        clc
        adc ZP0                 ;add 50% extra push just to make a better game and make sure cars are not left above each other
        cmp #4
        bcs +
        lda #4
+       sta _bcarclashpush

        ;calculate how much yellow car is pushed by blue car
++      lda _bcarspeed
        lsr
        lsr                     ;skip fraction
        tax                     ;blue car speed in .X
        lda _ycarclashangle
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
        sta ZP0
        lsr 
        clc
        adc ZP0                 ;add 50% extra push just to make a better game and make sure cars are not left above each other
        cmp #4
        bcs +
        lda #4        
+       sta _ycarclashpush
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

SetTrafficClash:                ;IN: .A = car that has collided with traffic. 0 = yellow car, 1 = blue car
        sta .collidingcarflag
        jsr GetCollidingTrafficCarRelativePosition
        jsr GetClashAngle
        lda .collisionangle        
        clc
        adc #128                ;add 180 deg
        sta .tclashangle         ;set angle in which direction race car is pushed by traffic car (the opposite direction)

        ;calculate how much race car is pushed by traffic car
        lda #TRAFFIC_SPEED
        lsr
        lsr                     ;skip fraction
        tax                     ;traffic car speed in .X
        lda .tclashangle
        sec
        sbc .tcarangle          ;difference between collision angle and movement angle is needed to calculate in which speed traffic car is moving against race car
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
        lda #8
        sta .rcarclashpush      ;if traffic car actually is moving away just set a small standard value
        bra ++
+       lsr                     ;convert from fixed point 4.4 to fixed point 6.2
        lsr                     
        sta ZP0
        lsr 
        clc
        adc ZP0                 ;add 50% extra push just to make a better game and make sure cars are not left above each other
        cmp #8
        bcs +
        lda #8        
+       sta .rcarclashpush

++      jsr PlayClashSound

        lda .collidingcarflag
        bne +
        lda .tclashangle
        sta _ycarclashangle
        lda .rcarclashpush
        sta _ycarclashpush
        lda #MIN_SPEED
        sta _ycarspeed
        rts
+       lda .tclashangle
        sta _bcarclashangle
        lda .rcarclashpush
        sta _bcarclashpush
        lda #MIN_SPEED
        sta _bcarspeed
        rts      

.collidingcarflag       !byte 0 ;which race car that has collided with traffic car
.tclashangle            !byte 0 ;direction race car is pushed by traffic car
.tcarangle              !byte 0 ;direction traffic car is moving
.rcarclashpush          !byte 0 ;how much race car is pushed by traffic car

GetCollidingTrafficCarRelativePosition:         ;IN: .A = flag, 0 = yellow car, 1 = blue car, OUT: distance variables will be set
        ldx _car0_xpos_lo
        stx ZP10
        ldx _car0_xpos_hi
        stx ZP11
        ldy _car0_ypos_lo
        sty ZP12
        ldy _car0_ypos_hi
        sty ZP13        
        jsr CalculateDistanceToTrafficCar
        +Cmp16 .absxdist_lo, 32, 0 ;x distance < 32 (sprite width and height is 32)
        bcs +
        +Cmp16 .absydist_lo, 32, 0 ;y distance < 32
        bcs +
        lda _car0_angle
        sta .tcarangle
        rts

+       ldx _car1_xpos_lo
        stx ZP10
        ldx _car1_xpos_hi
        stx ZP11
        ldy _car1_ypos_lo
        sty ZP12
        ldy _car1_ypos_hi
        sty ZP13        
        jsr CalculateDistanceToTrafficCar
        +Cmp16 .absxdist_lo, 32, 0
        bcs +
        +Cmp16 .absydist_lo, 32, 0
        bcs +
        lda _car1_angle
        sta .tcarangle
        rts

+       ldx _car2_xpos_lo
        stx ZP10
        ldx _car2_xpos_hi
        stx ZP11
        ldy _car2_ypos_lo
        sty ZP12
        ldy _car2_ypos_hi
        sty ZP13        
        jsr CalculateDistanceToTrafficCar
        +Cmp16 .absxdist_lo, 32, 0
        bcs +
        +Cmp16 .absydist_lo, 32, 0
        bcs +
        lda _car2_angle
        sta .tcarangle
        rts

+       ldx _car3_xpos_lo
        stx ZP10
        ldx _car3_xpos_hi
        stx ZP11
        ldy _car3_ypos_lo
        sty ZP12
        ldy _car3_ypos_hi
        sty ZP13        
        jsr CalculateDistanceToTrafficCar
        +Cmp16 .absxdist_lo, 32, 0
        bcs +
        +Cmp16 .absydist_lo, 32, 0
        bcs +
        lda _car3_angle
        sta .tcarangle
        rts

+       ldx _car4_xpos_lo
        stx ZP10
        ldx _car4_xpos_hi
        stx ZP11
        ldy _car4_ypos_lo
        sty ZP12
        ldy _car4_ypos_hi
        sty ZP13        
        jsr CalculateDistanceToTrafficCar
        +Cmp16 .absxdist_lo, 32, 0
        bcs +
        +Cmp16 .absydist_lo, 32, 0
        bcs +
        lda _car4_angle
        sta .tcarangle
        rts

+       ldx _car5_xpos_lo
        stx ZP10
        ldx _car5_xpos_hi
        stx ZP11
        ldy _car5_ypos_lo
        sty ZP12
        ldy _car5_ypos_hi
        sty ZP13        
        jsr CalculateDistanceToTrafficCar
        +Cmp16 .absxdist_lo, 32, 0
        bcs +
        +Cmp16 .absydist_lo, 32, 0
        bcs +
        lda _car5_angle
        sta .tcarangle
        rts

+       ldx _car6_xpos_lo
        stx ZP10
        ldx _car6_xpos_hi
        stx ZP11
        ldy _car6_ypos_lo
        sty ZP12
        ldy _car6_ypos_hi
        sty ZP13        
        jsr CalculateDistanceToTrafficCar
        +Cmp16 .absxdist_lo, 32, 0
        bcs +
        +Cmp16 .absydist_lo, 32, 0
        bcs +
        lda _car6_angle
        sta .tcarangle
        rts

+       ldx _car7_xpos_lo
        stx ZP10
        ldx _car7_xpos_hi
        stx ZP11
        ldy _car7_ypos_lo
        sty ZP12
        ldy _car7_ypos_hi
        sty ZP13        
        jsr CalculateDistanceToTrafficCar
        lda _car7_angle
        sta .tcarangle
        rts

CalculateDistanceToTrafficCar:  ;IN: ZP10, ZP11 = xpos of traffic car, ZP12, ZP13 = ypos of traffic car
                                ;OUT: distance variables will be set
        lda .collidingcarflag
        beq +
        jmp ++
+       +CalculateDistance _ycarxpos_lo, ZP10, .xdist_lo, .absxdist_lo
        +CalculateDistance _ycarypos_lo, ZP12, .ydist_lo, .absydist_lo
        rts
++      +CalculateDistance _bcarxpos_lo, ZP10, .xdist_lo, .absxdist_lo
        +CalculateDistance _bcarypos_lo, ZP12, .ydist_lo, .absydist_lo
        rts