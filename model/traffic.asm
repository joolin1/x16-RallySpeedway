;*** traffic.asm - Class definition ********************************************************************

;This file works as a class definition. Therefore every label is local. An instance of the class is made by including this source file
;in another file and then map the public funtions here to global instance specific labels.
;By including the file, all variables will be added once for every instance. The drawback is that the code is will as well (like a macro). 

;Car properties
.speed                  !byte 0         ;fixed point 6.2. 256 = 64.0 = theoretical max speed (+1)
.angle                  !byte 0         ;fixed point 6.2. 256 = 64.0 = 360 deg
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

;Route variables
.block_xpos             !byte 0         ;current position in block map
.block_ypos             !byte 0
.old_block_xpos         !byte 0         ;former position in block map
.old_block_ypos         !byte 0
.block                  !byte 0         ;current block according to block map
.routedirection         !byte 0         ;current direction of route according to route map

;*** Public functions ******************************************************************************

InitTraffic = .InitTraffic
TCar_CarTick = .TrafficTick
_tcarxpos_lo = .xpos_lo_int
_tcarxpos_hi = .xpos_hi_int
_tcarypos_lo = .ypos_lo_int
_tcarypos_hi = .ypos_hi_int
_tcarangle = .angle

.InitTraffic:                      
        lda #10
        sta .speed
        lda _startdirection
        sta .routedirection
        sta .angle

        ;set start block and init block history
        lda _xstartblock
        sta .block_xpos
        sta .old_block_xpos
        lda _ystartblock
        sta .block_ypos
        sta .old_block_ypos

        ;where to put car in startblock
        lda #64                 ;center car
        sta .xstartoffset
        lda #44
        sta .ystartoffset

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

        ;jsr .PlayEngineSound
        jsr .UpdateCarProperties
        jsr .UpdateRouteInformation     ;explicitly call this routine here, it is otherwise only called when car is entering a new block        
        rts

.TrafficTick:                       ;advance one jiffy, calculate new positions of cars according to speed and direction
        ;TODO: Move car! Just speed for now ...
        jsr .UpdateCarPosition
        jsr .UpdateCarProperties
        rts

.UpdateCarPosition:
        lda .speed
        lsr
        lsr                     ;get rid of fraction
        sta ZP0                 ;speed will also be turning speed
        lda .routedirection
        cmp #ROUTE_OFFROAD
        bne +
        rts        
+       cmp #ROUTE_EAST
        bne +
        jsr .DirectEast
        bra ++
+       cmp #ROUTE_NORTH
        bne +
        jsr .DirectNorth
        bra ++
+       cmp #ROUTE_WEST
        bne +
        jsr .DirectWest
        bra ++
+       cmp #ROUTE_SOUTH
        bne ++
        jsr .DirectSouth

++      ldx ZP0                 ;speed in .x
        lda .angle              ;angle in .A
        jsr .Move               ;move car in current direction
        rts

.DirectEast:
        lda .angle
        bne +                   
        rts                     ;if angle = 0 deg do nothing
+       cmp #128
        bcc +
        lda .angle
        clc
        adc ZP0                 ;increase angle if bigger than 180 deg
        sta .angle              
        rts
+       lda .angle
        sec                     
        sbc ZP0                 ;decrease angle if lesser than 180 deg
        sta .angle
        rts

.DirectWest:
        lda .angle
        cmp #128
        bne +
        rts                     ;if angle = 180 deg do nothing
+       bcc +
        lda .angle
        sec
        sbc ZP0
        sta .angle
        rts
+       lda .angle
        clc
        adc ZP0
        sta .angle
        rts

.DirectNorth:
        lda .angle
        cmp #64
        bne +
        rts                     ;if angle = 90 deg do nothing
+       bcc +  
        cmp #192
        bcs +                   
        lda .angle      
        sec
        sbc ZP0                 ;if angle > 90 deg and < 270 deg increase it
        sta .angle
        rts
+       lda .angle
        clc
        adc ZP0                 ;if angle < 90 deg and >= 270 deg increase it
        sta .angle
        rts

.DirectSouth:
        lda .angle
        cmp #192
        bne +
        rts                     ;if angle = 90 deg do nothing
+       bcs +  
        cmp #64
        bcc +                   
        lda .angle      
        clc
        adc ZP0                 ;if angle < 90 deg and > 270 deg increase it
        sta .angle
        rts
+       lda .angle
        sec
        sbc ZP0
        sta .angle
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
        lda .block_ypos
        cmp .old_block_ypos
        bne .UpdateRouteInformation
        rts

.UpdateRouteInformation:
        lda .block_xpos                                                 ;update block route history           
        sta .old_block_xpos
        lda .block_ypos
        sta .old_block_ypos

        +GetElementInArray _blockmap_lo, 5, .block_ypos, .block_xpos    ;get current block
        lda (ZP0)
        sta .block
        tay
        +GetElementInArray _route_lo, 5, .block_ypos, .block_xpos       ;get direction that current block is leading to
        lda (ZP0)
        sta .routedirection
        rts

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

.IncreaseSpeed:
        ldx .speed
        cpx #TRAFFIC_MAX_SPEED
        bcc +
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
        lda .speed
        bne +
        rts
+       lda .angle              ;fixed 6.2, 256 = 64.0 = 360 deg
        inc
        inc                     ;increase angle for car
        sta .angle
        rts

.TurnRight:
        lda .speed
        bne +
        rts
+       lda .angle              ;fixed 6.2, 256 = 64.0 = 360 deg
        dec
        dec
        sta .angle
        rts