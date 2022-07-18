;*** joystick.lib **********************************************************************************

JOYSTICK_PRESENT        = $00
JOYSTICK_NOT_PRESENT    = $ff

JOY_NOTHING_PRESSED     = 255
JOY_BUTTON_B            = 128
JOY_BUTTON_A            = 64
JOY_SELECT              = 32
JOY_START               = 16
JOY_UP                  = 8
JOY_DOWN                = 4
JOY_LEFT                = 2
JOY_RIGHT               = 1

;What controllers are used (= what _joy0 and joy1 will correspond to) depends on how many game controllers are present
.joy0mapping:   !byte 0 ;can be keyboard or game controller 1
.joy1mapping:   !byte 0 ;can be nothing, game controller 1 or game controller 2
.joystick_count !byte 0

_joy0:          !byte 0 ;status for first controller
_joy1:          !byte 0 ;status for second controller

;*** Public functions **********************************************************

InitJoysticks:
        jsr joystick_scan
        lda #1
        sta .joystick_count     ;keyboard joystick is always present
        lda #1
        jsr joystick_get
        cpy #JOYSTICK_NOT_PRESENT
        beq +
        inc .joystick_count     ;game controller 1 is present
+       lda #2
        jsr joystick_get
        cpy #JOYSTICK_NOT_PRESENT
        beq +
        inc .joystick_count     ;game controller 2 is present

+       lda .joystick_count
        cmp #1
        bne +      
        stz .joy0mapping        ;joy0 = keyboard
        lda #JOYSTICK_NOT_PRESENT
        sta .joy1mapping        ;joy1 = not present
        rts

+       cmp #2
        bne +
        lda #1                  ;joy0 = game controller
        sta .joy0mapping        
        stz .joy1mapping        ;joy1 = keyboard
        rts

+       lda #1                 
        sta .joy0mapping        ;joy0 = game controller 1
        lda #2
        sta .joy1mapping        ;joy1 = game controller 2
        rts

GetJoys:                        ;OUT: status of both controllers in _joy0 and _joy1
        ;jsr joystick_scan      ;only necessary if default irq handler is skipped
        lda .joy0mapping
        jsr .wrapped_joystick_get
        sta _joy0
        lda .joy1mapping
        jsr .wrapped_joystick_get
        sta _joy1
        rts

.wrapped_joystick_get:
        jsr joystick_get
        ora #64         ;keep all except bit 6
        sta ZP0
        txa
        ora #127        ;mask out button A
        sec
        ror             ;move result to bit 6
        and ZP0         ;merge with other info
        rts