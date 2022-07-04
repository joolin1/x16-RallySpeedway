;*** joystick.lib **********************************************************************************

JOYSTICK_NOT_PRESENT    = 0
JOYSTICK_TYPE_NES       = 1
JOYSTICK_TYPE_SNES      = 2

JOY_NOTHING_PRESSED     = 255
JOY_BUTTON_A            = 128
JOY_BUTTON_B            = 64
JOY_SELECT              = 32
JOY_START               = 16
JOY_UP                  = 8
JOY_DOWN                = 4
JOY_LEFT                = 2
JOY_RIGHT               = 1

_joy0type:	!byte 0 ;used by GetJoys to store status of game controller 0 in NES style
_joy1type:	!byte 0 ;used by GetJoys to store status of game controller 1 in NES style
_joy0:          !byte 0 ;status for game controller 0
_joy1:          !byte 0 ;status for game controller 1

;*** Public functions **********************************************************

InitJoysticks:
	jsr joystick_scan
	ldx #0
	jsr joystick_get
	txa
	and #12
	beq +
	lda #JOYSTICK_TYPE_SNES
	sta _joy0type
	bra ++
+	lda #JOYSTICK_TYPE_NES
	sta _joy0type
++      ldx #1
	jsr joystick_get
        tya
        beq +
        lda #JOYSTICK_NOT_PRESENT
        sta _joy1type
        rts
+	txa
	and #12
	beq +
	lda #JOYSTICK_TYPE_SNES
	sta _joy1type
	rts
+	lda #JOYSTICK_TYPE_NES
	sta _joy1type
	rts

GetJoys:                        ;OUT: status of both joysticks in _joy0 and _joy1
        jsr joystick_scan
        ldx #0
        jsr joystick_get
        pha
        lda _joy0type
        cmp #JOYSTICK_TYPE_NES
        bne +
        pla
        sta _joy0
        bra ++
+       pla
        jsr .MoveBits
        sta _joy0
++      ldx #1
        jsr joystick_get
        pha
        lda _joy1type
        cmp #JOYSTICK_TYPE_NES
        bne +
        pla
        sta _joy1
        rts
+       pla
        jsr .MoveBits
        sta _joy1
        rts

GetJoy0:                        ;OUT: .A = status of joystick 0 in NES layout regardless of joystick type
        jsr joystick_scan
        ldx #0
        jsr joystick_get        
        pha
        lda _joy0type
        cmp #JOYSTICK_TYPE_NES
        bne +
        pla                     ;do nothing if NES
        rts                     

GetJoy1:
        jsr joystick_scan       ;OUT: .A = status of joystick 1 in NES layout regardless of joystick type
        ldx #1
        jsr joystick_get
        pha
        lda _joy1type
        cmp #JOYSTICK_TYPE_NES
        bne +
        pla                     ;do nothing if NES
        rts

;*** Private functions *********************************************************

+       pla
.MoveBits:
        and #191                ;set bit 6 to 0 in byte 0 (first byte with joystick info)
        sta ZP0
        and #128                ;keep just bit 7 (button B when SNES)
        lsr                     ;shift 7 to 6
        ora ZP0                 ;merge with byte 0
        and #127                ;set bit 7 to 0
        sta ZP0
        txa
        and #128                ;get bit 7 in byte 1 (button A when SNES)
        ora ZP0                 ;merge with byte 0
        rts