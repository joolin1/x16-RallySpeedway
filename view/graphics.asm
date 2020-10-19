;*** Load graphic resources to VRAM ****************************************************************

;Memory layout for screen and graphic resources
!addr L1_MAP_ADDR       = $0000                   ;         8 Kb | Layer 1 - the original text layer is by default located at $0000 an in front of layer 0
                                                  ;              | 80 cols (each 256 bytes) x 60 rows = 256 x 60 = $3c00 bytes but we only use 30 rows and 256 x 30 = 7680 bytes
!addr L0_MAP_ADDR       = $2000                   ;         8 Kb | Layer 0 - game graphics layer. Both used in tile mode and text mode.
                                                  ;              |           text mode: 40 cols (each 256 bytes) x 30 rows = 7680 bytes
                                                  ;              |           tile mode: 32 cols (each 64 bytes)  x 32 rows = 2048 bytes
!addr L0_MAP_ADDR_2     = $2800                   ;              | Layer 0 - The lower half of the tilemap can be used as a second buffer because only the upper half (the first 16 rows) are displayed.
                                                  ;Total   16 Kb of screen memory
                                                  
!addr TILES_ADDR        = $4000                   ;        16 Kb | room for 128 tiles   (16 rows x  8 bytes/row) -> 128 x 16 x  8 = $4000 bytes
!addr CARS_ADDR         = $8000                   ;       8.5 Kb | 17 car sprites       (32 rows x 16 bytes/row) ->  17 x 32 x 16 = $2200 bytes 
!addr EXPLOSION_ADDR    = CARS_ADDR + $2200       ;         6 Kb | 12 explosion sprites (32 rows x 16 bytes/row) ->  12 x 32 x 16 = $1800 bytes
!addr TEXT_ADDR         = EXPLOSION_ADDR + $1800  ;        15 Kb | 15 text sprites      (64 rows x 16 bytes/row) ->  15 x 64 x 16 = $3C00 bytes
!addr BADGES_ADDR       = TEXT_ADDR + $3C00       ;       0.5 Kb | 2 badge sprites      (16 rows x 16 bytes/row) ->   2 x 16 x 16 =  $200 bytes
                                                  ;  Total 46 Kb of graphical resources

!addr CAR_PALETTES       = PALETTE + $20
!addr YCAR_PALETTE       = PALETTE + $20
!addr BCAR_PALETTE       = PALETTE + $40
!addr SPRITETEXT_PALETTE = PALETTE + $60
!addr TRACKS_PALETTE     = PALETTE + $80

;Graphic resources to load
.tilesname              !raw "TILES.BIN",0
.carsname               !raw "CARS.BIN",0
.explosionname          !raw "EXPLOSION.BIN",0
.textname               !raw "TEXT.BIN",0
.badgesname             !raw "BADGES.BIN",0
.blocksname             !raw "BLOCKS.BIN",0
.tracksname             !raw "TRACKS.BIN",0

.errorflag      !byte   0   ;at least one i/o error has occurred if set

LoadGraphics:
        stz .errorflag
        jsr .LoadTiles
        jsr .LoadCars
        jsr .LoadExplosion
        jsr .LoadText
        jsr .LoadBadges
        jsr .LoadBlocks
        jsr .LoadTracks
        lda .errorflag
        beq +
        sec                             ;set carry to flag error
        rts
+       jsr .CopyPalettesToVRAM
        lda #0
        ldx #<.charset
        ldy #>.charset
        jsr screen_set_charset
        clc                             ;clear carry to flag everything is ok
        rts

.LoadTiles:
        lda #<.tilesname
        sta ZP0
        lda #>.tilesname
        sta ZP1
        lda #<TILES_ADDR
        sta ZP2
        lda #>TILES_ADDR
        sta ZP3
        jsr .VLoad
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
        jsr .VLoad
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
        jsr .VLoad
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
        jsr .VLoad
        rts

.LoadBadges:
        lda #<.badgesname
        sta ZP0
        lda #>.badgesname
        sta ZP1
        lda #<BADGES_ADDR
        sta ZP2
        lda #>BADGES_ADDR
        sta ZP3
        jsr .VLoad
        rts

.LoadBlocks:
        lda #<.blocksname
        sta ZP0
        lda #>.blocksname
        sta ZP1
        lda #<_blocks
        sta ZP2
        lda #>_blocks
        sta ZP3
        jsr .Load       ;blocks are located in RAM (tiles in VRAM)
        rts

.LoadTracks:
        lda #<.tracksname
        sta ZP0
        lda #>.tracksname
        sta ZP1
        lda #<_trackdata
        sta ZP2
        lda #>_trackdata
        sta ZP3
        jsr .Load       ;tracks are located in RAM
        rts

.Load:
        jsr LoadFile                   ;call filehandler
        bcc +
        jsr PrintIOErrorMessage
        lda #1
        sta .errorflag
+       rts

.VLoad:
        jsr VLoadFile                   ;call filehandler
        bcc +
        jsr PrintIOErrorMessage
        lda #1
        sta .errorflag
+       rts

.CopyPalettesToVRAM:
        lda #<PALETTE
        sta VERA_ADDR_L
        lda #>PALETTE                       
        sta VERA_ADDR_M
        lda #$11                
        sta VERA_ADDR_H                 ;increment = 1

        ldy #0           
-       lda .palettes,y        ;loop through 5 palettes * 16 colors * 2 bytes = 160
        sta VERA_DATA0     
        iny
        cpy #160             
        bne -
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
        !byte $00,$1c,$38,$70,$70,$70,$38,$1c,$00,$70,$38,$1c,$1c,$1c,$38,$70
        !byte $00,$c6,$38,$fe,$38,$c6,$00,$00,$00,$30,$30,$fc,$fc,$30,$30,$00
        !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7c,$7c,$00,$00,$00
        !byte $00,$00,$00,$00,$00,$38,$38,$38,$00,$06,$0e,$1c,$38,$70,$e0,$c0
        !byte $00,$7c,$e6,$ee,$f6,$fe,$fe,$7c,$00,$38,$78,$38,$38,$fe,$fe,$fe
        !byte $00,$7c,$ce,$1c,$78,$fe,$fe,$fe,$00,$7e,$06,$1c,$c6,$fe,$fe,$7c
        !byte $00,$1c,$3c,$7c,$dc,$fe,$fe,$1c,$00,$fe,$e0,$fc,$06,$e6,$fe,$7c
        !byte $00,$7c,$e0,$fc,$e6,$fe,$fe,$7c,$00,$fe,$0e,$1e,$3c,$7c,$f8,$f8
        !byte $00,$7c,$ee,$7c,$ee,$fe,$fe,$7c,$00,$7c,$e6,$7e,$0e,$fe,$fc,$f8
        !byte $00,$38,$38,$38,$00,$38,$38,$38,$00,$00,$00,$00,$00,$00,$fe,$fe
        !byte $df,$f0,$e3,$e7,$ee,$fb,$f0,$df,$ff,$00,$03,$fe,$03,$fe,$06,$fc
        !byte $fc,$02,$fc,$00,$00,$00,$00,$00,$7c,$fe,$c6,$1c,$38,$00,$38,$38

.palettes                                       ;$00c5
        !word $0000, $0fff, $0800, $0afe, $0c4c, $0080, $000a, $0ee7, $0d85, $0640, $0f77, $0000, $0777, $0af6, $008f, $0bbb    ;user interface (C64 palette but 11 = black instead of dark grey)
.carspritepalettes
        !word $0000, $0000, $0EE7, $0afe, $0c4c, $00c5, $000a, $0ee7, $0d85, $0640, $0f77, $0333, $0777, $0af6, $008f, $0bbb    ;yellow car (C64 palette but 1 = black, 2 = yellow)
        !word $0000, $0000, $008F, $0afe, $0c4c, $00c5, $000a, $0ee7, $0d85, $0640, $0f77, $0333, $0777, $0af6, $008f, $0bbb    ;blue car   (C64 palette but 1 = black, 2 = light blue)
.spritetextpalette
        !word $0000, $0000, $0666, $0afe, $0c4c, $00c5, $000a, $0ee7, $0d85, $0640, $0f77, $0333, $0777, $0af6, $008f, $0bbb    ;sprite text (C64 palette but 1 = black, 2 = grey)
.trackpalette
        !word $0000, $0000, $0334, $0A33, $0453, $0B42, $0171, $0666, $06B5, $0BBB, $06E6, $0CF0, $0BF6, $0FFF, $0000, $0000    ;tiles
