;*** Bluecar.asm - instance of the class Car *******************************************************

;**** Public functions and properties **************************************************************

BCar_StartRace                  = .StartRace
BCar_ResumeRace                 = .ResumeRace
BCar_CarTick                    = .CarTick
BCar_TimeAddSeconds             = .TimeAddSeconds
BCar_TimeSubSeconds             = .TimeSubSeconds
BCar_Collide                    = .Collide

BCar_PrintDebugInformation:             ;DEBUG
        +SetPrintParams 4,0,$01
        lda _bcarclashangle
        jsr VPrintNumber
        +SetPrintParams 5,0,$01
        lda _bcarclashpush
        jsr VPrintNumber
        +SetPrintParams 6,0,$01
        lda _bcarspeed
        jsr VPrintNumber    
        rts

_bcarxpos_lo = .xpos_lo_int                     ;world position (0-4095)
_bcarxpos_hi = .xpos_hi_int
_bcarypos_lo = .ypos_lo_int
_bcarypos_hi = .ypos_hi_int

_bcar_checkpoint_xpos = .checkpoint_xpos        ;block position (0-31)
_bcar_checkpoint_ypos = .checkpoint_ypos
_bcar_checkpoint_direction = .checkpointdirection
_bcar_routedirection = .routedirection
_bcarspeed = .speed
_bcardistance_lo = .distance_lo
_bcardistanceleft_lo = .distanceleft_lo 
_bcarangle = .angle
_bcardisplayangle = .displayangle
_bcarclashpush = .clashpush
_bcarclashangle = .clashangle
_bcarcollisionflag = .collisionflag
_bcarfinishflag = .finishflag
_bcarpenaltycount = .penaltycount
_bcarcollisioncount = .collisioncount
_bcartime = .minutes

;*** Private variables and constants ***************************************************************

.ID     = 1
.joy    = _joy1         ;use gamepad 2

.PlayEngineSound        = PlayBCarEngineSound
.PlaySkiddingSound      = PlayBCarSkiddingSound
.StopSkiddingSound      = StopBCarSkiddingSound
.StopCarSounds          = StopBCarSounds

!src "model/car.asm"    ;add an instance of car class
!src "libs/timer.asm"  ;add an instance of timer class