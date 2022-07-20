;*** Commander X16 constants ***********************************************************************

TRUE     = 1
FALSE    = 0

;*** BANKED RAM AND ROM ***************
!addr BANK_ADDR  = $A000

!addr RAM_BANK   = $00
!addr ROM_BANK   = $01

;*** Zeropage *************************
!addr ZP0   = $02
!addr ZP1   = $03
!addr ZP2   = $04
!addr ZP3   = $05
!addr ZP4   = $06
!addr ZP5   = $07
!addr ZP6   = $08
!addr ZP7   = $09
!addr ZP8   = $0A
!addr ZP9   = $0B
!addr ZPA   = $0C
!addr ZPB   = $0D
!addr ZPC   = $0E
!addr ZPD   = $0F
!addr ZPE   = $10
!addr ZPF   = $11

;*** IRQ ******************************
!addr IRQ_HANDLER_L 	= $0314		; Address of default IRQ handler
!addr IRQ_HANDLER_H 	= $0315

;*** VERA interface *******************
!addr VERA_ADDR_L   	= $9F20 	; LLLLLLLL - 17 Bit address L
!addr VERA_ADDR_M   	= $9F21		; MMMMMMMM - 17 Bit address M
!addr VERA_ADDR_H	    = $9F22		; IIIID--H - 17 Bit address H (I=Increment, D=Decrement)
!addr VERA_DATA0	    = $9F23		; Data port 0
!addr VERA_DATA1	    = $9F24		; Data port 1
!addr VERA_CTRL      	= $9F25		; R-----DA (R=RESET, D=DCSEL, A=ADDRSEL)
!addr VERA_IEN		    = $9F26		; I---ASLV (I=IRQ line bit 8, A=AFLOW, S=SPRCOL, L=LINE, V=VSYNC)
!addr VERA_ISR		    = $9F27		; SSSSASLV (S=Srite collisions, ...see above)
!addr VERA_IRQLINE_L    = $9F28     ; IRQ Line bits 0-7

;When DCSEL=0
!addr DC_VIDEO		    = $9F29     ;FS10-COO (F=Current field, S=Sprites enable, 1=Layer 1 enable, 0=Layer 0 enable, C=Chroma disable, O=Output mode)
!addr DC_HSCALE		    = $9F2A
!addr DC_VSCALE		    = $9F2B
!addr DC_BORDER_COLOR  	= $9F2C

;When DCSEL=1
!addr DC_HSTART         = $9F29     ;Bits 9-2
!addr DC_HSTOP   	    = $9F2A     ;Bits 9-2
!addr DC_VSTART 	    = $9F2B     ;Bits 8-1
!addr DC_VSTOP  	    = $9F2C     ;Bits 8-1

;Layer 0 registers
!addr L0_CONFIG         = $9F2D
!addr L0_MAPBASE        = $9F2E
!addr L0_TILEBASE       = $9F2F
!addr L0_HSCROLL_L      = $9F30
!addr L0_HSCROLL_H      = $9F31
!addr L0_VSCROLL_L      = $9F32
!addr L0_VSCROLL_H      = $9F33

;Layer 1 registers
!addr L1_CONFIG         = $9F34
!addr L1_MAPBASE        = $9F35
!addr L1_TILEBASE       = $9F36
!addr L1_HSCROLL_L      = $9F37
!addr L1_HSCROLL_H      = $9F38
!addr L1_VSCROLL_L      = $9F39
!addr L1_VSCROLL_H      = $9F3A

;PCM Audio
!addr AUDIO_CTRL        = $9F3B
!addr AUDIO_RATE        = $9F3C
!addr AUDIO_DATA        = $9F3D
!addr SPI_DATA          = $9F3E
!addr SPI_CTRL          = $9F3F

;*** Kernal routines ******************
!addr SETLFS    = $FFBA
!addr SETNAM    = $FFBD
!addr BSOUT     = $FFD2
!addr LOAD      = $FFD5
!addr SAVE      = $FFD8
!addr RDTIM     = $FFDE
!addr GETIN     = $FFE4
!addr PLOT      = $FFF0

!addr joystick_scan         = $FF53
!addr joystick_get          = $FF56
!addr screen_set_charset    = $FF62

;*** ASCII codes **********************
A_RETURN    = $0D
A_BACKSPACE = $14
A_SPACE     = $20
A_HYPHEN    = $2D
A_NINE      = $39
A_N         = $4E
A_Y         = $59

;*** Screen codes *********************
S_D         = $04
S_N         = $0E
S_T         = $14
S_Y         = $19        
S_SPACE     = $20
S_COLON     = $3A    

;*** VRAM *************************************************

;Characters, base $1F000
!addr CHAR_ADDR         = $1F000

;PSG, base $1F9C0
PSG_ADDR                = $F9C0

PSG_V0_FREQ_L           = $F9C0
PSG_V0_FREQ_H           = $F9C1
PSG_V0_PAN_VOL          = $F9C2
PSG_V0_WF_PW            = $F9C3

PSG_V1_FREQ_L           = $F9C4
PSG_V1_FREQ_H           = $F9C5
PSG_V1_PAN_VOL          = $F9C6
PSG_V1_WF_PW            = $F9C7

PSG_V2_FREQ_L           = $F9C8
PSG_V2_FREQ_H           = $F9C9
PSG_V2_PAN_VOL          = $F9CA
PSG_V2_WF_PW            = $F9CB

PSG_V3_FREQ_L           = $F9CC
PSG_V3_FREQ_H           = $F9CD
PSG_V3_PAN_VOL          = $F9CE
PSG_V3_WF_PW            = $F9CF

PSG_V4_FREQ_L           = $F9D0
PSG_V4_FREQ_H           = $F9D1
PSG_V4_PAN_VOL          = $F9D2
PSG_V4_WF_PW            = $F9D3

;Palette, base $1FA00
!addr PALETTE           = $FA00

;Sprite attributes, base $1FC00
!addr SPR_ADDR          = $FC00

!addr SPR0_ADDR_L       = $FC00
!addr SPR0_MODE_ADDR_H  = $FC01
!addr SPR0_XPOS_L       = $FC02
!addr SPR0_XPOS_H       = $FC03
!addr SPR0_YPOS_L       = $FC04
!addr SPR0_YPOS_H       = $FC05
!addr SPR0_ATTR_0       = $FC06
!addr SPR0_ATTR_1       = $FC07

!addr SPR1_ADDR_L       = $FC08
!addr SPR1_MODE_ADDR_H  = $FC09
!addr SPR1_XPOS_L       = $FC0A
!addr SPR1_XPOS_H       = $FC0B
!addr SPR1_YPOS_L       = $FC0C
!addr SPR1_YPOS_H       = $FC0D
!addr SPR1_ATTR_0       = $FC0E
!addr SPR1_ATTR_1       = $FC0F

!addr SPR2_ADDR_L       = $FC10
!addr SPR2_MODE_ADDR_H  = $FC11
!addr SPR2_XPOS_L       = $FC12
!addr SPR2_XPOS_H       = $FC13
!addr SPR2_YPOS_L       = $FC14
!addr SPR2_YPOS_H       = $FC15
!addr SPR2_ATTR_0       = $FC16
!addr SPR2_ATTR_1       = $FC17

!addr SPR3_ADDR_L       = $FC18
!addr SPR3_MODE_ADDR_H  = $FC19
!addr SPR3_XPOS_L       = $FC1A
!addr SPR3_XPOS_H       = $FC1B
!addr SPR3_YPOS_L       = $FC1C
!addr SPR3_YPOS_H       = $FC1D
!addr SPR3_ATTR_0       = $FC1E
!addr SPR3_ATTR_1       = $FC1F

!addr SPR4_ADDR_L       = $FC20
!addr SPR4_MODE_ADDR_H  = $FC21
!addr SPR4_XPOS_L       = $FC22
!addr SPR4_XPOS_H       = $FC23
!addr SPR4_YPOS_L       = $FC24
!addr SPR4_YPOS_H       = $FC25
!addr SPR4_ATTR_0       = $FC26
!addr SPR4_ATTR_1       = $FC27

!addr SPR5_ADDR_L       = $FC28
!addr SPR5_MODE_ADDR_H  = $FC29
!addr SPR5_XPOS_L       = $FC2A
!addr SPR5_XPOS_H       = $FC2B
!addr SPR5_YPOS_L       = $FC2C
!addr SPR5_YPOS_H       = $FC2D
!addr SPR5_ATTR_0       = $FC2E
!addr SPR5_ATTR_1       = $FC2F

!addr SPR6_ADDR_L       = $FC30
!addr SPR6_MODE_ADDR_H  = $FC31
!addr SPR6_XPOS_L       = $FC32
!addr SPR6_XPOS_H       = $FC33
!addr SPR6_YPOS_L       = $FC34
!addr SPR6_YPOS_H       = $FC35
!addr SPR6_ATTR_0       = $FC36
!addr SPR6_ATTR_1       = $FC37

!addr SPR7_ADDR_L       = $FC38
!addr SPR7_MODE_ADDR_H  = $FC39
!addr SPR7_XPOS_L       = $FC3A
!addr SPR7_XPOS_H       = $FC3B
!addr SPR7_YPOS_L       = $FC3C
!addr SPR7_YPOS_H       = $FC3D
!addr SPR7_ATTR_0       = $FC3E
!addr SPR7_ATTR_1       = $FC3F

!addr SPR8_ADDR_L       = $FC40
!addr SPR8_MODE_ADDR_H  = $FC41
!addr SPR8_XPOS_L       = $FC42
!addr SPR8_XPOS_H       = $FC43
!addr SPR8_YPOS_L       = $FC44
!addr SPR8_YPOS_H       = $FC45
!addr SPR8_ATTR_0       = $FC46
!addr SPR8_ATTR_1       = $FC47

!addr SPR9_ADDR_L       = $FC48
!addr SPR9_MODE_ADDR_H  = $FC49
!addr SPR9_XPOS_L       = $FC4A
!addr SPR9_XPOS_H       = $FC4B
!addr SPR9_YPOS_L       = $FC4C
!addr SPR9_YPOS_H       = $FC4D
!addr SPR9_ATTR_0       = $FC4E
!addr SPR9_ATTR_1       = $FC4F

!addr SPR10_ADDR_L      = $FC50
!addr SPR10_MODE_ADDR_H = $FC51
!addr SPR10_XPOS_L      = $FC52
!addr SPR10_XPOS_H      = $FC53
!addr SPR10_YPOS_L      = $FC54
!addr SPR10_YPOS_H      = $FC55
!addr SPR10_ATTR_0      = $FC56
!addr SPR10_ATTR_1      = $FC57

!addr SPR11_ADDR_L      = $FC58
!addr SPR11_MODE_ADDR_H = $FC59
!addr SPR11_XPOS_L      = $FC5A
!addr SPR11_XPOS_H      = $FC5B
!addr SPR11_YPOS_L      = $FC5C
!addr SPR11_YPOS_H      = $FC5D
!addr SPR11_ATTR_0      = $FC5E
!addr SPR11_ATTR_1      = $FC5F

!addr SPR12_ADDR_L      = $FC60
!addr SPR12_MODE_ADDR_H = $FC61
!addr SPR12_XPOS_L      = $FC62
!addr SPR12_XPOS_H      = $FC63
!addr SPR12_YPOS_L      = $FC64
!addr SPR12_YPOS_H      = $FC65
!addr SPR12_ATTR_0      = $FC66
!addr SPR12_ATTR_1      = $FC67

!addr SPR13_ADDR_L      = $FC68
!addr SPR13_MODE_ADDR_H = $FC69
!addr SPR13_XPOS_L      = $FC6A
!addr SPR13_XPOS_H      = $FC6B
!addr SPR13_YPOS_L      = $FC6C
!addr SPR13_YPOS_H      = $FC6D
!addr SPR13_ATTR_0      = $FC6E
!addr SPR13_ATTR_1      = $FC6F

!addr SPR14_ADDR_L      = $FC70
!addr SPR14_MODE_ADDR_H = $FC71
!addr SPR14_XPOS_L      = $FC72
!addr SPR14_XPOS_H      = $FC73
!addr SPR14_YPOS_L      = $FC74
!addr SPR14_YPOS_H      = $FC75
!addr SPR14_ATTR_0      = $FC76
!addr SPR14_ATTR_1      = $FC77

!addr SPR15_ADDR_L      = $FC78
!addr SPR15_MODE_ADDR_H = $FC79
!addr SPR15_XPOS_L      = $FC7A
!addr SPR15_XPOS_H      = $FC7B
!addr SPR15_YPOS_L      = $FC7C
!addr SPR15_YPOS_H      = $FC7D
!addr SPR15_ATTR_0      = $FC7E
!addr SPR15_ATTR_1      = $FC7F

!addr SPR16_ADDR_L      = $FC80
!addr SPR16_MODE_ADDR_H = $FC81
!addr SPR16_XPOS_L      = $FC82
!addr SPR16_XPOS_H      = $FC83
!addr SPR16_YPOS_L      = $FC84
!addr SPR16_YPOS_H      = $FC85
!addr SPR16_ATTR_0      = $FC86
!addr SPR16_ATTR_1      = $FC87

!addr SPR17_ADDR_L      = $FC88
!addr SPR17_MODE_ADDR_H = $FC89
!addr SPR17_XPOS_L      = $FC8A
!addr SPR17_XPOS_H      = $FC8B
!addr SPR17_YPOS_L      = $FC8C
!addr SPR17_YPOS_H      = $FC8D
!addr SPR17_ATTR_0      = $FC8E
!addr SPR17_ATTR_1      = $FC8F

!addr SPR18_ADDR_L      = $FC90
!addr SPR18_MODE_ADDR_H = $FC91
!addr SPR18_XPOS_L      = $FC92
!addr SPR18_XPOS_H      = $FC93
!addr SPR18_YPOS_L      = $FC94
!addr SPR18_YPOS_H      = $FC95
!addr SPR18_ATTR_0      = $FC96
!addr SPR18_ATTR_1      = $FC97