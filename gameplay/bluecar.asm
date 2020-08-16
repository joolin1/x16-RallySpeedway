;*** Bluecar.asm - instance of the class Car *******************************************************

;**** Public functions and properties **************************************************************

BCar_Show                       = .Show
BCar_Hide                       = .Hide
BCar_ReactOnPlayerInput         = .ReactOnPlayerInput
BCar_StartRace                  = .StartRace
BCar_ResumeRace                 = .ResumeRace
BCar_CarTick                    = .CarTick
BCar_UpdateSprite               = .UpdateSprite
BCar_Explode                    = .Explode
BCar_TimeAddSeconds             = .TimeAddSeconds
BCar_TimeSubSeconds             = .TimeSubSeconds

BCar_PrintDebugInformation:             ;DEBUG
        +SetPrintParams 5,0,$01
        lda .distance
        jsr VPrintNumber
        +SetPrintParams 6,0,$01
        lda .checkpoint_xpos
        jsr VPrintNumber
        +SetPrintParams 7,0,$01
        lda .checkpoint_ypos
        jsr VPrintNumber
        +SetPrintParams 8,0,$01
        lda .checkpointdirection
        jsr VPrintNumber
        rts

_bcarxpos_lo = .xpos_lo_int                     ;world position (0-4095)
_bcarxpos_hi = .xpos_hi_int
_bcarypos_lo = .ypos_lo_int
_bcarypos_hi = .ypos_hi_int

_bcar_checkpoint_xpos = .checkpoint_xpos        ;block position (0-31)
_bcar_checkpoint_ypos = .checkpoint_ypos
_bcar_checkpoint_direction = .checkpointdirection
_bcarspeed = .speed
_bcardistance = .distance
_bcarangle = .angle
_bcarclashpush = .clashpush
_bcarclashangle = .clashangle
_bcarfinishflag = .finishflag
_bcarpenaltycount = .penaltycount
_bcarcollisioncount = .collisioncount
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

!src "gameplay/car.asm"    ;add an instance of car class
!src "libs/timer.asm"  ;add an instance of timer class