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
!addr EXPLOSION_ADDR    = $A200                   ;         6 Kb | 12 explosion sprites (32 rows x 16 bytes/row) ->  12 x 32 x 16  = $1800 bytes
!addr TEXT_ADDR         = $BA00                   ;        15 Kb | 15 text sprites      (64 rows x 16 bytes/row) ->  15 x 64 x 16  = $3C00 bytes
!addr BADGES_ADDR       = $F600                   ;       0.5 Kb | 2 badge sprites      (16 rows x 16 bytes/row) ->   2 x 16 x 16  =  $200 bytes
!addr IMAGE_ADDR        = $F800                   ;        37 Kb | 1 title image        (320x240 px x 2 px/byte) -> 320 x 240 x .5 = $9600 bytes
!addr TRAFFIC_ADDR      = $18E00                  ;       8.5 Kb | 17 other car sprites (32 rows x 16 bytes/row) ->  17 x 32 x 16  = $2200 bytes
                                                  ;Total 91.5 Kb of graphical resources

!addr FONT_ADDR         = $1F000

!addr CAR_PALETTES       = PALETTE + $20
!addr YCAR_PALETTE       = PALETTE + $20
!addr BCAR_PALETTE       = PALETTE + $40
!addr SPRITETEXT_PALETTE = PALETTE + $60
!addr TRACKS_PALETTE     = PALETTE + $80

;RAM Memory layout
;              $0810: zsmkit
;                   : Game Code 
;              $A000: RAM banks

;RAM banks
TRACK_BANK              = 1
BLOCK_BANK_0            = 2     ;blocks neeed 2 banks = 128 blocks of 128 bytes each
BLOCK_BANK_1            = 3
ZSM_TITLE_BANK          = 4     ;title tune takes 3 banks (23 KB)
ZSM_FINISHED_BANK       = 8     ;finished tune take 2 banks (11 KB)
SAVEDRACE_BANK          = 10
ZSMKIT_BANK             = 11

;Graphic resources to load
.tilesname              !text "TILES.BIN",0
.carsname               !text "CARS.BIN",0
.explosionname          !text "EXPLOSION.BIN",0
.textname               !text "TEXT.BIN",0
.badgesname             !text "BADGES.BIN",0
.blocksname             !text "BLOCKS.BIN",0
.tracksname             !text "TRACKS.BIN",0
.imagename              !text "IMAGE.BIN",0
.trafficname            !text "TRAFFIC.BIN",0
.savedracename          !text "SAVEDRACE.BIN",0
.fontname               !text "FONT.BIN",0

;Sound resources to load
.zsmtitle       !text "TITLE.ZSM",0
.zsmfinished    !text "FINISHED.ZSM",0

PlayMusic:                      ;IN: .A = memory bank where music is loaded     
        sta RAM_BANK
        ldx #0                  ;priority = 0
        lda #<BANK_ADDR
        ldy #>BANK_ADDR
        jsr zsm_setmem
        ldx #0
        jsr zsm_play   
        rts

StopMusic:
        ldx #0
        jsr zsm_stop
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
        +LoadResource .trafficname  , TRAFFIC_ADDR  , LOAD_TO_VRAM_BANK1, FILE_HAS_HEADER
        +LoadResource .fontname     , FONT_ADDR     , LOAD_TO_VRAM_BANK1, FILE_HAS_NO_HEADER
        lda #BLOCK_BANK_0
        sta RAM_BANK
        +LoadResource .blocksname   , BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_HEADER
        lda #TRACK_BANK
        sta RAM_BANK
        +LoadResource .tracksname   , BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_HEADER       
        lda #ZSM_TITLE_BANK
        sta RAM_BANK
        +LoadResource .zsmtitle     , BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_NO_HEADER
        lda #ZSM_FINISHED_BANK
        sta RAM_BANK
        +LoadResource .zsmfinished , BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_NO_HEADER
        lda #SAVEDRACE_BANK
        sta RAM_BANK
        +LoadResource .savedracename, BANK_ADDR     , LOAD_TO_RAM       , FILE_HAS_HEADER
        lda #TRACK_BANK
        sta RAM_BANK
        lda _fileerrorflag
        beq +
        sec                             ;set carry to flag error
        rts
+       clc                             ;clear carry to flag everything is ok
        rts