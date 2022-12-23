;*** soundfx.asm ***********************************************************************************

PLAYING_YENGINE     = 0
PLAYING_BENGINE     = 1
PLAYING_YSKIDDING1  = 2
PLAYING_YSKIDDING2  = 3
PLAYING_BSKIDDING1  = 4
PLAYING_BSKIDDING2  = 5
PLAYING_CLASH       = 6
PLAYING_OUTRUN1     = 7
PLAYING_OUTRUN2     = 8
PLAYING_EXPLOSION   = 9
PLAYING_WINNER1     = 10
PLAYING_WINNER2     = 11

_playingtable   !fill 12,0      ;boolean table for sound effects (NOTE: Make sure to reserv the same number of bytes as number of sound effects)

!macro SfxPlay .playing_fx, .voice, .length, .repeat, .data, .index, .delay { ;IN: 4 immediate values and 3 vectors
        ldy #.playing_fx
        lda _playingtable,y
        beq +++                 ;exit if this sound isn't playing
        lda .delay
        beq +                   ;read new sound data if delay = 0
        dec .delay
        bra +++

+       lda .index
        cmp #.length*5          ;reached end of sound data?
        bne ++
        lda #.repeat
        beq +                   ;should sound be repeated?
        stz .index              ;yes, start from the beginning
        bra ++
+       ldy #.playing_fx
        lda #0
        sta _playingtable,y     ;no, stop sound
        lda #.voice             
        jsr StopSound
        bra +++

++      lda #<PSG_ADDR_V8       ;start with base address of PSG (voice 8 and upwards are used)
        sta ZP0
        lda #>PSG_ADDR_V8
        sta ZP1
        lda #.voice
        asl
        asl
        clc
        adc ZP0                 ;add voice number*4 because each voice has four addresses to write to
        sta ZP0
        lda #0
        adc ZP1
        sta ZP1

        lda ZP0                 ;set start voice address
        sta VERA_ADDR_L
        lda ZP1
        sta VERA_ADDR_M
        lda #$11                ;auto increment one
        sta VERA_ADDR_H

        ldy .index              ;read data from table and stor in addresses of the voice
        lda .data,y
        ldx #.playing_fx
        jsr AdjustEngineSound   ;if engine sound, change frequency according to speed            
        sta VERA_DATA0
        iny
        lda .data,y             
        sta  VERA_DATA0
        iny
        lda .data,y          
        sta VERA_DATA0
        iny
        lda .data,y       
        sta VERA_DATA0
        iny
        lda .data,y
        sta .delay              ;set how many jiffies this data should sound
        iny
        sty .index              
+++     nop     
}

AdjustEngineSound:
        cpx #PLAYING_YENGINE
        bne +
        sta ZP0
        lda _ycarspeed
        asl
        clc
        adc ZP0
        rts
+       cpx #PLAYING_BENGINE
        bne +
        sta ZP0
        lda _bcarspeed
        asl
        clc
        adc ZP0
+       rts

StopSound:                      ;IN: .A = voice to silence      
        ldx #<PSG_ADDR_V8       ;start with base address of PSG (voice 8 and upwards are used)
        stx ZP0
        ldx #>PSG_ADDR_V8
        stx ZP1
        asl
        asl
        clc
        adc ZP0                 ;add voice number*4 because each voice has four addresses to write to
        sta ZP0
        lda #0
        adc ZP1
        sta ZP1
        lda ZP0                 ;set start voice address
        sta VERA_ADDR_L
        lda ZP1
        sta VERA_ADDR_M
        lda #$11                ;auto increment one
        sta VERA_ADDR_H
        stz VERA_DATA0          ;set all registers of voice to 0
        stz VERA_DATA0
        stz VERA_DATA0
        stz VERA_DATA0
        rts

PlayYCarEngineSound:
        ldy #PLAYING_YENGINE
        lda #1
        sta _playingtable,y
        stz .yengine_index
        stz .yengine_delay
        rts

.yengine_index          !byte 0
.yengine_delay          !byte 0

PlayBCarEngineSound:
        ldy #PLAYING_BENGINE
        lda #1
        sta _playingtable,y
        stz .bengine_index
        stz .bengine_delay
        rts

.bengine_index          !byte 0
.bengine_delay          !byte 0

StopCarSounds:
        jsr StopYCarSounds ;stop all car sounds. When race is interrupted by outdistancing, collision or race over, cars should be immediately silent
        jsr StopBCarSounds
        rts

StopYCarSounds:            ;stop these sounds when yellow car has finished and slowed down
        lda #0
        ldy #PLAYING_YENGINE
        sta _playingtable,y
        ldy #PLAYING_YSKIDDING1
        sta _playingtable,y
        sta _playingtable+1,y
        lda #0                  ;silence all voices that are used by yellow car
        jsr StopSound           
        lda #2
        jsr StopSound
        lda #3
        jsr StopSound
        rts

StopBCarSounds:              
        lda #0
        ldy #PLAYING_BENGINE
        sta _playingtable,y
        ldy #PLAYING_BSKIDDING1
        sta _playingtable,y
        sta _playingtable+1,y
        lda #1                  ;silence all voices that are used by blue car
        jsr StopSound
        lda #4
        jsr StopSound
        lda #5
        jsr StopSound
        rts

PlayYCarSkiddingSound:
        ldy #PLAYING_YSKIDDING1
        lda #1
        sta _playingtable,y
        sta _playingtable+1,y
        stz .yskidding1_index
        stz .yskidding1_delay
        stz .yskidding2_index
        stz .yskidding2_delay
        rts

.yskidding1_index        !byte 0
.yskidding1_delay        !byte 0
.yskidding2_index        !byte 0
.yskidding2_delay        !byte 0

StopYCarSkiddingSound:          ;Skidding is a repeating sound, therefore a special routine for stopping the sound is necessary
        ldy #PLAYING_YSKIDDING1
        lda #0
        sta _playingtable,y
        sta _playingtable+1,y
        lda #2
        jsr StopSound
        lda #3
        jsr StopSound
        rts

PlayBCarSkiddingSound:
        ldy #PLAYING_BSKIDDING1
        lda #1
        sta _playingtable,y
        sta _playingtable+1,y
        stz .bskidding1_index
        stz .bskidding1_delay
        stz .bskidding2_index
        stz .bskidding2_delay
        rts

.bskidding1_index        !byte 0
.bskidding1_delay        !byte 0
.bskidding2_index        !byte 0
.bskidding2_delay        !byte 0

StopBCarSkiddingSound:                  ;Skidding is a repeating sound, therefore a special routine for stopping the sound is necessary
        ldy #PLAYING_BSKIDDING1
        lda #0
        sta _playingtable,y
        sta _playingtable+1,y
        lda #4
        jsr StopSound
        lda #5
        jsr StopSound
        rts

PlayClashSound:
        ldy #PLAYING_CLASH
        lda #1
        sta _playingtable,y
        stz .clash_index
        stz .clash_delay
        rts

.clash_index            !byte 0
.clash_delay            !byte 0

PlayOutrunSound:
        ldy #PLAYING_OUTRUN1
        lda #1
        sta _playingtable,y
        stz .outrun1_index
        stz .outrun1_delay
        ldy #PLAYING_OUTRUN2          ;use two voices
        lda #1
        sta _playingtable,y
        stz .outrun2_index
        stz .outrun2_delay
        rts

.outrun1_index           !byte 0
.outrun1_delay           !byte 0
.outrun2_index           !byte 0
.outrun2_delay           !byte 0

PlayExplosionSound:
        ldy #PLAYING_EXPLOSION
        lda #1
        sta _playingtable,y
        stz .explosion_index
        stz .explosion_delay
        rts

.explosion_index        !byte 0
.explosion_delay        !byte 0

; PlayFinishedSound:
;         ldy #PLAYING_WINNER1
;         lda #1
;         sta _playingtable,y
;         stz .winner1_index
;         stz .winner1_delay
;         ldy #PLAYING_WINNER2            ;use two voices
;         lda #1
;         sta _playingtable,y
;         stz .winner2_index
;         stz .winner2_delay
;         rts

.winner1_index           !byte 0
.winner1_delay           !byte 0
.winner2_index           !byte 0
.winner2_delay           !byte 0

SfxTick:
                ;sound fx            voice length           repeat? data          
        +SfxPlay PLAYING_YENGINE,      0,  ENGINE_LENGTH,      1,      .enginefx,    .yengine_index,    .yengine_delay
        +SfxPlay PLAYING_BENGINE,      1,  ENGINE_LENGTH,      1,      .enginefx,    .bengine_index,    .bengine_delay
        +SfxPlay PLAYING_YSKIDDING1,   2,  SKIDDING_LENGTH,    1,   .skidding1fx, .yskidding1_index, .yskidding1_delay
        +SfxPlay PLAYING_YSKIDDING2,   3,  SKIDDING_LENGTH,    1,   .skidding2fx, .yskidding2_index, .yskidding2_delay
        +SfxPlay PLAYING_BSKIDDING1,   4,  SKIDDING_LENGTH,    1,   .skidding1fx, .bskidding1_index, .bskidding1_delay
        +SfxPlay PLAYING_BSKIDDING2,   5,  SKIDDING_LENGTH,    1,   .skidding1fx, .bskidding2_index, .bskidding2_delay       
        +SfxPlay PLAYING_CLASH,        6,  CLASH_LENGTH,       0,       .clashfx,      .clash_index,      .clash_delay
        +SfxPlay PLAYING_OUTRUN1,      6,  OUTRUN_LENGTH,      0,     .outrun1fx,    .outrun1_index,    .outrun1_delay
        +SfxPlay PLAYING_OUTRUN2,      7,  OUTRUN_LENGTH,      0,     .outrun2fx,    .outrun2_index,    .outrun2_delay
        +SfxPlay PLAYING_EXPLOSION,    7,  EXPLOSION_LENGTH,   0,   .explosionfx,  .explosion_index,  .explosion_delay
        ; +SfxPlay PLAYING_WINNER1,      7,  WINNER_LENGTH,      0,     .winner1fx,    .winner1_index,    .winner1_delay
        ; +SfxPlay PLAYING_WINNER2,      8,  WINNER_LENGTH,      0,     .winner2fx,    .winner2_index,    .winner2_delay
        rts         

;*** definitions of sound effects ******************************************************************

RIGHT_PAN       = 64
LEFT_PAN        = 128
BOTH_PAN        = 192
PULSE           = 0
SAW             = 64
TRIANGLE        = 128
NOISE           = 192

ENGINE_LENGTH = 4
.enginefx       !byte 74, 0, BOTH_PAN + 48, PULSE + 10, 4     ;low freq, high freq, pan + vol, waveform + wavelength, delay
                !byte 74, 0, BOTH_PAN + 48, PULSE + 20, 4
                !byte 74, 0, BOTH_PAN + 48, PULSE + 10, 4
                !byte 74, 0, BOTH_PAN + 48, PULSE + 20, 4

CLASH_LENGTH = 1
.clashfx        !byte 249, 10, BOTH_PAN + 63, NOISE + 5, 0

SKIDDING_LENGTH = 4
.skidding1fx    !byte 249, 10, BOTH_PAN + 32, SAW +  5, 8 
                !byte 160, 11, BOTH_PAN + 32, SAW + 10, 8
                !byte 249, 10, BOTH_PAN + 32, SAW + 15, 8 
                !byte 160, 11, BOTH_PAN + 32, SAW + 10, 8
 
.skidding2fx    !byte 125, 5, BOTH_PAN + 32, NOISE +  5, 8 
                !byte 125, 5, BOTH_PAN + 32, NOISE + 10, 8
                !byte 125, 5, BOTH_PAN + 32, NOISE + 15, 8 
                !byte 125, 5, BOTH_PAN + 32, NOISE + 10, 8

EXPLOSION_LENGTH = 12
.explosionfx    !byte 249, 10, BOTH_PAN + 63, NOISE + 10, 8
                !byte 249, 10, BOTH_PAN + 63, NOISE + 20, 8
                !byte 249, 10, BOTH_PAN + 48, NOISE + 30, 8
                !byte 249, 10, BOTH_PAN + 48, NOISE + 20, 8
                !byte 249, 10, BOTH_PAN + 32, NOISE + 10, 8
                !byte 249, 10, BOTH_PAN + 32, NOISE + 20, 8
                !byte 249, 10, BOTH_PAN + 24, NOISE + 30, 8
                !byte 249, 10, BOTH_PAN + 24, NOISE + 20, 8
                !byte 249, 10, BOTH_PAN + 16, NOISE + 10, 8
                !byte 249, 10, BOTH_PAN + 16, NOISE + 20, 8
                !byte 249, 10, BOTH_PAN +  8, NOISE + 30, 8
                !byte 249, 10, BOTH_PAN +  8, NOISE + 20, 8

OUTRUN_LENGTH = 8
.outrun1fx      !byte 125, 5, LEFT_PAN + 63, TRIANGLE + 52, 16
                !byte 125, 5, LEFT_PAN + 56, TRIANGLE + 52, 4
                !byte 125, 5, LEFT_PAN + 63, TRIANGLE + 52, 16
                !byte 125, 5, LEFT_PAN + 56, TRIANGLE + 52, 4
                !byte 125, 5, LEFT_PAN + 63, TRIANGLE + 52, 16
                !byte 125, 5, LEFT_PAN + 56, TRIANGLE + 52, 4
                !byte 125, 5, LEFT_PAN + 48, TRIANGLE + 52, 4
                !byte 125, 5, LEFT_PAN + 32, TRIANGLE + 52, 4

.outrun2fx      !byte 190, 2, RIGHT_PAN + 63, TRIANGLE + 12, 16
                !byte 190, 2, RIGHT_PAN + 56, TRIANGLE + 12, 4
                !byte 190, 2, RIGHT_PAN + 63, TRIANGLE + 12, 16
                !byte 190, 2, RIGHT_PAN + 56, TRIANGLE + 12, 4
                !byte 190, 2, RIGHT_PAN + 63, TRIANGLE + 12, 16
                !byte 190, 2, RIGHT_PAN + 56, TRIANGLE + 12, 4
                !byte 190, 2, RIGHT_PAN + 48, TRIANGLE + 12, 4
                !byte 190, 2, RIGHT_PAN + 32, TRIANGLE + 12, 4

; WINNER_LENGTH = 12
; .winner1fx      !byte 190,2, LEFT_PAN + 63, TRIANGLE + 52, 20 ;C4
;                 !byte 190,2, LEFT_PAN + 48, TRIANGLE + 52,  4 ;C4
;                 !byte 190,2, LEFT_PAN + 63, TRIANGLE + 52, 12 ;C4
;                 !byte 117,3, LEFT_PAN + 63, TRIANGLE + 52, 12 ;E4
;                 !byte  28,4, LEFT_PAN + 63, TRIANGLE + 52, 12 ;G4
;                 !byte 190,2, LEFT_PAN + 63, TRIANGLE + 52, 12 ;C4
;                 !byte 117,3, LEFT_PAN + 63, TRIANGLE + 52, 12 ;E4
;                 !byte  28,4, LEFT_PAN + 63, TRIANGLE + 52, 12 ;G4
;                 !byte 125,5, LEFT_PAN + 63, TRIANGLE + 52, 24 ;C5
;                 !byte 234,6, LEFT_PAN + 63, TRIANGLE + 52, 16 ;E5
;                 !byte  28,4, LEFT_PAN + 63, TRIANGLE + 52,  8 ;G4
;                 !byte 125,5, LEFT_PAN + 63, TRIANGLE + 52, 48 ;C5

; .winner2fx      !byte  14,2, RIGHT_PAN + 63, TRIANGLE + 52, 20 ;G3
;                 !byte  14,2, RIGHT_PAN + 48, TRIANGLE + 52,  4 ;G3
;                 !byte  14,2, RIGHT_PAN + 63, TRIANGLE + 52, 12 ;G3
;                 !byte 190,2, RIGHT_PAN + 63, TRIANGLE + 52, 12 ;C4
;                 !byte 117,3, RIGHT_PAN + 63, TRIANGLE + 52, 12 ;E4
;                 !byte  14,2, RIGHT_PAN + 63, TRIANGLE + 52, 12 ;G3
;                 !byte 190,2, RIGHT_PAN + 63, TRIANGLE + 52, 12 ;C4
;                 !byte 117,3, RIGHT_PAN + 63, TRIANGLE + 52, 12 ;E4
;                 !byte  28,4, RIGHT_PAN + 63, TRIANGLE + 52, 24 ;G4
;                 !byte 125,5, RIGHT_PAN + 63, TRIANGLE + 52, 16 ;C5
;                 !byte 117,3, RIGHT_PAN + 63, TRIANGLE + 52,  8 ;E4
;                 !byte  28,4, RIGHT_PAN + 63, TRIANGLE + 52, 48 ;G4
