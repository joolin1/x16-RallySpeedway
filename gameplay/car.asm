;*** Car.asm - Class definition ********************************************************************

;This file works as a class definition. Therefore every label is local. An instance of the class is made by including this source file
;in another file and then map the public funtions here to global instance specific labels.
;By including the file, all variables will be added once for every instance. The drawback is that the code is will as well (like a macro). 

;Car properties
.speed                  !byte 0         ;fixed point 6.2. 256 = 64.0 = theoretical max speed (+1)
.angle                  !byte 0         ;fixed point 6.2. 256 = 64.0 = 360 deg
.skidangle              !byte 0         ;angle for skidding, car turns left -> angle 90 degrees less than angle for direction, car turns right -> angle 90 degrees more
.plusangle              !byte 0         ;fixed point 6.2. Extra rotation for skidding car
.displayangle           !byte 0         ;fixed point 6.2. The actual angle car is rendered in, will equal .angle when not skidding
.turncount              !byte 0         ;how long car has been turning. high value means steep turn which will cause car to skid
.turndirection          !byte 0         ;current direction car is turning, 1 = left turn, 0 = right turn
.clashpush              !byte 0         ;the force car is pushed by the other car when clashing
.clashangle             !byte 0         ;direction car is pushed by the other car when clashing
.xpos_lo                !byte 0         ;current position in game world, a fixed point number 12.4 (0-4095) 
.xpos_hi                !byte 0
.ypos_lo                !byte 0
.ypos_hi                !byte 0
.xpos_lo_int            !byte 0         ;integer value of car position
.xpos_hi_int            !byte 0
.ypos_lo_int            !byte 0
.ypos_hi_int            !byte 0
.xstartoffset           !byte 0         ;distance from middle of block when positioned for start
.ystartoffset           !byte 0
.offroadflag            !byte 0         ;flag for offroad driving
.collisionflag          !byte 0         ;flag for collision between car and background

;Route variables
.block_xpos             !byte 0         ;current position in block map
.block_ypos             !byte 0
.old_block_xpos         !byte 0         ;former position in block map
.old_block_ypos         !byte 0
.checkpoint_xpos        !byte 0         ;current checkpoint in block map (used when resuming race after collision and outdistancing)
.checkpoint_ypos        !byte 0
.checkpointdirection    !byte 0         ;current direction for checkpoint
.block                  !byte 0         ;current type of block according to block map
.routedirection         !byte 0         ;current direction of route according to route map
.distance               !byte 0         ;distance since last checkpoint
.penaltycount           !byte 0         ;how many times the car has got a time penalty
.collisioncount         !byte 0         ;how many times the cas has collided/crashed
.finishflag             !byte 0         ;flag for finished race

;*** Public functions ******************************************************************************

.Show:
        +VPokeI .SPR_ATTR_0,COLLISION_MASK+8            ;enable sprite 
        +VPokeI .SPR_ATTR_1, %10100000 + .CAR_PALETTE   ;set palette 1 for yellow car and palette 2 for blue car
        rts

.Hide:
        +VPokeI .SPR_ATTR_0,0    ;disable sprite
        rts

.ReactOnPlayerInput:
        lda .joy
        bit #JOY_LEFT
        bne +
        jsr .TurnLeft
        bra ++
+       bit #JOY_RIGHT
        bne +
        jsr .TurnRight
        bra ++

+       stz .turncount          ;car is not turning anymore

++
        lda .joy                ;DEBUG
        and #JOY_BUTTON_B                 
        bne +
        lda #1
        sta _debug              ;END DEBUG

+       lda .finishflag         
        beq +
        jsr .StopCar            ;car has finished race, stop by slowing down to speed 0
        rts

+       lda .joy
        and #JOY_BUTTON_A       ;button A?
        bne +
        jsr .DecreaseSpeed      ;car is braking - slow down
        rts

+       lda .offroadflag
        beq +
        jsr .DecreaseSpeed      ;car is off road - slow down
        rts

+       lda .turncount      
        cmp #SKID_LIMIT         ;is car turning so fast that it will skid?
        bcc +                   ;no, increase speed
        jsr .DecreaseSpeed      ;yes, slow down
        rts                     
+       jsr .IncreaseSpeed      ;not braking, not offroad, not skidding -> increase speed
        rts

.StartRace:                     ;Start new race
        jsr .TimeReset
        stz .penaltycount
        stz .collisioncount
        stz .finishflag
        stz .distance
        lda _xstartblock
        sta .checkpoint_xpos
        lda _ystartblock
        sta .checkpoint_ypos
        lda _startdirection
        sta .checkpointdirection
        jsr .InitRace
        rts

.ResumeRace:                    
        jsr .InitRace        
        rts

.InitRace:                      ;initialization that both new and resumed races share
        stz .speed
        lda .checkpointdirection
        sta .angle
        sta .displayangle
        stz .skidangle
        stz .plusangle
        stz .turncount
        stz .clashpush
        stz .clashangle
        stz .offroadflag

        ;set start block and init block history
        lda .checkpoint_xpos
        sta .block_xpos
        sta .old_block_xpos
        lda .checkpoint_ypos
        sta .block_ypos
        sta .old_block_ypos

        ;decide where to put car/cars in startblock
        lda _noofplayers
        cmp #1
        bne +
        ldx #64                 ;if one player center the only car
        bra ++        
+       lda #.ID                ;if two players position cars side by side
        beq +
        ldx #64+CAR_START_DISTANCE/2
        bra ++
+       ldx #64-CAR_START_DISTANCE/2
++      lda .checkpointdirection
        bit #64                 ;start direction horizontal or vertical?
        beq +
        stx .xstartoffset
        ldx #64
        stx .ystartoffset
        bra ++
+       stx .ystartoffset
        ldx #64
        stx .xstartoffset

        ;position car in start block
++      stz .xpos_lo
        lda .checkpoint_xpos
        sta .xpos_hi
        lsr .xpos_hi            ;start block in high byte divided by 2 = 128 * block.        
        ror .xpos_lo
        lda .xpos_lo
        clc 
        adc .xstartoffset       ;add 64 (a half block) to center car
        sta .xpos_lo
        lda .xpos_hi
        adc #0
        sta .xpos_hi
        +MultiplyBy16 .xpos_lo  ;fixed point 12.4. Upper 12 bits represent the integer part

        stz .ypos_lo
        lda .checkpoint_ypos
        sta .ypos_hi
        lsr .ypos_hi
        ror .ypos_lo
        lda .ypos_lo
        clc
        adc .ystartoffset
        sta .ypos_lo
        lda .ypos_hi
        adc #0
        sta .ypos_hi
        +MultiplyBy16 .ypos_lo

        jsr .PlayEngineSound
        jsr .UpdateCarProperties
        jsr .UpdateRouteInformation     ;explicitly call this routine here, it is otherwise only called when car is entering a new block        
        rts

.CarTick:                       ;advance one jiffy, calculate new positions of cars according to speed and direction
        jsr .TimeTick           ;add a jiffy to the timer
        jsr .ReactOnPlayerInput
        lda .speed              
        lsr
        lsr                     ;skip fraction, speed is fixed point 6.2
        bne +
        rts
+       jsr .UpdateCarPosition
        jsr .UpdateCarProperties
        jsr .UpdateTileInformation
        rts

.UpdateCarPosition:
        ;Move car
        tax                     ;speed in .X
        lda .angle              ;angle in .A       
        jsr .Move               ;move car in current direction

        ;Push car if colliding with the other
        lda .clashpush
        lsr       
        lsr
        beq +
        tax                     ;speed in .X
        lda .clashangle         ;angle in .A
        jsr .Move
        dec .clashpush

        ;Skid car
+       lda .turncount
        cmp #SKID_LIMIT         ;fixed point 6.2
        bmi ++                  ;do not skid if turn is less than skid limit

        lda .speed
        lsr                     ;skip fraction, skid ratio is fixed point 6.2
        lsr                     ;skidding in direct proportion to speed.
        lsr
        bne +
        lda #1                  ;min value = 1
+       tax                     ;skid amount in .X
        lda .skidangle          ;angle in .A
        jsr .Move               ;skid cars outwards when turning      

        ;Calculate display angle for car depending on skidding
        lda .turncount
        cmp #SKID_LIMIT             ;don't increase extra rotation if car is not skidding
        bcc ++    
        jsr .IncreaseExtraRotation
        jsr .PlaySkiddingSound
        bra +++
++      jsr .DecreaseExtraRotation
        jsr .StopSkiddingSound
+++     lda .angle                  ;add extra rotation to direction car is moving
        clc
        adc .plusangle             
        sta .displayangle
        rts

.UpdateCarProperties:
        ;update integer value of car position
        lda .xpos_lo
        clc
        adc #8                          ;add 8 = 0.5 to round the number instead of truncating it                          
        sta .xpos_lo_int
        lda .xpos_hi
        adc #0
        sta .xpos_hi_int
        lda .ypos_lo
        clc
        adc #8                          ;see comment above
        sta .ypos_lo_int
        lda .ypos_hi
        adc #0
        sta .ypos_hi_int
        +DivideBy16 .xpos_lo_int        ;divide by 16 to convert 16 bit fixed point to 12 bit integer
        +DivideBy16 .ypos_lo_int

        ;update block position
        lda .xpos_lo_int
        asl
        lda .xpos_hi_int
        rol                     ;convert car x position (0-4095) to block x position (0-31)     
        and #31
        sta .block_xpos

        lda .ypos_lo_int
        asl
        lda .ypos_hi_int
        rol                     ;convert car y position (0-4095) to block y position (0-31)     
        and #31
        sta .block_ypos
   
        ;update route information if car entered a new block...
        lda .block_xpos
        cmp .old_block_xpos
        bne .UpdateRouteInformation
        rts
+       lda .block_ypos
        cmp .old_block_ypos
        bne .UpdateRouteInformation
        rts
        
.UpdateRouteInformation:
        inc .distance           ;always update distance, it doesn't matter if car is driving offroad
        lda .block_xpos         ;update block route history           
        sta .old_block_xpos
        lda .block_ypos
        sta .old_block_ypos
        +GetElementInArray _blockmap_lo, 5, .block_ypos, .block_xpos    ;get current block type
        lda (ZP0)
        sta .block
        +GetElementInArray _route_lo, 5, .block_ypos, .block_xpos       ;get direction that current block is leading to
        lda (ZP0)
        sta .routedirection
        cmp #ROUTE_OFFROAD
        beq +
        lda .block
        cmp #BLOCK_EW_STARTFINISH
        beq +
        cmp #BLOCK_NS_STARTFINISH
        beq +
        sta .checkpointdirection        ;if car is on road AND road is part of route AND not finish block, then update checkpoint information
        lda .block_xpos
        sta .checkpoint_xpos
        lda .block_ypos
        sta .checkpoint_ypos
+       rts

.UpdateSprite:
        ;update which car sprite to show
        lda .displayangle           ;update car sprite to point in right direction, a skidding car will be rotated some extra degrees        
        lsr                         ;get rid of fraction
        lsr
        tay
        lda _anglespritetable,y
        sta ZP0
        stz ZP1
        +MultiplyBy16 ZP0           ;multiply with 16 to get actual offset
        lda ZP0
        +VPoke .SPR_ADDR_L       
        lda ZP1
        clc
        adc #$04                    ;add base address of sprites (sprite 1 located at $8000 and $8000/32=$400)
        +VPoke .SPR_MODE_ADDR_H
        lda .displayangle           ;flip sprite if necessary
        lsr                         ;get rid of fraction
        lsr             
        tay                                          
        lda _anglefliptable,y
        ora #8                      ;don't forget to set bit 4 to keep a z depth of 2 (= between layers)
        +VPoke .SPR_ATTR_0
        rts

.UpdateTileInformation:

        ;1 - get address of current block
        lda .block              ;load block index from block map
        stz ZP0
        lsr                     ;interpret block index as the high byte, that means index * 256, shift right to get index * 128 which gives the address of the block
        sta ZP1                 ;store high byte result
        ror ZP0                 ;now ZP0 and ZP1 = block index * 128
        lda ZP0                         
        clc             
        adc #<_blocks           ;add base address
        sta ZP0
        lda ZP1
        adc #>_blocks
        sta ZP1                 ;now ZP0 and ZP1 = address of current block
      
        ;2 - get which tile in block the car is located in
        lda .xpos_lo_int
        and #127                ;block is 128 pixels wide
        lsr
        lsr
        lsr
        lsr                     ;divide by 16 because tiles are 16 pixels wide
        asl                     ;muliply by 2 because every tile takes 2 bytes in block definition.       
        clc
        adc ZP0
        sta ZP0
        lda ZP1
        adc #0                  ;now ZP0 and ZP1 = address of current block + tile x offset
        sta ZP1

        lda .ypos_lo_int
        and #112                ;keep bit 4-6 = keep bit 0-6 divide by 16 (tiles are 16 pixels high) and multiply by 16 because a row in a block definition is 16 bytes     
        clc
        adc ZP0
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1                 ;now ZP0 and ZP1 = address of current block + tile x offset + tile y offset
        lda (ZP0)               ;load current tile

        ;3 - check collision status
        tay
        lda _tilecollisionstatus,y      ;read collision status for current tile

        cmp #TILE_ROAD
        bne +
        stz .offroadflag                ;car is on road
        rts

+       cmp #TILE_TERRAIN
        bne +
        lda #1                          
        sta .offroadflag                ;car is off road
        rts

+       cmp #TILE_FINISH
        bne +
        jsr .CheckDirection             ;check if car has crossed the finish line from the right direction
        sta .finishflag                 ;car has finished race!
        rts

+       cmp #TILE_OBSTACLE
        beq +
        rts
+       lda #ST_COLLISION               ;car has collided
        sta _gamestatus
        lda #1
        sta .collisionflag
        lda .finishflag
        beq +
        stz .speed                      ;car has collided but has also finished the race, in this case ignore collision and just abruptly set speed to 0
        rts
+       inc .collisioncount             ;count number of collisions
        jsr StopCarSounds
        jsr PlayExplosionSound
        rts
                          
.CheckDirection:                        ;OUT: .A = true (1) if car has crossed the finish line in the right direction, false otherwise
        !byte $ff
        lda .angle
        ldx .routedirection

        cpx #ROUTE_OFFROAD
        bne +
        lda #0          ;return false if there against all odds is another finish line that is not part of the route that the car has crossed. 
        rts

        ;adjust angle depending on route direction. If route goes east, car should cross finish line with 192 < angle < 64.
        ;if this case we add 64 so we then can check if 0 < result < 128    
+       cpx #ROUTE_EAST
        bne +
        clc
        adc #64
        bra ++       
+       cmp #ROUTE_WEST
        bne +
        sec
        sbc #64
        bra ++
+       cmp #ROUTE_SOUTH
        bne +
        clc
        adc #128
+       ;(if north, do nothing)

++      cmp #128
        bcc +
        lda #0
        rts
+       cmp #1
        bcs +
        lda #0
        rts
+       lda #1          ;return true because angle 0 < angle < 128
        rts

.Explode:
        lda .collisionflag
        bne +
        rts
+       lda .animationindex             ;load current animation index
        cmp #12                         ;12 sprites in explosion animation
        beq ++    

        clc
        adc #17                         ;add offset, first sprite in animation is no 17
        sta ZP0
        stz ZP1
        +MultiplyBy16 ZP0               ;multiply with 16 to get actual offset
        lda ZP1                         ;add sprite base address = $8000 ($8000/32 = $400)
        clc
        adc #$04
        sta ZP1                       
        lda ZP0                         ;set low address of next sprite in animation
        +VPoke .SPR_ADDR_L
        lda ZP1                         ;set high address of next sprite in animation
        +VPoke .SPR_MODE_ADDR_H
        lda #%10100000
        +VPoke .SPR_ATTR_1              ;set palette offset to 0 (explosion colors)
        inc .animationdelay              ;wait a certain amount of interrupt calls before advancing frame
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
        lda #ST_RESUMERACE
        sta _gamestatus
        stz .collisionflag
        lda #COLLISION_TIME             ;add extra time for the colliding car
        jsr .TimeAddSeconds
        rts

.animationindex !byte 0         ;current sprite in explosion animation
.animationdelay !byte 0         ;delay counter to slow down animation 

;Private functions *************************************************************

.Move:                          ;IN: .A = angle, .X = speed. Move car in given direction.
        lsr
        lsr                     ;skip fraction, angle is fixed point 6.2
        asl                     ;multiply by two to get right offset for sin and cos values (16 bit words)
        tay
-       lda .xpos_lo 
        clc 
        adc _anglecos,y         ;add cosine value represented by a 4 bit fraction
        sta .xpos_lo
        lda .xpos_hi
        adc _anglecos+1,y
        sta .xpos_hi
        lda .ypos_lo 
        sec
        sbc _anglesin,y         ;add sine value represented by a 4 bit fraction
        sta .ypos_lo
        lda .ypos_hi
        sbc _anglesin+1,y
        sta .ypos_hi
        dex
        bne -
        rts

.IncreaseExtraRotation:
        lda .turndirection
        beq +

        lda .plusangle              
        cmp #MAX_EXTRA_ROTATION
        beq ++
        inc .plusangle          ;increase rotation to the left when turning left and skidding
        inc .plusangle
        rts

+       lda .plusangle
        cmp #-MAX_EXTRA_ROTATION
        beq ++
        dec .plusangle          ;increase rotation to the right when turning right and skidding
        dec .plusangle
++      rts

.DecreaseExtraRotation:
        lda .turndirection
        beq +

        lda .plusangle
        beq ++
        dec .plusangle          ;decrease rotation to the left when turning left and not skidding
        dec .plusangle
        rts

+       lda .plusangle
        beq ++
        inc .plusangle          ;decrease rotation to the right when turning right and not skidding
        inc .plusangle
++      rts

.IncreaseSpeed:

        ldx .speed
        lda .offroadflag
        beq +
        cpx #MIN_SPEED
        bcc ++
        rts
+       cpx #MAX_SPEED
        bcc ++
        rts
++      inc .speeddelay
        lda .speeddelay
        cmp #SPEED_DELAY
        bcc +
        stz .speeddelay        
        inc .speed              ;fixed 6.2, 24 = 6.0
+       rts

.speeddelay     !byte 0

.DecreaseSpeed:
        inc .brakedelay
        lda .brakedelay
        cmp #BRAKE_DELAY
        bne +
        stz .brakedelay
        lda .speed              ;fixed 6.2, 14 = 3.5
        cmp #MIN_SPEED
        beq +
        bcc +
        dec
        sta .speed
+       rts

.StopCar:
        inc .brakedelay
        lda .brakedelay
        cmp #BRAKE_DELAY
        bne +
        stz .brakedelay

        lda .speed
        beq +
        dec
        sta .speed
        beq +
        dec
        sta .speed       
+       rts

.brakedelay     !byte 0

.TurnLeft:
        sta .turndirection      ;flag that car is turning left
        lda .speed
        bne +
        rts

+       lda .angle              ;fixed 6.2, 256 = 64.0 = 360 deg
        inc
        inc                     ;increase angle for car
        sta .angle
        sec
        sbc #64                 ;subtract 90 degrees
        sta .skidangle
        lda #1
        bra .IncreaseTurnCount

.TurnRight:
        stz .turndirection      ;flag that car is turning right
        lda .speed
        bne +
        rts

+       lda .angle              ;fixed 6.2, 256 = 64.0 = 360 deg
        dec
        dec
        sta .angle
        clc
        adc #64                 ;add 90 degrees
        sta .skidangle

.IncreaseTurnCount:
        lda .turncount          ;count how long user is turning
        cmp #128                ;fixed 6.2, 128 = 32.0 = 180 degrees
        beq +
        inc .turncount 
        inc .turncount 
+       rts