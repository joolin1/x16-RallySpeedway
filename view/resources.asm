;*** Load resources ********************************************************************************

;VRAM Memory layout for screen and graphic resources
!addr L1_MAP_ADDR       = $0000                   ;         8 Kb | Layer 1 - the original text layer is by default located at $0000 an in front of layer 0
                                                  ;              | 80 cols (each 256 bytes) x 60 rows = 256 x 60 = $3c00 bytes but we only use 30 rows and 256 x 30 = 7680 bytes
!addr L0_MAP_ADDR       = $2000                   ;         8 Kb | Layer 0 - game graphics layer. Both used in tile mode and text mode.
                                                  ;              |           text mode: 40 cols (each 256 bytes) x 30 rows = 7680 bytes
                                                  ;              |           tile mode: 32 cols (each 64 bytes)  x 32 rows = 2048 bytes
!addr L0_MAP_ADDR_2     = $2800                   ;              | Layer 0 - The lower half of the tilemap can be used as a second buffer because only the upper half (the first 16 rows) are displayed.
                                                  ;Total   16 Kb of screen memory
                                                  
!addr TILES_ADDR        = $4000                   ;        16 Kb | room for 128 tiles   (16 rows x  8 bytes/row) -> 128 x 16 x  8  = $4000 bytes
!addr CARS_ADDR         = $8000                   ;       8.5 Kb | 17 car sprites       (32 rows x 16 bytes/row) ->  17 x 32 x 16  = $2200 bytes 
!addr EXPLOSION_ADDR    = CARS_ADDR + $2200       ;         6 Kb | 12 explosion sprites (32 rows x 16 bytes/row) ->  12 x 32 x 16  = $1800 bytes
!addr TEXT_ADDR         = EXPLOSION_ADDR + $1800  ;        15 Kb | 15 text sprites      (64 rows x 16 bytes/row) ->  15 x 64 x 16  = $3C00 bytes
!addr BADGES_ADDR       = TEXT_ADDR + $3C00       ;       0.5 Kb | 2 badge sprites      (16 rows x 16 bytes/row) ->   2 x 16 x 16  =  $200 bytes
!addr IMAGE_ADDR        = BADGES_ADDR + $200      ;        37 Kb | 1 title image        (320x240 px x 2 px/byte) -> 320 x 240 x .5 = $9600 bytes
                                                  ;  Total 83 Kb of graphical resources

!addr CAR_PALETTES       = PALETTE + $20
!addr YCAR_PALETTE       = PALETTE + $20
!addr BCAR_PALETTE       = PALETTE + $40
!addr SPRITETEXT_PALETTE = PALETTE + $60
!addr TRACKS_PALETTE     = PALETTE + $80

;Graphic resources to load
.tilesname              !text "TILES.BIN",0
.carsname               !text "CARS.BIN",0
.explosionname          !text "EXPLOSION.BIN",0
.textname               !text "TEXT.BIN",0
.badgesname             !text "BADGES.BIN",0
.blocksname             !text "BLOCKS.BIN",0
.tracksname             !text "TRACKS.BIN",0
.imagename              !text "IMAGE.BIN",0

;RAM Memory layout for graphic and music resources
;              $0810: game code
;              $9766: ZSound
;              $A000: RAM banks containing tracks, blocks, music and race recordings

TRACK_BANK              = 1
BLOCK_BANK_0            = 2     ;blocks neeed 2 banks = 128 blocks of 128 bytes each
BLOCK_BANK_1            = 3
ZSM_TITLE_BANK          = 4
ZSM_MENU_BANK           = 5
ZSM_NAMEENTRY_BANK      = 6
RACE_RECORDING_BANK     = 7

;Sound resources to load
.zsoundname     !text "ZSOUND.BIN",0
.zsmtitle       !text "TITLE.ZSM",0
.zsmmenu        !text "MENU.ZSM",0
.zsmnameentry   !text "NAMEENTRY.ZSM",0

StartMusic:              ;IN: .A = ram bank
	ldx #<BANK_ADDR
	ldy #>BANK_ADDR
	jsr Z_startmusic
        rts

_fileerrorflag      !byte   0   ;at least one i/o error has occurred if set

!macro LoadResource .filename, .addr, .ramtype, .header {
        lda #<.filename
        sta ZP0
        lda #>.filename
        sta ZP1
        lda #<.addr
        sta ZP2
        lda #>.addr
        sta ZP3
        lda #.ramtype
        sta ZP4
        lda #.header
        sta ZP5
        jsr LoadFile                   ;call filehandler
        bcc +
        jsr PrintIOErrorMessage
        lda #1
        sta _fileerrorflag
+
}

LoadResources:
        stz _fileerrorflag
        +LoadResource .tilesname    , TILES_ADDR    , LOAD_TO_VRAM_BANK0, FILE_HAS_HEADER
        +LoadResource .carsname     , CARS_ADDR     , LOAD_TO_VRAM_BANK0, FILE_HAS_HEADER
        +LoadResource .explosionname, EXPLOSION_ADDR, LOAD_TO_VRAM_BANK0, FILE_HAS_HEADER
        +LoadResource .textname     , TEXT_ADDR     , LOAD_TO_VRAM_BANK0, FILE_HAS_HEADER
        +LoadResource .badgesname   , BADGES_ADDR   , LOAD_TO_VRAM_BANK0, FILE_HAS_HEADER
        +LoadResource .imagename    , IMAGE_ADDR    , LOAD_TO_VRAM_BANK0, FILE_HAS_HEADER
        +LoadResource .zsoundname   , ZSOUND_ADDR   , LOAD_TO_RAM       , FILE_HAS_HEADER
        lda #BLOCK_BANK_0
        sta RAM_BANK
        +LoadResource .blocksname   , BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_HEADER
        lda #TRACK_BANK
        sta RAM_BANK
        +LoadResource .tracksname   , BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_HEADER       
        lda #ZSM_TITLE_BANK
        sta RAM_BANK
        +LoadResource .zsmtitle     , BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_NO_HEADER
        lda #ZSM_MENU_BANK
        sta RAM_BANK
        +LoadResource .zsmmenu      , BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_NO_HEADER
        lda #ZSM_NAMEENTRY_BANK
        sta RAM_BANK
        +LoadResource .zsmnameentry , BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_NO_HEADER
        lda #TRACK_BANK
        sta RAM_BANK
        lda _fileerrorflag
        beq +
        sec                             ;set carry to flag error
        rts
+       clc                             ;clear carry to flag everything is ok
        rts

_charset:
        !byte $00,$00,$00,$00,$00,$00,$fe,$fe,$00,$38,$7c,$6c,$c6,$de,$de,$de
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
        !byte $00,$38,$38,$38,$00,$38,$38,$38,$38,$28,$7c,$6c,$c6,$de,$de,$de
        !byte $df,$f0,$e3,$e7,$ee,$fb,$f0,$df,$ff,$00,$03,$fe,$03,$fe,$06,$fc
        !byte $fc,$02,$fc,$00,$00,$00,$00,$00,$7c,$fe,$c6,$1c,$38,$00,$38,$38