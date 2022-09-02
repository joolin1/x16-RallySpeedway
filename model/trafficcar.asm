;*** trafficcar.asm - Class definition ************************************************************

;This file works as a class definition. Therefore every label is local. An instance of the class is made by including this source file
;in another file and then map the public funtions here to global instance specific labels.
;By including the file, all variables will be added once for every instance. The drawback is that the code is will as well (like a macro). 

;Car properties
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
.direction              !byte 0         ;current direction of route according to route map
.old_direction          !byte 0

;*** Public functions ******************************************************************************

.InitCar:                         ;IN: .A = direction, .X = x startblock, .Y = y startblock         
        ;set start block
        sta .angle
        sta .direction
        stx .block_xpos
        sty .block_ypos          

        ;set offset in start block
        jsr GetRandomNumber2
        and #31                 ;max offset = 31
        clc 
        adc #48
        sta ZP0
        lda .direction
        cmp #ROUTE_EAST
        beq +
        cmp #ROUTE_WEST
        beq +
        lda ZP0
        sta .xstartoffset
        lda #64
        sta .ystartoffset
        bra ++
+       lda #64
        sta .xstartoffset
        lda ZP0
        sta .ystartoffset

        ;position car in start block
++      stz .xpos_lo
        lda .block_xpos
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
        lda .block_ypos
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
        rts

.TrafficTick:                       ;advance one jiffy, calculate new positions of cars according to speed and direction
        jsr .MoveCar
        jsr .UpdateCarProperties
        rts

;*** Private functions **************************************************************************** 

.MoveCar:
        lda .direction
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
++      lda #TRAFFIC_SPEED
        lsr
        lsr                     ;get rid of fraction
        tax                     ;speed in .X
        lda .angle
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

.DirectEast:
        lda .angle
        bne +
        stz .turningspeed                   
        rts                     ;if angle = 0 deg do nothing
+       jsr .GetTurningSpeed    ;speed in ZP0
        lda .angle
        cmp #128
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
        stz .turningspeed                   
        rts                     ;if angle = 180 deg do nothing
+       jsr .GetTurningSpeed    ;speed in ZP0
        lda .angle
        cmp #128
        bcc +
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
        stz .turningspeed                   
        rts                     ;if angle = 90 deg do nothing
+       jsr .GetTurningSpeed    ;speed in ZP0
        lda .angle
        cmp #64
        bcc +        
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
        stz .turningspeed                  
        rts                     ;if angle = 90 deg do nothing
+       jsr .GetTurningSpeed    ;speed in ZP0
        lda .angle
        cmp #192
        bcs +  
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

.GetTurningSpeed:               ;randomize a turning speed for each turn and keep it until turn completed
        lda .turningspeed       ;OUT: ZP0 = current turning speed
        bne +
        jsr GetRandomNumber
        and #3
        inc                     ;now speed = 1, 2, 3 and 4
        sta .turningspeed       ;
+       dec                     ;now speed = 0, 1, 2 and 3
        asl
        asl
        asl                     ;multiply by 8 to get right row in speed table
        clc
        adc .turningspeed_index ;add col
        tay
        lda .turningspeeds,y
        sta ZP0
        lda .turningspeed_index
        inc
        and #7
        sta .turningspeed_index ;add column and wrap at 8
        rts

.turningspeed           !byte 0
.turningspeeds          !byte 1,1,1,2,1,1,1,1   ;1.125
                        !byte 1,2,1,2,1,2,1,1   ;1.375
                        !byte 1,2,2,2,1,2,1,2   ;1.625
                        !byte 2,2,2,2,2,2,2,2   ;2
.turningspeed_index     !byte 0

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
        lda .direction
        sta .old_direction
        +GetElementInArray _route_lo, 5, .block_ypos, .block_xpos       ;get direction that current block is leading to
        lda (ZP0)
        sta .direction
        cmp #ROUTE_CROSSING
        bne +
        lda .old_direction
        sta .direction
+       rts