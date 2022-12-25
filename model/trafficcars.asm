;*** trafficcars.asm ******************************************************************************

TRAFFIC_COUNT = 8
TRAFFIC_SPEED = 8

.block_xpos         !byte 0
.block_ypos         !byte 0
.direction          !byte 0
.old_direction      !byte 0

InitTraffic:
    lda _xstartblock
    sta .block_xpos
    lda _ystartblock
    sta .block_ypos
    lda _startdirection
    sta .old_direction

    jsr .GoRandomlyForward
    jsr Car0_Init
    jsr .GoRandomlyForward
    jsr Car1_Init
    jsr .GoRandomlyForward
    jsr Car2_Init
    jsr .GoRandomlyForward
    jsr Car3_Init
    jsr .GoRandomlyForward
    jsr Car4_Init
    jsr .GoRandomlyForward
    jsr Car5_Init
    jsr .GoRandomlyForward
    jsr Car6_Init
    jsr .GoRandomlyForward
    jsr Car7_Init
    rts

.GoRandomlyForward:                 ;OUT: .A = direction, .X and .Y = block position
-   jsr GetRandomNumber2
    and #15
    cmp #2
    bcc -
-   pha
    +GetElementInArray _route_lo, 5, .block_ypos, .block_xpos       ;get direction for current block
    lda (ZP0)
    sta .direction
    cmp #ROUTE_CROSSING
    bne +
    lda .old_direction
    sta .direction          ;if crossing continue straight forward
+   jsr .GoToNextBlock
    pla
    dec
    bne -
    lda .direction
    ldx .block_xpos
    ldy .block_ypos
    rts

.GoToNextBlock:
    lda .direction
    sta .old_direction
    cmp #ROUTE_EAST
    bne +
    +IncAndWrap32 .block_xpos
    rts
+   cmp #ROUTE_WEST
    bne +
    +DecAndWrap32 .block_xpos
    rts
+   cmp #ROUTE_NORTH
    bne +
    +DecAndWrap32 .block_ypos
    rts
+   cmp #ROUTE_SOUTH
    bne +
    +IncAndWrap32 .block_ypos
+   rts

Traffic_Tick:
    jsr Car0_Tick
    jsr Car1_Tick
    jsr Car2_Tick
    jsr Car3_Tick
    jsr Car4_Tick
    jsr Car5_Tick
    jsr Car6_Tick
    jsr Car7_Tick
    rts

!zone
;*** Car 0 ****************************************************************************************
Car0_Init       = .InitCar
Car0_Tick       = .TrafficTick   
_car0_angle     = .angle      
_car0_xpos_lo   = .xpos_lo_int
_car0_xpos_hi   = .xpos_hi_int
_car0_ypos_lo   = .ypos_lo_int
_car0_ypos_hi   = .ypos_hi_int

!src "model/trafficcar.asm"

!zone
;*** Car 1 ****************************************************************************************
Car1_Init       = .InitCar
Car1_Tick       = .TrafficTick   
_car1_angle     = .angle      
_car1_xpos_lo   = .xpos_lo_int
_car1_xpos_hi   = .xpos_hi_int
_car1_ypos_lo   = .ypos_lo_int
_car1_ypos_hi   = .ypos_hi_int

!src "model/trafficcar.asm"

!zone
;*** Car 2 ****************************************************************************************
Car2_Init       = .InitCar
Car2_Tick       = .TrafficTick   
_car2_angle     = .angle      
_car2_xpos_lo   = .xpos_lo_int
_car2_xpos_hi   = .xpos_hi_int
_car2_ypos_lo   = .ypos_lo_int
_car2_ypos_hi   = .ypos_hi_int

!src "model/trafficcar.asm"

!zone
;*** Car 3 ****************************************************************************************
Car3_Init       = .InitCar
Car3_Tick       = .TrafficTick   
_car3_angle     = .angle      
_car3_xpos_lo   = .xpos_lo_int
_car3_xpos_hi   = .xpos_hi_int
_car3_ypos_lo   = .ypos_lo_int
_car3_ypos_hi   = .ypos_hi_int

!src "model/trafficcar.asm"

!zone
;*** Car 4 ****************************************************************************************
Car4_Init       = .InitCar
Car4_Tick       = .TrafficTick   
_car4_angle     = .angle      
_car4_xpos_lo   = .xpos_lo_int
_car4_xpos_hi   = .xpos_hi_int
_car4_ypos_lo   = .ypos_lo_int
_car4_ypos_hi   = .ypos_hi_int

!src "model/trafficcar.asm"

!zone
;*** Car 5 ****************************************************************************************
Car5_Init       = .InitCar
Car5_Tick       = .TrafficTick   
_car5_angle     = .angle      
_car5_xpos_lo   = .xpos_lo_int
_car5_xpos_hi   = .xpos_hi_int
_car5_ypos_lo   = .ypos_lo_int
_car5_ypos_hi   = .ypos_hi_int

!src "model/trafficcar.asm"

!zone
;*** Car 6 ****************************************************************************************
Car6_Init       = .InitCar
Car6_Tick       = .TrafficTick   
_car6_angle     = .angle      
_car6_xpos_lo   = .xpos_lo_int
_car6_xpos_hi   = .xpos_hi_int
_car6_ypos_lo   = .ypos_lo_int
_car6_ypos_hi   = .ypos_hi_int

!src "model/trafficcar.asm"

!zone
;*** Car 7 ****************************************************************************************
Car7_Init       = .InitCar
Car7_Tick       = .TrafficTick   
_car7_angle     = .angle      
_car7_xpos_lo   = .xpos_lo_int
_car7_xpos_hi   = .xpos_hi_int
_car7_ypos_lo   = .ypos_lo_int
_car7_ypos_hi   = .ypos_hi_int

!src "model/trafficcar.asm"

