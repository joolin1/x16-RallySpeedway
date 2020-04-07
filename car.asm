;*** Car.asm - Class definition ********************************************************************

;This file works as a class definition. Therefore every label is local. An instance of the class is made by including this source file
;in another file and then map the public funtions here to global instance specifig labels.
;By including the file, all variables will be added once for every instance. The drawback is that the code is also duplicated. 

;*** Public functions ******************************************************************************

.Show:
        +VPokeI .SPR_ATTR_0,COLLISION_MASK+8     ;enable sprite 
        lda #.ID
        bne +
        +VPokeI .SPR_ATTR_1, %10100001   ;set palette offset to 1 (yellow car colors) when car explodes palette 0 is used
        rts
+       +VPokeI .SPR_ATTR_1, %10100010   ;set palette offset to 2 (blue car colors)
        rts

.Hide:
        +VPokeI .SPR_ATTR_0,0    ;disable sprite
        jsr .StopCarSound
        rts

.ReactOnPlayerInput:
        lda .joy
        pha
        and #3
        cmp #1                  ;left?
        bne +
        jsr .TurnLeft
        bra ++

+       cmp #2                  ;right?
        bne +
        jsr .TurnRight
        bra ++

+       stz .turncount          ;car is not turning anymore

++
        pla                     ;DEBUG
        pha                    
        and #64                 
        bne +
        lda #1
        sta _debug              ;END DEBUG
+       pla
        and #128                ;button A?
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

.Init:
        stz .distance
        stz .speed
        lda _startdirection
        sta .angle
        sta .displayangle
        stz .skidangle
        stz .plusangle
        stz .turncount
        stz .clashpush
        stz .clashangle

        lda _noofplayers
        cmp #1
        bne +
        lda #64                 ;if one player center the only car
        bra ++        
+       lda #.ID                ;if two players position cars side by side
        beq +
        ldx #64+CAR_START_DISTANCE/2
        bra ++
+       ldx #64-CAR_START_DISTANCE/2
++      lda _startdirection
        bit #64
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
        lda _xstartblock
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
        lda _ystartblock
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

        lda _xstartblock        ;current position and former positions are simply set to start position when race is about to begin
        sta .block_xpos
        sta .old_block_xpos
        sta .older_block_xpos
        lda _ystartblock
        sta .block_ypos
        sta .old_block_ypos
        sta .older_block_ypos

        jsr .StartEngineSound
        jsr .UpdatePosition        
        rts

.xstartoffset   !byte 0
.ystartoffset   !byte 0

.UpdatePosition:                ;calculate new positions of cars according to speed and direction
        lda .speed              
        lsr
        lsr                     ;skip fraction, speed is fixed point 6.2
        beq .UpdateCarProperties ;nothing to do if speed is 0

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
        bmi +                   ;do not skid if turn is less than skid limit

        lda .speed
        lsr                     ;skip fraction, skid ratio is fixed point 6.2
        lsr                     ;skidding in direct proportion to speed.
        lsr
        tax                     ;skid amount in .X
        lda .skidangle          ;angle in .A
        jsr .Move               ;skid cars outwards when turning      

        ;Calculate display angle for car depending on skidding
        lda .turncount
        cmp #SKID_LIMIT             ;don't increase extra rotation if car is not skidding
        bcc +    
        jsr .IncreaseExtraRotation
        jsr .StartSkiddingSound
        bra ++
+       jsr .DecreaseExtraRotation
        jsr .StopSkiddingSound
++      lda .angle                  ;add extra rotation to direction car is moving
        clc
        adc .plusangle             
        sta .displayangle        

        jsr .UpdateCarProperties 
        rts

.UpdateCarProperties:

        jsr .TimeTick               ;add a jiffy to the timer
        lda .speed
        jsr .UpdateEngineSound      ;change engine sound depending on speed   

        ;update integer value of cars position
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

        ;update block position, save two last blocks
        lda .old_block_xpos
        sta .older_block_xpos
        lda .old_block_ypos
        sta .older_block_ypos
        lda .block_xpos
        sta .old_block_xpos
        lda .block_ypos
        sta .old_block_ypos

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

        ;update current block
        sta ZP0
        stz ZP1
        +MultiplyBy32 ZP0       ;y pos * 32               

        lda .block_xpos      
        clc
        adc ZP0                 ;add x pos
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1
        
        lda ZP0                 ;add base address
        clc
        adc #<_blockmap
        sta ZP0
        lda ZP1
        adc #>_blockmap                  
        sta ZP1                 ;now ZP0 and ZP1 = address in block map where to read current block
        lda (ZP0)               ;load current block
        sta .block

        ;update distance
        tay
        lda _blockroadstatus,y  ;see if block is terrain or road
        bne +
        rts                     ;don't add terrain blocks to route
+       lda .block_xpos
        cmp .old_block_xpos
        beq +
        cmp .older_block_xpos
        beq +
        inc .distance
        jsr .UpdateCheckpoint
        rts
+       lda .block_ypos
        cmp .old_block_ypos
        beq +
        cmp .older_block_ypos
        beq +
        inc .distance
        jsr .UpdateCheckpoint
+       rts

.UpdateCheckpoint:
        lda .block
        tay
        lda _blockroadstatus,y

        ;set checkpoint for horizontal road
        cmp #BLOCK_HOR_ROAD             
        bne ++
        lda .block_xpos                 ;set new horizontal checkpoint
        sta .checkpoint_block_xpos
        lda .block_ypos
        sta .checkpoint_block_ypos
        lda .old_block_xpos
        inc
        cmp .block_xpos
        bne +
        stz .checkpointdirection        ;car is coming from west, set 0 deg
        rts
+       lda #128
        sta .checkpointdirection        ;car is coming from east, set 180 deg
        rts

        ;set checkpoint for vertical road
++      cmp #BLOCK_VER_ROAD
        bne ++
        lda .block_xpos                 ;set new vertical checkpoint
        sta .checkpoint_block_xpos
        lda .block_ypos
        sta .checkpoint_block_ypos
        lda .old_block_ypos
        inc
        cmp .block_ypos
        bne +
        lda #192
        sta .checkpointdirection        ;car is coming from north, set 270 deg
        rts
+       lda #64
        sta .checkpointdirection        ;car is coming from south, set 90 deg        
++      rts

.UpdateStartPosition                    ;set global start position variables to last checkpoint of this car
        lda .distance
        bne +
        rts
+       lda .checkpoint_block_xpos      
        sta _xstartblock
        lda .checkpoint_block_ypos
        sta _ystartblock
        lda .checkpointdirection
        sta _startdirection
        rts

.UpdateSprite:
        ;update which car sprite to show
        lda .displayangle           ;update car sprite to point in right direction, a skidding car will be rotated up to 22.5 degrees extra        
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

.DetectCollision:       
        ;1 - get address of current block
        lda .block
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
        lda _tilecollisionstatus,y       ;read collision status for current tile

        bne +
        stz .offroadflag                 ;car is on road
        rts

+       cmp #TILE_TERRAIN
        bne ++
        lda #1                          ;car is off road
        sta .offroadflag
        rts

++      lda #ST_COLLISION               ;car has collided
        sta _gamestatus
        lda #1
        sta .collisionflag
        lda #%10100000
        +VPoke .SPR_ATTR_1              ;set palette offset to 0 (explosion colors)
        jsr .StopCarSound
        jsr .StartExplosionSound
        rts

.Explode:
        lda .collisionflag
        bne +
        jsr .StopCarSound               ;this car has not collided, but stop engine sound while the other car explodes
        rts
+       jsr .PlayExplosionSound
        lda .animationindex             ;load current animation index
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
        lda #ST_SETUPRACE
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
        lda .offroadflag
        bne +
        lda #MAX_SPEED          ;set speed limit for car on road
        bra ++
+       lda #MIN_SPEED          ;set speed limit for car off road

++      cmp .speed          
        bcs +
        rts

+       inc .speeddelay
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

        lda .speed
        cmp #MIN_SPEED          ;fixed 6.2, 14 = 3.5
        bmi +
        dec
        sta .speed
+       rts

.brakedelay     !byte 0

.TurnLeft:
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
        sta .turndirection      ;flag that car is turning left
        bra .IncreaseTurnCount

.TurnRight:
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
        stz .turndirection      ;flag that car is turning right

.IncreaseTurnCount:
        lda .turncount          ;count how long user is turning
        cmp #128                ;fixed 6.2, 128 = 32.0 = 180 degrees
        beq +
        inc .turncount 
        inc .turncount 
+       rts

.offroadflag            !byte 0         ;flag for offroad driving
.collisionflag          !byte 0         ;flag for collision between car and background
.clashpush              !byte 0         ;the force car is pushed by the other car when clashing
.clashangle             !byte 0         ;direction car is pushed by the other car when clashing
.speed                  !byte 0         ;fixed point 6.2. 256 = 64.0 = theoretical max speed (+1)
.angle                  !byte 0         ;fixed point 6.2. 256 = 64.0 = 360 deg
.plusangle              !byte 0         ;fixed point 6.2. Extra rotation for skidding car
.displayangle           !byte 0         ;fixed point 6.2. The actual angle car is rendered in, will equal .angle when not skidding
.turncount              !byte 0         ;measurement for how fast user turns. Holding left or right down for long = fast turn -> skidding
.skidangle              !byte 0         ;angle for skidding, car turns left -> angle 90 degrees less than angle for direction, car turns right -> angle 90 degrees more
.turndirection          !byte 0         ;1 = left turn, 0 = right turn
.xpos_lo                !byte 0         ;fixed point 12.4 (0-4095), horizontal location for car on block map that is 32 blocks x 128 pixels = 4096 pixels wide
.xpos_hi                !byte 0
.ypos_lo                !byte 0         ;fixed point 12.4. 0-4095), vertical location for car on block map that is 32 blocks x 128 pixels = 4096 pixels high 
.ypos_hi                !byte 0
.xpos_lo_int            !byte 0         ;integer value of car position
.xpos_hi_int            !byte 0
.ypos_lo_int            !byte 0
.ypos_hi_int            !byte 0
.block_xpos             !byte 0         ;current position in block map (0-31)
.block_ypos             !byte 0
.old_block_xpos         !byte 0         ;former position in block map (0-31)
.old_block_ypos         !byte 0
.older_block_xpos       !byte 0         ;former former position in block map (0-31)
.older_block_ypos       !byte 0
.checkpoint_block_xpos  !byte 0         ;last block passed that was a horizontal or vertical road block, called checkpoint because this is where car will start over if collision or outrun occurs.
.checkpoint_block_ypos  !byte 0
.checkpointdirection    !byte 0         ;direction last checkpoint was passed. 
.block                  !byte 0         ;which type of block car is on
.distance               !byte 0         ;how many blocks the car has passed
