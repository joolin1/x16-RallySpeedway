;*** Init screen and sprites ************************************************************************

!addr MAP_ADDR          = $4000
!addr TILE_ADDR         = $6000  ;Room for 32 tiles. Now 23 tiles x 128 bytes each = 2944 bytes. (Tile mode 4bpp = 2 pixels per byte, tile 16x16 pixels = 8 bytes per row) 
!addr SPRITE_ADDR       = $8000
!addr CAR_PALETTES      = PALETTE + $20
!addr YCAR_PALETTE      = PALETTE + $20
!addr BCAR_PALETTE      = PALETTE + $40

COLLISION_MASK = %00010000

FILENAME=$05
FILENAME_L=$05
FILENAME_H=FILENAME_L+1
FILENAMELENGTH=$07

InitScreenAndSprites:
        stz VERA_CTRL
        jsr .CopySpritesToVRAM
        jsr .CopySpritePalettesToVRAM
        jsr LoadTiles
        ;jsr .CopyTilesToVRAM
        jsr .CopyCharactersToVRAM

        ;Display
        jsr VPoke                       ;set horizontal scale to 2:1
        !word DC_HSCALE
        !byte 64
        jsr VPoke                       ;set vertical scale to 2:1
        !word DC_VSCALE
        !byte 64

        jsr VPoke                       ;enable sprites globally           
        !word SPR_CTRL
        !byte 1

        ;Init text sprites
        lda #$00                        ;text sprites will begin att $8000 + 29 car and explosion sprites = $ba00 
        sta ZP0
        lda #$BA
        sta ZP1
        +DivideBy32 ZP0                 ;address of first sprite in ZP0 and ZP1

        lda #<SPR3_ADDR_L               ;low byte of address attribute for first text sprite
        sta ZP2

        ldx #10                         ;number of sprites
-       lda ZP2
        sta VERA_ADDR_LO
        lda #$50
        sta VERA_ADDR_MID
        lda #$1f
        sta VERA_ADDR_HI
        lda ZP0                         ;write address of sprite
        sta VERA_DATA0
        lda ZP1
        sta VERA_DATA0

        lda ZP0                         ;add 1024/32=32 to get address of next sprite
        clc
        adc #32
        sta ZP0
        lda ZP1
        adc #0
        sta ZP1

        lda ZP2                         ;add 8 to get address attribute of next sprite
        clc
        adc #8
        sta ZP2

        dex
        bne -

        +VPokeSpritesI SPR3_YPOS_L, 10, 98
        +VPokeSpritesI SPR3_YPOS_H, 10, 0

        +VPokeSpritesI SPR3_ATTR_0, 10, 0         ;disable all text sprites for now
        +VPokeSpritesI SPR3_ATTR_1, 10, %11100000 ;set height to 64 pixels and width to 32
        rts

RestoreScreenAndSprites:        ;Restore screen and sprites when user ends game
        jsr VPoke               ;set horizontal scale to 1:1
        !word DC_HSCALE
        !byte 128

        jsr VPoke               ;set vertical scale to 1:1
        !word DC_VSCALE
        !byte 128

        jsr VPoke               ;disable layer 0
        !word Ln0_CTRL0
        !byte 0

        jsr VPoke               ;enable layer 1 mode 0
        !word Ln1_CTRL0
        !byte 1                 

        jsr VPoke               ;disable sprites globally
        !word SPR_CTRL
        !byte 0

        rts


LoadTiles:
        lda #<.tilesname
        sta FILENAME_L
        lda #>.tilesname
        sta FILENAME_H
        lda #.end_tilesname-.tilesname
        sta FILENAMELENGTH
        jsr Vload ;$0,$00,$40
        rts

.tilesname     !raw "Rally/Graphics/tiles.bin"
.end_tilesname

Vload:
; ;.macro VLOAD bank, addrlo,addrhi
        lda FILENAMELENGTH
        ldx FILENAME_L
        ldy FILENAME_H
        jsr $FFBD   ;call SETNAM
        lda #$02
        ldx #$08;
        ldy #$00    ;load at mem addr defined 
        jsr $FFBA   ;call SETLFS
        lda #2;#bank+2 ;it's really like that (former meaning A: 0 = Load, 1-255 = Verify)
        ldx #$00;addrlo  
        ldy #$60;addrhi  
        jsr $FFD5   ;call LOAD
        bcs +
        rts
+       !byte $ff
        rts
; ;.endmacro
;         rts

;*** Private functions - Copy from RAM to VRAM *****************************************************

.CopySpritesToVRAM:
        lda #$00
        sta VERA_ADDR_LO
        lda #>SPRITE_ADDR     
        sta VERA_ADDR_MID
        lda #$10
        sta VERA_ADDR_HI

        lda #<.sprites
        sta ZP0
        lda #>.sprites
        sta ZP1

        ldx #0
-       ldy #0
--      lda (ZP0),y             ;loop through 256 bytes
        sta VERA_DATA0
        iny
        cpy #0
        bne --
        inc ZP1
        inx
        cpx #98                 ;(17 car sprites + 12 explosion sprites) x 32 rows x 16 bytes per row + 7 text sprites x 64 rows x 16 bytes per row = 98 x 256 
        bne -
        rts

.CopySpritePalettesToVRAM:
        lda #<CAR_PALETTES
        sta VERA_ADDR_LO
        lda #>CAR_PALETTES                       
        sta VERA_ADDR_MID
        lda #$1f                
        sta VERA_ADDR_HI                ;increment = 1

        ldy #0           
-       lda .carspritepalettes,y        ;loop through 2 * 16 colors * 2 bytes = 64
        sta VERA_DATA0     
        iny
        cpy #64             
        bne -
        rts

.CopyCharactersToVRAM:
        ;This is a simpler way! - but does not seem to work
        ;lda #0
        ;ldx #<_charset
        ;ldy #>_charset
        ;!byte $ff
        ;jsr screen_set_charset

	stz	VERA_CTRL
	lda	#$00		
	sta	VERA_ADDR_LO
	lda	#$F8		        ;base address of font is $F800
	sta	VERA_ADDR_MID
	lda	#$10		        ;increment by 1, bank 0
	sta	VERA_ADDR_HI
	lda	#<.charset	
	sta	ZP0
	lda	#>.charset
	sta	ZP1
	ldy	#64		        ;number of characters to replace in font
--	ldx	#8		        ;number of bytes in each character
-	lda	(ZP0)
	sta	VERA_DATA0
	lda	#1
	clc
	adc	ZP0
	sta	ZP0
	lda	#0
	adc	ZP1
	sta	ZP1
	dex
	bne	-		
	dey
	bne	--
	rts

.charset
        !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$38,$7c,$6c,$c6,$de,$de,$de
        !byte $00,$f8,$cc,$f8,$cc,$fe,$fe,$fc,$00,$7c,$e6,$c0,$e6,$fe,$fe,$7c
        !byte $00,$f8,$ec,$e6,$ee,$fe,$fe,$fc,$00,$f0,$c0,$f8,$c0,$fe,$fe,$fe
        !byte $00,$fe,$f0,$fc,$f0,$f0,$f0,$f0,$00,$7c,$e0,$ec,$e6,$fe,$fe,$7c
        !byte $00,$e6,$e6,$e6,$fe,$e6,$e6,$e6,$00,$fe,$38,$38,$38,$fe,$fe,$fe
        !byte $00,$06,$06,$e6,$e6,$fe,$fe,$7c,$00,$e4,$ec,$f8,$f8,$fc,$ee,$ee
        !byte $00,$c0,$c0,$c0,$c0,$fe,$fe,$fe,$00,$c6,$ee,$fe,$fe,$fe,$e6,$e6
        !byte $00,$e6,$e6,$f6,$fe,$fe,$ee,$e6,$00,$7c,$e6,$e6,$e6,$fe,$fe,$7c
        !byte $00,$fc,$e6,$e6,$fe,$fc,$f0,$f0,$00,$7c,$e6,$e6,$ee,$fc,$fe,$7e
        !byte $00,$fc,$e6,$e6,$fe,$fc,$ee,$ee,$00,$7c,$e0,$7c,$0e,$fe,$fe,$fc
        !byte $00,$fe,$fe,$fe,$38,$38,$38,$38,$00,$e6,$e6,$e6,$e6,$fe,$fe,$fe
        !byte $00,$e6,$e6,$e6,$e6,$7c,$7c,$38,$00,$e6,$e6,$e6,$fe,$fe,$ee,$c6
        !byte $00,$e6,$e6,$3c,$3c,$fe,$e6,$e6,$00,$e6,$e6,$fe,$7c,$38,$38,$38
        !byte $00,$7e,$1c,$38,$70,$fe,$fe,$fe,$00,$00,$00,$00,$00,$00,$00,$00
        !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$00,$00
        !byte $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        !byte $ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff
        !byte $ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$38,$38,$38,$18,$30,$00,$00
        !byte $df,$f0,$e3,$e7,$ee,$fb,$f0,$df,$ff,$00,$03,$fe,$03,$fe,$06,$fc
        !byte $fc,$02,$fc,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7c,$7c,$00,$00,$00
        !byte $00,$00,$00,$00,$00,$38,$38,$38,$00,$c0,$e0,$70,$38,$1c,$0e,$06
        !byte $00,$7c,$e6,$ee,$f6,$fe,$fe,$7c,$00,$38,$78,$38,$38,$fe,$fe,$fe
        !byte $00,$7c,$ce,$1c,$78,$fe,$fe,$fe,$00,$7e,$06,$1c,$c6,$fe,$fe,$7c
        !byte $00,$1c,$3c,$7c,$dc,$fe,$fe,$1c,$00,$fe,$e0,$fc,$06,$e6,$fe,$7c
        !byte $00,$7c,$e0,$fc,$e6,$fe,$fe,$7c,$00,$fe,$0e,$1e,$3c,$7c,$f8,$f8
        !byte $00,$7c,$ee,$7c,$ee,$fe,$fe,$7c,$00,$7c,$e6,$7e,$0e,$fe,$fc,$f8
        !byte $00,$38,$38,$38,$00,$38,$38,$38,$00,$00,$00,$00,$00,$00,$00,$00
        !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

.carspritepalettes
        !word $0000, $0000, $0EE7, $0EE7, $0FFF, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000    ;yellow car (color 2 = yellow)
        !word $0000, $0000, $008F, $008F, $0FFF, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000    ;blue car   (color 2 = light blue)

.sprites:
.carsprites:
        !bin "Rally/Graphics/rallycars.bin"
.explosionsprites:
        !bin "Rally/Graphics/rallyexplosion.bin"
.penaltysprites:
;        !bin "Rally/Graphics/rallytext.bin"
         !bin "Rally/Graphics/old-rallypenalty.bin"

