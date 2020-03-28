;*** Bluecar.asm - instance of the class Car *******************************************************

;**** Public functions and properties **************************************************************

BCar_ReactOnPlayerInput         = .ReactOnPlayerInput
BCar_Init                       = .Init
BCar_UpdatePosition             = .UpdatePosition
BCar_UpdateSprite               = .UpdateSprite
BCar_UpdateStartPosition        = .UpdateStartPosition
BCar_DetectCollision            = .DetectCollision
BCar_Explode                    = .Explode
BCar_TimeReset                  = .TimeReset
BCar_TimeTick                   = .TimeTick
BCar_TimeAddSeconds             = .TimeAddSeconds

BCar_DisplayTime:
        lda #1          ;white text color
        ldx #31         ;column
        ldy #28         ;row
        jsr .DisplayTime
        rts

BCar_PrintDebugInformation:         ;DEBUG
        lda #5
        jsr DebugSetLine
        lda .distance
        jsr DebugPrintNumber
        lda #6
        jsr DebugSetLine
        lda .checkpoint_block_xpos
        jsr DebugPrintNumber
        lda #7
        jsr DebugSetLine
        lda .checkpoint_block_ypos
        jsr DebugPrintNumber
        lda #8
        jsr DebugSetLine
        lda .checkpointdirection
        jsr DebugPrintNumber
        rts

_bcarxpos_lo = .xpos_lo_int
_bcarxpos_hi = .xpos_hi_int
_bcarypos_lo = .ypos_lo_int
_bcarypos_hi = .ypos_hi_int

_bcardistance = .distance
_bcarspeed = .speed
_bcarangle = .angle
_bcarclashpush = .clashpush
_bcarclashangle = .clashangle

;*** Private variables and constants ***************************************************************

.joy = _joy1

.SPR_ADDR_L       = SPR2_ADDR_L
.SPR_MODE_ADDR_H  = SPR2_MODE_ADDR_H
.SPR_ATTR_0       = SPR2_ATTR_0
.SPR_ATTR_1       = SPR2_ATTR_1

.ID = 1

!src "Rally/car.asm"    ;add an instance of car class
!src "Rally/timer.asm"  ;add an instance of timer class