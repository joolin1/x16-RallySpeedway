;*** Load graphic resources to VRAM ****************************************************************

;Memory layout for screen and graphic resources
!addr MAP_ADDR          = $4000
!addr TILE_ADDR         = $6000                     ;Room for 32 tiles. Now 23 tiles x 128 bytes each = 2944 bytes. (Tile mode 4bpp = 2 pixels per byte, tile 16x16 pixels = 8 bytes per row) 
!addr CARS_ADDR         = $8000                     ;17 car sprites       (32 rows x 16 bytes/row) -> 17 x 32 x 16 = $2200 bytes 
!addr EXPLOSION_ADDR    = CARS_ADDR + $2200         ;12 explosion sprites (32 rows x 16 bytes/row) -> 12 x 32 x 16 = $1800 bytes
!addr TEXT_ADDR         = EXPLOSION_ADDR + $1800    ;10 text sprites      (64 rows x 16 bytes/row) -> 10 x 64 x 16 = $2800 bytes
!addr SPRITE_ADDR       = $8000

;(17 car sprites + 12 explosion sprites) x 32 rows x 16 bytes per row + 7 text sprites x 64 rows x 16 bytes per row = 98 x 256 

!addr CAR_PALETTES      = PALETTE + $20
!addr YCAR_PALETTE      = PALETTE + $20
!addr BCAR_PALETTE      = PALETTE + $40

;Graphic resources to load
.tilesname              !raw "x16-rallyspeedway/tiles.bin"
.end_tilesname
.carsname               !raw "x16-rallyspeedway/cars.bin"
.end_carsname
.explosionname          !raw "x16-rallyspeedway/explosion.bin"
.end_explosionname
.textname               !raw "x16-rallyspeedway/text.bin"
.end_textname

.filename_lo             = ZP0
.filename_hi             = ZP1
.filenamelength          = ZP2
.loadaddr_lo             = ZP3
.loadaddr_hi             = ZP4

LoadGraphics:
        jsr .LoadTiles
        jsr .LoadCars
        jsr .LoadExplosion
        jsr .LoadText
        jsr .CopySpritePalettesToVRAM
        jsr .CopyCharactersToVRAM
        rts

.LoadTiles:
        lda #<.tilesname
        sta .filename_lo
        lda #>.tilesname
        sta .filename_hi
        lda #.end_tilesname-.tilesname
        sta .filenamelength
        lda #<TILE_ADDR
        sta .loadaddr_lo
        lda #>TILE_ADDR
        sta .loadaddr_hi
        jsr .Vload
        rts

.LoadCars:
        lda #<.carsname
        sta .filename_lo
        lda #>.carsname
        sta .filename_hi
        lda #.end_carsname-.carsname
        sta .filenamelength
        lda #<CARS_ADDR
        sta .loadaddr_lo
        lda #>CARS_ADDR
        sta .loadaddr_hi
        jsr .Vload
        rts

.LoadExplosion:
        lda #<.explosionname
        sta .filename_lo
        lda #>.explosionname
        sta .filename_hi
        lda #.end_explosionname-.explosionname
        sta .filenamelength
        lda #<EXPLOSION_ADDR
        sta .loadaddr_lo
        lda #>EXPLOSION_ADDR
        sta .loadaddr_hi
        jsr .Vload
        rts

.LoadText:
        lda #<.textname
        sta .filename_lo
        lda #>.textname
        sta .filename_hi
        lda #.end_textname-.textname
        sta .filenamelength
        lda #<TEXT_ADDR
        sta .loadaddr_lo
        lda #>TEXT_ADDR
        sta .loadaddr_hi
        jsr .Vload
        rts

.Vload:
        lda .filenamelength
        ldx .filename_lo
        ldy .filename_hi
        jsr SETNAM
        lda #$02
        ldx #$08            ;device
        ldy #$00  
        jsr SETLFS
        lda #2              ;0 = load, 1 - verify, 2 - VRAM bank 0, 3 - VRAM bank 1...
        ldx .loadaddr_lo    ;low address  
        ldy .loadaddr_hi    ;high address  
        jsr LOAD
        bcs +               ;branch if error
        rts
+       !byte $ff
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


