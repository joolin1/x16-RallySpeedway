;*** Bluecar.asm - instance of the class Car *******************************************************

;**** Public functions and properties **************************************************************

BCar_Show                       = .Show
BCar_Hide                       = .Hide
BCar_ReactOnPlayerInput         = .ReactOnPlayerInput
BCar_Init                       = .Init
BCar_UpdatePosition             = .UpdatePosition
BCar_UpdateSprite               = .UpdateSprite
BCar_UpdateStartPosition        = .UpdateStartPosition
BCar_DetectCollision            = .DetectCollision
BCar_Explode                    = .Explode
BCar_TimeReset                  = .TimeReset
BCar_TimeAddSeconds             = .TimeAddSeconds
BCar_TimeSubSeconds             = .TimeSubSeconds
BCar_DisplayTime                = .DisplayTime

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
_bcarfinishflag = .finishflag
_bcarpenaltycount = .penaltycount       ;decimal mode
_bcarcollisioncount = .collisioncount   ;decimal mode
_bcartime = .minutes

;*** Private variables and constants ***************************************************************

.ID     = 1
.joy    = _joy1         ;use gamepad 2
.CAR_PALETTE = 2        ;use palette 2 to make car blue

.PlayEngineSound        = PlayBCarEngineSound
.PlaySkiddingSound      = PlayBCarSkiddingSound
.StopSkiddingSound      = StopBCarSkiddingSound

.SPR_ADDR_L       = SPR2_ADDR_L         ;blue car is sprite 2
.SPR_MODE_ADDR_H  = SPR2_MODE_ADDR_H
.SPR_ATTR_0       = SPR2_ATTR_0
.SPR_ATTR_1       = SPR2_ATTR_1

!src "x16-rallyspeedway/car.asm"    ;add an instance of car class
!src "x16-rallyspeedway/timer.asm"  ;add an instance of timer class