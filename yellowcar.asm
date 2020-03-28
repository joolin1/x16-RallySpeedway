;*** Yellowcar.asm - instance of the class car *****************************************************

;**** Public functions and properties **************************************************************

YCar_ReactOnPlayerInput         = .ReactOnPlayerInput
YCar_Init                       = .Init
YCar_UpdatePosition             = .UpdatePosition
YCar_UpdateSprite               = .UpdateSprite
YCar_UpdateStartPosition        = .UpdateStartPosition
YCar_DetectCollision            = .DetectCollision
YCar_Explode                    = .Explode
YCar_TimeReset                  = .TimeReset
YCar_TimeTick                   = .TimeTick
YCar_TimeAddSeconds             = .TimeAddSeconds

YCar_DisplayTime:
        lda #1          ;white text color
        ldx #1          ;column
        ldy #28         ;row
        jsr .DisplayTime
        rts

YCar_PrintDebugInformation:  ;DEBUG
        lda #0
        jsr DebugSetLine
        lda .distance
        jsr DebugPrintNumber
        lda #1
        jsr DebugSetLine
        lda .checkpoint_block_xpos
        jsr DebugPrintNumber
        lda #2
        jsr DebugSetLine
        lda .checkpoint_block_ypos
        jsr DebugPrintNumber
        lda #3
        jsr DebugSetLine
        lda .checkpointdirection
        jsr DebugPrintNumber
        rts

_ycarxpos_lo = .xpos_lo_int
_ycarxpos_hi = .xpos_hi_int
_ycarypos_lo = .ypos_lo_int
_ycarypos_hi = .ypos_hi_int

_ycardistance = .distance
_ycarspeed = .speed
_ycarangle = .angle
_ycarclashpush = .clashpush
_ycarclashangle = .clashangle

;*** Private variables and constants ***************************************************************

.joy = _joy0

.SPR_ADDR_L       = SPR1_ADDR_L
.SPR_MODE_ADDR_H  = SPR1_MODE_ADDR_H
.SPR_ATTR_0       = SPR1_ATTR_0
.SPR_ATTR_1       = SPR1_ATTR_1

.ID = 0

!src "Rally/car.asm"    ;add an instance of car class
!src "Rally/timer.asm"  ;add an instance of timer class