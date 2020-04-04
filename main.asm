;*** main.asm - Entry point for game,setup and main game loop **************************************
!cpu 65c02
!to "rallyspeedway.prg", cbm
!src "x16-rallyspeedway/definitions.asm"
!src "x16-rallyspeedway/macros.asm"

;Status for game
ST_MENU         = 0     ;show start screen or menu
ST_SETUPRACE    = 1     ;draw track, position cars
ST_READYTORACE  = 2     ;wait for player/s to start race
ST_RACING       = 3     ;race on
ST_COLLISION    = 5     ;one car (or possibly both) has/have crashed
ST_OUTRUN       = 6     ;one car has outrun the other (if two players)
ST_RACEOVER     = 7     ;race is over, winner is announced
ST_QUITGAME     = 8     ;end game

;Constants for car behaviour
SKID_LIMIT = 16         ;how deep the turn needs to be before the car starts to skid
MAX_SPEED = 24          ;maximum speed that car accelerates to by itself when on road
MIN_SPEED = 14          ;minimum speed,the user can brake down to, when car is offroad the car will also slow down to this speed
MAX_EXTRA_ROTATION = 16 ;how much extra the car is rotated when skidding
SPEED_DELAY = 2         ;how fast the car is accelerating
BRAKE_DELAY = 4         ;how fast the car is braking/slowing down when off road
ANIMATION_DELAY = 4     ;how fast an exploding car is animated

CAR_START_DISTANCE = 24
PENALTY_TIME = 1        ;how much time that is added to a car that has been outrun
COLLISION_TIME = 1      ;how much time that is added for a car that has collided with the background 

*=$0801
	!byte $0E,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00
*=$0810

!zone
;*** Main program ***********************************************************************

StartGame:
        jsr LoadGraphics                ;load tiles and sprites from disk to VRAM
        bcc +
        rts                             ;exit if some resource failed to load
+       jsr InitScreenAndSprites
        jsr InitJoysticks               ;set type of joysticks (game controllers) being used 
        lda #ST_MENU
        sta _gamestatus	
        sei
	lda IRQ_HANDLER_L	        ;save original IRQ handler
	sta .defaulthandler_lo
	lda IRQ_HANDLER_H
	sta .defaulthandler_hi
	lda #<IrqHandler	        ;set custom IRQ handler
	sta IRQ_HANDLER_L
	lda #>IrqHandler
	sta IRQ_HANDLER_H	
	;lda #5                         ;enable vertical blanking and sprite collision interrupts
        lda #1                          				
	sta VERA_IEN		        ;enable Vera vertical blanking interrupts
	cli

        ;main loop
-       !byte $cb		        ;wait for an interrupt to trigger (ACME does not know the opcode WAI)
        lda .vsynctrigger               ;check if interrupt was triggered by on vertical blank
        beq -
        jsr GameTick
        stz .vsynctrigger
        lda _gamestatus
        cmp #ST_QUITGAME
        bne -
        jsr EndGame
        rts

IrqHandler:
        ; lda VERA_ISR  ;no support for hardware sprite collisions yet
        ; and #$04
        ; beq +
+       lda VERA_ISR
        and #$01
        beq +
        sta .vsynctrigger
        sta VERA_ISR
        lda _gamestatus
        cmp #ST_RACING
        bne +
        jsr UpdateView
        ;alt 1 - jump to default handler
+       jmp (.defaulthandler_lo)     
        ;alt 2 - skip default handler, return directly from interrupt
        ; pla                            
        ; tay
        ; pla
        ; tax
        ; pla
        ; rti

EndGame:                       
 	sei                             ;restore default irq handler
	lda .defaulthandler_lo
	sta IRQ_HANDLER_L
	lda .defaulthandler_hi
	sta IRQ_HANDLER_H
	cli
        jsr RestoreScreenAndSprites
        rts

.defaulthandler_lo 	!byte 0
.defaulthandler_hi	!byte 0
.vsynctrigger           !byte 0

GameTick:
        jsr GetJoys                     ;read gamepads and store for all functions to use
        lda _gamestatus               

        cmp #ST_MENU
        bne +                    
        ;inc _gamestatus                 ;TEMP - skip menu, start race
	;jsr SetLayer0ToTileMode         ;TEMP
	;jsr ClearTextLayer1             ;TEMP
        jsr HideCars                   ;comment out to skip status menu
        jsr MenuHandler                ;comment out to skip status menu
        jsr YCar_TimeReset
        jsr BCar_TimeReset
        rts

+       cmp #ST_SETUPRACE               ;ready to race, cars in position, waiting for user input to start/continue race
        bne +                   
        jsr InitMap
	jsr ShowCars
	jsr YCar_Init
        jsr BCar_Init
	jsr InitCamera
        jsr InitView
        jsr UpdateView
        inc _gamestatus
        rts

+       cmp #ST_READYTORACE
        bne +
        jsr WaitForStart
        rts

+       cmp #ST_COLLISION               ;one car has collided, animate explosion
        bne +
        jsr YCar_Explode                ;each car has a collision flag which is set when the car has collided with the background
        jsr BCar_Explode
        jsr UpdateStartPosition
        rts

+       cmp #ST_OUTRUN                  ;one car has outrun the other, this will of course never happen if there is only one player 
        bne +
        jsr HideCars
        lda _bcaroutrun
        jsr ShowPenaltyText
        jsr UpdateStartPosition
        rts

+       cmp #ST_RACEOVER                ;race over, announce winner
        bne + 
        ;jsr AnnounceWinner             ;TODO
        rts

+       jsr YCar_ReactOnPlayerInput     ;adjust direction and speed based on player input
        jsr YCar_UpdatePosition         ;calculate new direction, speed and skidding, update timer
        jsr YCar_DetectCollision        ;check if the car has collided
        lda _noofplayers
        cmp #1
        beq +        
        jsr BCar_ReactOnPlayerInput
        jsr BCar_UpdatePosition
        jsr BCar_DetectCollision
        jsr DetectClash                 ;check if one car has outrun the other or if cars have collided
+       jsr UpdateCamera                ;set camera, i e what part of the map that will be displayed
        rts

WaitForStart:
        lda _joy0
        and #8                  ;player 1 - up pressed?
        bne +
        inc _gamestatus
        rts
+       lda _noofplayers
        cmp #2
        beq +
        rts
+       lda _joy1               ;give both players the chance to start race
        and #8
        bne +
        inc _gamestatus         ;update status to "racing"
+       rts

;*** Global variables ******************************************************************************

_gamestatus     !byte   0       
_noofplayers	!byte   2	;number of players
_track		!byte   1	;selected track
_xstartblock    !byte   2       ;race start position
_ystartblock    !byte   2
_startdirection !byte   0       ;race start direction

_debug          !byte   0       ;DEBUG - flag for breaking into debugger

;tables for which sprite (0-4) represents the current angle and how it is flipped (0 = no flip, 1 = horizontal flip, 2 vertical flip, 3 = flipped both ways)
_anglespritetable       !byte   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15
                        !byte  16,15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1                       
                        !byte   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15
                        !byte  16,15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1
_anglefliptable         !byte   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        !byte   0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
                        !byte   1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
                        !byte   3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2

;table for sine and cosine values. Fractions in fixed point numbers used are represented by 4 bits. For example sin(45) = 0.707 * 16 = 11.3.
;NOTE! words are used because of the negative values!
_anglesin       !word   0,  2,  3,  5,  6,  8,  9, 10, 11, 12, 13, 14, 15, 15, 16, 16 ;sin angles 0-
_anglecos       !word  16, 16, 16, 15, 15, 14, 13, 12, 11, 10,  9,  8,  6,  5,  3,  2 ;sin angles 90-
                !word   0, -2, -3, -5, -6, -8, -9,-10,-11,-12,-13,-14,-15,-15,-16,-16 ;sin angles 180-
                !word -16,-16,-16,-15,-15,-14,-13,-12,-11,-10, -9, -8, -6, -5, -3, -2 ;sin angles 270-
                !word   0,  2,  3,  5,  6,  8,  9, 10, 11, 12, 13, 14, 15, 15, 16, 16 ;cos angles 270-

;*** Other source files ****************************************************************************

!zone
!src "x16-rallyspeedway/menu.asm"
!zone
!src "x16-rallyspeedway/map.asm"
!zone
!src "x16-rallyspeedway/view.asm"
!src "x16-rallyspeedway/camera.asm"
!zone;
!src "x16-rallyspeedway/yellowcar.asm"
!zone
!src "x16-rallyspeedway/bluecar.asm"
!zone
!src "x16-rallyspeedway/interaction.asm"
!zone
!src "x16-rallyspeedway/joystick.asm"
!zone
!src "x16-rallyspeedway/debug.asm"
!zone
!src "x16-rallyspeedway/screen.asm"
!zone
!src "x16-rallyspeedway/init.asm"
!zone
!src "x16-rallyspeedway/vload.asm"
!zone
!src "x16-rallyspeedway/helpers.asm"
!zone
