;*** Load graphic resources to VRAM ****************************************************************

;Memory layout for screen and graphic resources
!addr L1_MAP_ADDR       = $0000                   ;         8 Kb | Layer 1 - the original text layer is by default located at $0000 an in front of layer 0
                                                  ;              | 80 cols (each 256 bytes) x 60 rows = 256 x 60 = $3c00 bytes but we only use 30 rows and 256 x 30 = $1e00
!addr L0_MAP_ADDR       = $2000                   ;         8 Kb | Layer 0 - game graphics layer. Both used in tile mode and text mode
                                                  ;Total   16 Kb of screen memory
                                                  
!addr TILE_ADDR         = $4000                   ;        16 Kb | room for 128 tiles   (16 rows x  8 bytes/row) -> 128 x 16 x  8 = $4000 bytes
!addr CARS_ADDR         = $8000                   ;       8.5 Kb | 17 car sprites       (32 rows x 16 bytes/row) ->  17 x 32 x 16 = $2200 bytes 
!addr EXPLOSION_ADDR    = CARS_ADDR + $2200       ;         6 Kb | 12 explosion sprites (32 rows x 16 bytes/row) ->  12 x 32 x 16 = $1800 bytes
!addr TEXT_ADDR         = EXPLOSION_ADDR + $1800  ;        14 Kb | 14 text sprites      (64 rows x 16 bytes/row) ->  14 x 64 x 16 = $3800 bytes
                                                  ;Total 44.5 Kb of graphical resources

!addr CAR_PALETTES      = PALETTE + $20
!addr YCAR_PALETTE      = PALETTE + $20
!addr BCAR_PALETTE      = PALETTE + $40

;Graphic resources to load
.tilesname              !raw "X16-RALLYSPEEDWAY/TILES.BIN",0
.carsname               !raw "X16-RALLYSPEEDWAY/CARS.BIN",0
.explosionname          !raw "X16-RALLYSPEEDWAY/EXPLOSION.BIN",0
.textname               !raw "X16-RALLYSPEEDWAY/TEXT.BIN",0
.leaderboardname        !raw "X16-RALLYSPEEDWAY/LEADERBOARD.BIN",0

; .filename_lo            !byte   0
; .filename_hi            !byte   0
; .loadaddr_lo            !byte   0
; .loadaddr_hi            !byte   0

;Error messages
.message1       !scr 13,"FAILED TO LOAD ",0
.message2       !scr 13,"I/O ERROR #",0
.errorarray     !scr 0
                !scr ": TOO MANY FILES",0
                !scr ": FILE OPEN",0
                !scr ": FILE NOT OPEN",0
                !scr ": FILE NOT FOUND",0
                !scr ": DEVICE NOT PRESENT",0
                !scr ": NOT INPUT FILE",0
                !scr ": NOT OUTPUT FILE",0
                !scr ": MISSING FILENAME",0
                !scr ": ILLEGAL DEVICE NUMBER",0

.errorflag      !byte   0   ;at least one i/o error has occurred if set

LoadGraphics:
        stz .errorflag
        jsr .LoadTiles
        jsr .LoadCars
        jsr .LoadExplosion
        jsr .LoadText
        jsr .LoadLeaderboard
        lda .errorflag
        beq +
        sec                             ;set carry to flag error
        rts
+       jsr .CopySpritePalettesToVRAM
        jsr .CopyCharactersToVRAM
        clc                             ;clear carry to flag everything is ok
        rts

.LoadTiles:
        lda #<.tilesname
        sta ZP0
        lda #>.tilesname
        sta ZP1
        lda #<TILE_ADDR
        sta ZP2
        lda #>TILE_ADDR
        sta ZP3
        jsr .Vload
        rts

.LoadCars:
        lda #<.carsname
        sta ZP0
        lda #>.carsname
        sta ZP1
        lda #<CARS_ADDR
        sta ZP2
        lda #>CARS_ADDR
        sta ZP3
        jsr .Vload
        rts

.LoadExplosion:
        lda #<.explosionname
        sta ZP0
        lda #>.explosionname
        sta ZP1
        lda #<EXPLOSION_ADDR
        sta ZP2
        lda #>EXPLOSION_ADDR
        sta ZP3
        jsr .Vload
        rts

.LoadText:
        lda #<.textname
        sta ZP0
        lda #>.textname
        sta ZP1
        lda #<TEXT_ADDR
        sta ZP2
        lda #>TEXT_ADDR
        sta ZP3
        jsr .Vload
        rts

.LoadLeaderboard
        lda #<.leaderboardname
        sta ZP0
        lda #>.leaderboardname
        sta ZP1
        lda #<_leaderboard
        sta ZP2
        lda #>_leaderboard
        sta ZP3
        lda #0
        sta ZP4
        jsr .Load
        rts

SaveLeaderboard
        lda #<.leaderboardname
        sta ZP0
        lda #>.leaderboardname
        sta ZP1
        lda #<_leaderboard
        sta ZP2
        lda #>_leaderboard
        sta ZP3
        lda #<_leaderboard_end
        sta ZP4
        lda #>_leaderboard_end
        sta ZP5
        jsr .Save
        rts  

.Vload:                         
        lda #2                  ;2 = VRAM bank 0
        sta ZP4
        jsr .Load
        rts

.Load:                          ;IN: ZP0, ZP1 = filename, ZP2, ZP3 = load address, ZP4 = ;0 = load, 1 = verify, 2 = VRAM bank 0, 3 = VRAM bank 1...
        ldx ZP0                 ;filename
        ldy ZP1
        jsr GetStringLength     ;will return length of filename in .A
        jsr SETNAM
        lda #$02
        ldx #$08                ;device
        ldy #$00  
        jsr SETLFS
        ldx ZP2                 ;load address  
        ldy ZP3  
        lda ZP4                 ;load details
        jsr LOAD
        bcc +
        jsr .PrintErrorMessage
        lda #1
        sta .errorflag
+       rts

.Save:                                  ;IN: ZP0, ZP1 = filename, ZP2, ZP3 = save address, ZP4, ZP5 = end address+1
        ldx ZP0                         ;filename
        ldy ZP1
        jsr GetStringLength             ;will return length of filename in .A
        jsr SETNAM
        lda #$02
        ldx #$08                        ;device
        ldy #$00  
        jsr SETLFS
        lda #2                          ;address of zero page register holding start address
        ldx ZP4                         ;end address+1  
        ldy ZP5                   
        jsr SAVE
        bcc +
        ;no error handling...
+       rts

.PrintErrorMessage:                     ;IN: .A = error number, ZP0, ZP1 = filename
        pha
        ldx ZP0
        ldy ZP1
        phx
        phy
        ldx #<.message1
        ldy #>.message1
        jsr KPrintString                ;print "failed to load"          
        ply
        plx
        jsr KPrintString                ;print filename
        ldx #<.message2
        ldy #>.message2
        jsr KPrintString                ;print "i/o error"
        pla
        pha
        jsr KPrintDigit                 ;print error number
        pla
        ldx #<.errorarray
        ldy #>.errorarray
        jsr KPrintStringArrayElement    ;print error message
        rts   

.CopySpritePalettesToVRAM:
        lda #<CAR_PALETTES
        sta VERA_ADDR_L
        lda #>CAR_PALETTES                       
        sta VERA_ADDR_M
        lda #$11                
        sta VERA_ADDR_H                 ;increment = 1

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
    ;jsr screen_set_charset

	stz	VERA_CTRL
	lda	#$00		
	sta	VERA_ADDR_L
	lda	#$F8		        ;base address of font is $F800
	sta	VERA_ADDR_M
	lda	#$10		        ;increment by 1, bank 0
	sta	VERA_ADDR_H
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
        !byte $00,$7e,$1c,$38,$70,$fe,$fe,$fe,$f0,$f0,$f0,$f0,$00,$00,$00,$00
        !byte $0f,$0f,$0f,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0
        !byte $00,$00,$00,$00,$0f,$0f,$0f,$0f,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
        !byte $00,$00,$00,$00,$00,$00,$00,$00,$38,$38,$38,$38,$38,$00,$38,$38
        !byte $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        !byte $ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$00,$00
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