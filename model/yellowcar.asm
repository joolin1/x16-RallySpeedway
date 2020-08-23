;*** Yellowcar.asm - instance of the class car *****************************************************

;**** Public functions and properties **************************************************************

YCar_StartRace                  = .StartRace
YCar_ResumeRace                 = .ResumeRace
YCar_CarTick                    = .CarTick
YCar_TimeAddSeconds             = .TimeAddSeconds
YCar_TimeSubSeconds             = .TimeSubSeconds

YCar_PrintDebugInformation:             ;DEBUG
        +SetPrintParams 1,0,$01
        lda .block_xpos
        jsr VPrintNumber
        +SetPrintParams 2,0,$01
        lda .block_ypos
        jsr VPrintNumber
        +SetPrintParams 3,0,$01
        lda .block
        jsr VPrintNumber
        +SetPrintParams 4,0,$01
        lda .routedirection
        jsr VPrintNumber
        rts

_ycarxpos_lo = .xpos_lo_int                     ;world position (0-4095)
_ycarxpos_hi = .xpos_hi_int
_ycarypos_lo = .ypos_lo_int
_ycarypos_hi = .ypos_hi_int

_ycar_checkpoint_xpos = .checkpoint_xpos        ;block position (0-31)
_ycar_checkpoint_ypos = .checkpoint_ypos
_ycar_checkpoint_direction = .checkpointdirection
_ycarspeed = .speed
_ycardistance = .distance
_ycarangle = .angle
_ycardisplayangle = .displayangle
_ycarclashpush = .clashpush
_ycarclashangle = .clashangle
_ycarcollisionflag = .collisionflag
_ycarfinishflag = .finishflag
_ycarpenaltycount = .penaltycount
_ycarcollisioncount = .collisioncount
_ycartime = .minutes

;*** Private variables and constants ***************************************************************

.ID     = 0
.joy    = _joy0         ;use gamepad 1

.PlayEngineSound        = PlayYCarEngineSound
.PlaySkiddingSound      = PlayYCarSkiddingSound
.StopSkiddingSound      = StopYCarSkiddingSound

!src "model/car.asm"    ;add an instance of car class
!src "libs/timer.asm"   ;add an instance of timer class 