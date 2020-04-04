;*** RAM **********************

!addr IRQ_HANDLER_L 	= $0314		; Address of default IRQ handler
!addr IRQ_HANDLER_H 	= $0315

!addr VERA_ADDR_L   	= $9f20 	; LLLLLLLL - 17 Bit address L
!addr VERA_ADDR_M   	= $9f21		; MMMMMMMM - 17 Bit address M
!addr VERA_ADDR_H	    = $9f22		; IIIID--H - 17 Bit address H (I=Increment, D=Decrement)
!addr VERA_DATA0	    = $9f23		; Data port 0
!addr VERA_DATA1	    = $9f24		; Data port 1
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

;*** VRAM *********************

;Palette, base $1FA00
!addr PALETTE           = $FA00

;Characters, base $F800
!addr CHAR_ADDR         = $F800

;Sprite attributes base 1FC00
!addr SPR_ADDR          = $FC00

!addr SPR1_ADDR_L       = $FC08
!addr SPR1_MODE_ADDR_H  = $FC09
!addr SPR1_XPOS_L       = $FC0a
!addr SPR1_XPOS_H       = $FC0b
!addr SPR1_YPOS_L       = $FC0c
!addr SPR1_YPOS_H       = $FC0d
!addr SPR1_ATTR_0       = $FC0e
!addr SPR1_ATTR_1       = $FC0f

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
!addr SPR3_XPOS_L       = $FC1a
!addr SPR3_XPOS_H       = $FC1b
!addr SPR3_YPOS_L       = $FC1c
!addr SPR3_YPOS_H       = $FC1d
!addr SPR3_ATTR_0       = $FC1e
!addr SPR3_ATTR_1       = $FC1f

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
!addr SPR5_XPOS_L       = $FC2a
!addr SPR5_XPOS_H       = $FC2b
!addr SPR5_YPOS_L       = $FC2c
!addr SPR5_YPOS_H       = $FC2d
!addr SPR5_ATTR_0       = $FC2e
!addr SPR5_ATTR_1       = $FC2f

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
!addr SPR7_XPOS_L       = $FC3a
!addr SPR7_XPOS_H       = $FC3b
!addr SPR7_YPOS_L       = $FC3c
!addr SPR7_YPOS_H       = $FC3d
!addr SPR7_ATTR_0       = $FC3e
!addr SPR7_ATTR_1       = $FC3f

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
!addr SPR9_XPOS_L       = $FC4a
!addr SPR9_XPOS_H       = $FC4b
!addr SPR9_YPOS_L       = $FC4c
!addr SPR9_YPOS_H       = $FC4d
!addr SPR9_ATTR_0       = $FC4e
!addr SPR9_ATTR_1       = $FC4f

!addr SPR10_ADDR_L       = $FCFC
!addr SPR10_MODE_ADDR_H  = $FC51
!addr SPR10_XPOS_L       = $FC52
!addr SPR10_XPOS_H       = $FC53
!addr SPR10_YPOS_L       = $FC54
!addr SPR10_YPOS_H       = $FC55
!addr SPR10_ATTR_0       = $FC56
!addr SPR10_ATTR_1       = $FC57

!addr SPR11_ADDR_L       = $FC58
!addr SPR11_MODE_ADDR_H  = $FC59
!addr SPR11_XPOS_L       = $FC5a
!addr SPR11_XPOS_H       = $FC5b
!addr SPR11_YPOS_L       = $FC5c
!addr SPR11_YPOS_H       = $FC5d
!addr SPR11_ATTR_0       = $FC5e
!addr SPR11_ATTR_1       = $FC5f

!addr SPR12_ADDR_L       = $FC60
!addr SPR12_MODE_ADDR_H  = $FC61
!addr SPR12_XPOS_L       = $FC62
!addr SPR12_XPOS_H       = $FC63
!addr SPR12_YPOS_L       = $FC64
!addr SPR12_YPOS_H       = $FC65
!addr SPR12_ATTR_0       = $FC66
!addr SPR12_ATTR_1       = $FC67

!addr SPR13_ADDR_L       = $FC68
!addr SPR13_MODE_ADDR_H  = $FC69
!addr SPR13_XPOS_L       = $FC6a
!addr SPR13_XPOS_H       = $FC6b
!addr SPR13_YPOS_L       = $FC6c
!addr SPR13_YPOS_H       = $FC6d
!addr SPR13_ATTR_0       = $FC6e
!addr SPR13_ATTR_1       = $FC6f

;*** Kernal routines ***
!addr SCNKEY    = $FF9F
!addr SETLFS    = $FFBA
!addr SETNAM    = $FFBD
!addr BSOUT     = $FFD2
!addr LOAD      = $FFD5
!addr RDTIM     = $FFDE
!addr GETIN     = $FFE4
!addr PLOT      = $FFF0
!addr MOUSE     = $FF09
!addr CINT      = $FF81

!addr joystick_scan         = $FF53
!addr joystick_get          = $FF56
!addr screen_set_charset    = $ff62

;*** Zeropage ***
ZP0             = $00
ZP1             = $01
ZP2             = $02
ZP3             = $03
ZP4             = $04
ZP5             = $05
ZP6             = $06
ZP7             = $07
ZP8             = $08
ZP9             = $09
ZPA             = $0a
ZPB             = $0b
ZPC             = $0c
ZPD             = $0d
ZPE             = $0e
ZPF             = $0f

scrollxoffs_lo  = $10
scrollxoffs_hi  = $11
scrollyoffs_lo  = $12
scrollyoffs_hi  = $13