;*** RAM ***

!addr VERA_ADDR_LO   	= $9f20 	; LLLLLLLL - 20 Bit address L
!addr VERA_ADDR_MID  	= $9f21		; MMMMMMMM - 20 Bit address M
!addr VERA_ADDR_HI	    = $9f22		; IIIIHHHH - 20 Bit address H  I=Increment
!addr VERA_DATA0	    = $9f23		; Data port 0
!addr VERA_DATA1	    = $9f24		; Data port 1
!addr VERA_CTRL      	= $9F25		; R------A (R=RESET A=ADDRSEL)
!addr VERA_IEN		    = $9F26		; -------E (E=ENABLE INTERRUPTS)
!addr VERA_ISR		    = $9F27		; -------F (F=FLAG)
!addr IRQ_HANDLER_LO	= $0314		; Address of default IRQ handler
!addr IRQ_HANDLER_HI	= $0315

;*** VRAM ***

;Display composer, base $F0000
!addr DC_VIDEO		    = $0000
!addr DC_HSCALE		    = $0001
!addr DC_VSCALE		    = $0002
!addr DC_BORDER_COLOR  	= $0003
!addr DC_HSTART_L       = $0004
!addr DC_HSTOP_L	    = $0005
!addr DC_VSTART_L	    = $0006
!addr DC_VSTOP_L	    = $0007
!addr DC_STARTSTOP_H    = $0008
!addr DC_IRQ_LINE_L	    = $0009
!addr DC_IRQ_LINE_H	    = $000A

;Palette, base $F1000
!addr PALETTE           = $1000

;Characters, base $F800
!addr CHAR_ADDR         = $F800

;Layer 0 registers base F2000
!addr Ln0_CTRL0         = $2000
!addr Ln0_CTRL1         = $2001
!addr Ln0_MAP_BASE_L    = $2002
!addr Ln0_MAP_BASE_H    = $2003
!addr Ln0_TILE_BASE_L   = $2004
!addr Ln0_TILE_BASE_H   = $2005
!addr Ln0_HSCROLL_L     = $2006
!addr Ln0_HSCROLL_H     = $2007
!addr Ln0_VSCROLL_L     = $2008
!addr Ln0_VSCROLL_H     = $2009

!addr Ln0_BM_PAL_OFFS   = $2007

;Layer 1 registers base F3000
!addr Ln1_CTRL0         = $3000
!addr Ln1_CTRL1         = $3001
!addr Ln1_MAP_BASE_L    = $3002
!addr Ln1_MAP_BASE_H    = $3003
!addr Ln1_TILE_BASE_L   = $3004
!addr Ln1_TILE_BASE_H   = $3005
!addr Ln1_HSCROLL_L     = $3006
!addr Ln1_HSCROLL_H     = $3007
!addr Ln1_VSCROLL_L     = $3008
!addr Ln1_VSCROLL_H     = $3009

!addr Ln1_BM_PAL_OFFS   = $3007

;Sprite registers base F4000
!addr SPR_CTRL          = $4000
!addr SPR_COLLISION     = $4001

;Sprite attributes base F5000
!addr SPR1_ADDR_L       = $5008
!addr SPR1_MODE_ADDR_H  = $5009
!addr SPR1_XPOS_L       = $500a
!addr SPR1_XPOS_H       = $500b
!addr SPR1_YPOS_L       = $500c
!addr SPR1_YPOS_H       = $500d
!addr SPR1_ATTR_0       = $500e
!addr SPR1_ATTR_1       = $500f

!addr SPR2_ADDR_L       = $5010
!addr SPR2_MODE_ADDR_H  = $5011
!addr SPR2_XPOS_L       = $5012
!addr SPR2_XPOS_H       = $5013
!addr SPR2_YPOS_L       = $5014
!addr SPR2_YPOS_H       = $5015
!addr SPR2_ATTR_0       = $5016
!addr SPR2_ATTR_1       = $5017

!addr SPR3_ADDR_L       = $5018
!addr SPR3_MODE_ADDR_H  = $5019
!addr SPR3_XPOS_L       = $501a
!addr SPR3_XPOS_H       = $501b
!addr SPR3_YPOS_L       = $501c
!addr SPR3_YPOS_H       = $501d
!addr SPR3_ATTR_0       = $501e
!addr SPR3_ATTR_1       = $501f

!addr SPR4_ADDR_L       = $5020
!addr SPR4_MODE_ADDR_H  = $5021
!addr SPR4_XPOS_L       = $5022
!addr SPR4_XPOS_H       = $5023
!addr SPR4_YPOS_L       = $5024
!addr SPR4_YPOS_H       = $5025
!addr SPR4_ATTR_0       = $5026
!addr SPR4_ATTR_1       = $5027

!addr SPR5_ADDR_L       = $5028
!addr SPR5_MODE_ADDR_H  = $5029
!addr SPR5_XPOS_L       = $502a
!addr SPR5_XPOS_H       = $502b
!addr SPR5_YPOS_L       = $502c
!addr SPR5_YPOS_H       = $502d
!addr SPR5_ATTR_0       = $502e
!addr SPR5_ATTR_1       = $502f

!addr SPR6_ADDR_L       = $5030
!addr SPR6_MODE_ADDR_H  = $5031
!addr SPR6_XPOS_L       = $5032
!addr SPR6_XPOS_H       = $5033
!addr SPR6_YPOS_L       = $5034
!addr SPR6_YPOS_H       = $5035
!addr SPR6_ATTR_0       = $5036
!addr SPR6_ATTR_1       = $5037

!addr SPR7_ADDR_L       = $5038
!addr SPR7_MODE_ADDR_H  = $5039
!addr SPR7_XPOS_L       = $503a
!addr SPR7_XPOS_H       = $503b
!addr SPR7_YPOS_L       = $503c
!addr SPR7_YPOS_H       = $503d
!addr SPR7_ATTR_0       = $503e
!addr SPR7_ATTR_1       = $503f

!addr SPR8_ADDR_L       = $5040
!addr SPR8_MODE_ADDR_H  = $5041
!addr SPR8_XPOS_L       = $5042
!addr SPR8_XPOS_H       = $5043
!addr SPR8_YPOS_L       = $5044
!addr SPR8_YPOS_H       = $5045
!addr SPR8_ATTR_0       = $5046
!addr SPR8_ATTR_1       = $5047

!addr SPR9_ADDR_L       = $5048
!addr SPR9_MODE_ADDR_H  = $5049
!addr SPR9_XPOS_L       = $504a
!addr SPR9_XPOS_H       = $504b
!addr SPR9_YPOS_L       = $504c
!addr SPR9_YPOS_H       = $504d
!addr SPR9_ATTR_0       = $504e
!addr SPR9_ATTR_1       = $504f

!addr SPR10_ADDR_L       = $5050
!addr SPR10_MODE_ADDR_H  = $5051
!addr SPR10_XPOS_L       = $5052
!addr SPR10_XPOS_H       = $5053
!addr SPR10_YPOS_L       = $5054
!addr SPR10_YPOS_H       = $5055
!addr SPR10_ATTR_0       = $5056
!addr SPR10_ATTR_1       = $5057

!addr SPR11_ADDR_L       = $5058
!addr SPR11_MODE_ADDR_H  = $5059
!addr SPR11_XPOS_L       = $505a
!addr SPR11_XPOS_H       = $505b
!addr SPR11_YPOS_L       = $505c
!addr SPR11_YPOS_H       = $505d
!addr SPR11_ATTR_0       = $505e
!addr SPR11_ATTR_1       = $505f

!addr SPR12_ADDR_L       = $5060
!addr SPR12_MODE_ADDR_H  = $5061
!addr SPR12_XPOS_L       = $5062
!addr SPR12_XPOS_H       = $5063
!addr SPR12_YPOS_L       = $5064
!addr SPR12_YPOS_H       = $5065
!addr SPR12_ATTR_0       = $5066
!addr SPR12_ATTR_1       = $5067

!addr SPR13_ADDR_L       = $5068
!addr SPR13_MODE_ADDR_H  = $5069
!addr SPR13_XPOS_L       = $506a
!addr SPR13_XPOS_H       = $506b
!addr SPR13_YPOS_L       = $506c
!addr SPR13_YPOS_H       = $506d
!addr SPR13_ATTR_0       = $506e
!addr SPR13_ATTR_1       = $506f

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