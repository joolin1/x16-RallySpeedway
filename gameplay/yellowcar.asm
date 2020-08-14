;*** Yellowcar.asm - instance of the class car *****************************************************

;**** Public functions and properties **************************************************************

YCar_Show                       = .Show
YCar_Hide                       = .Hide
YCar_ReactOnPlayerInput         = .ReactOnPlayerInput
YCar_StartRace                  = .StartRace
YCar_ResumeRace                 = .ResumeRace
YCar_UpdatePosition             = .UpdatePosition
YCar_UpdateSprite               = .UpdateSprite
YCar_DetectCollision            = .DetectCollision
YCar_Explode                    = .Explode
YCar_TimeAddSeconds             = .TimeAddSeconds
YCar_TimeSubSeconds             = .TimeSubSeconds

YCar_PrintDebugInformation:             ;DEBUG
        ; +SetPrintParams 0,0,$01
        ; lda .distance
        ; jsr VPrintNumber
        +SetPrintParams 1,0,$01
        lda .checkpoint_xpos
        jsr VPrintNumber
        +SetPrintParams 2,0,$01
        lda .checkpoint_ypos
        jsr VPrintNumber
        +SetPrintParams 3,0,$01
        lda .checkpointdirection
        jsr VPrintNumber
        rts

_ycarxpos_lo = .xpos_lo_int                     ;world position (0-4095)
_ycarxpos_hi = .xpos_hi_int
_ycarypos_lo = .ypos_lo_int
_ycarypos_hi = .ypos_hi_int

_ycar_checkpoint_xpos = .checkpoint_xpos        ;block position (0-31)
_ycar_checkpoint_ypos = .checkpoint_ypos
_ycarspeed = .speed
_ycardistance = .distance
_ycarangle = .angle
_ycarclashpush = .clashpush
_ycarclashangle = .clashangle
_ycarfinishflag = .finishflag
_ycarpenaltycount = .penaltycount
_ycarcollisioncount = .collisioncount
_ycartime = .minutes

;*** Private variables and constants ***************************************************************

.ID     = 0
.joy    = _joy0         ;use gamepad 1
.CAR_PALETTE = 1        ;use palette 1 to make car yellow

.PlayEngineSound        = PlayYCarEngineSound
.PlaySkiddingSound      = PlayYCarSkiddingSound
.StopSkiddingSound      = StopYCarSkiddingSound

.SPR_ADDR_L       = SPR1_ADDR_L         ;yellow car is sprite 1
.SPR_MODE_ADDR_H  = SPR1_MODE_ADDR_H
.SPR_ATTR_0       = SPR1_ATTR_0
.SPR_ATTR_1       = SPR1_ATTR_1

!src "gameplay/car.asm"        ;add an instance of car class
!src "libs/timer.asm"      ;add an instance of timer class 