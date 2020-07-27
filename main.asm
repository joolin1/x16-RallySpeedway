!cpu 65c02
!to "rallyspeedway.prg", cbm
!src "includes/x16.asm"

;*** main.asm - Entry point for game,setup and main game loop **************************************

;Constants for car behaviour
SKID_LIMIT = 16         ;how deep the turn needs to be before the car starts to skid
MAX_SPEED = 16          ;maximum speed that car accelerates to by itself when on road
MIN_SPEED = 8           ;minimum speed,the user can brake down to, when car is offroad the car will also slow down to this speed
MAX_EXTRA_ROTATION = 16 ;how much extra the car is rotated when skidding
SPEED_DELAY = 4         ;how fast the car is accelerating
BRAKE_DELAY = 8         ;how fast the car is braking/slowing down when off road
ANIMATION_DELAY = 6     ;how fast an exploding car is animated

CAR_START_DISTANCE = 24 ;space between cars when two players
PENALTY_TIME = 1        ;how much time that is added to a car that has been outrun
COLLISION_TIME = 1      ;how much time that is added for a car that has collided with the background 

;*** Basic program ("10 SYS 2064") *****************************************************************

*=$0801
	!byte $0E,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00
*=$0810

;*** Main program **********************************************************************************

.StartGame:
        jsr LoadLeaderboard             ;load leaderboard, if not successful a new file will be created       
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
	lda #<.IrqHandler	        ;set custom IRQ handler
	sta IRQ_HANDLER_L
	lda #>.IrqHandler
	sta IRQ_HANDLER_H	
	;lda #5                         ;enable vertical blanking and sprite collision interrupts
        lda #1                          				
	sta VERA_IEN		        ;enable Vera vertical blanking interrupts
	cli

        ;main loop
-       !byte $cb		        ;wait for an interrupt to trigger (ACME does not know the opcode WAI)
        lda .vsynctrigger               ;check if interrupt was triggered by on vertical blank
        beq -
        jsr .GameTick
        stz .vsynctrigger
        lda _gamestatus
        cmp #ST_QUITGAME
        bne -
        jsr .EndGame
        rts

.IrqHandler:
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

.EndGame:                       
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

.GameTick:                              ;Main game loop
        jsr GetJoys                     ;read gamepads and store for all functions to use
        jsr SfxTick                     ;update all sound effects that are currently playing

        lda _gamestatus
        cmp #ST_MENU                    ;show start screen and menu
        bne +
        jmp .ShowMenu
+       cmp #ST_SETUPRACE               ;set up race, prepare everything
        bne +
        jmp .SetUpRace
+       cmp #ST_READYTORACE             ;ready to race, cars in position, waiting for user input to start/continue race
        bne +
        jmp .WaitForStart
+       cmp #ST_COLLISION               ;one car has collided, animate explosion
        bne +
        jmp .HandleCollision
+       cmp #ST_OUTRUN                  ;one car has outrun the other (only when two players) 
        bne +
        jmp .HandleOutrun
+       cmp #ST_FINISH                  ;race finished, announce winner
        bne + 
        jmp .HandleFinishedRace
+       cmp #ST_RACEOVER                ;wait for players selection of how to continue game
        bne +
        jmp .WaitForEnd

        ;race is on
+       jsr YCar_ReactOnPlayerInput     ;adjust direction and speed based on player input
        jsr YCar_UpdatePosition         ;calculate new direction, speed and skidding, update timer
        jsr YCar_DetectCollision        ;check if the car has collided
        lda _noofplayers
        cmp #1
        beq +        
        jsr BCar_ReactOnPlayerInput
        jsr BCar_UpdatePosition
        jsr BCar_DetectCollision
        jsr CheckInteraction            ;check if one car has outrun the other or if cars have collided
+       jsr CheckRaceOver               ;check if cars have finished race and speed have slowed down to 0
        jsr UpdateCamera                ;set camera, i e what part of the map that will be displayed
        rts

.ShowMenu:
        ; inc _gamestatus                ;TEMP - skip menu, start race
	; jsr SetLayer0ToTileMode        ;TEMP
	; jsr ClearTextLayer             ;TEMP
        jsr YCar_Hide                   ;comment out to skip status menu
        jsr BCar_Hide                   ;comment out to skip status menu
        jsr MenuHandler                 ;comment out to skip status menu
        jsr YCar_TimeReset
        jsr BCar_TimeReset
        rts

.SetUpRace:
        jsr SetTrack
        jsr InitMap
	jsr YCar_Init
        jsr YCar_Show
        lda _noofplayers
        cmp #1
        beq +
        jsr BCar_Init
        jsr BCar_Show
+	jsr InitCamera
        jsr InitView
        jsr UpdateView
        inc _gamestatus
        rts

.WaitForStart:
        lda _joy0
        and #8                  ;player 1 - up pressed?
        bne +
        lda #ST_RACING
        ;lda #ST_FINISH
        sta _gamestatus
        rts
+       lda _noofplayers
        cmp #2
        beq +
        rts
+       lda _joy1               ;give both players the chance to start race
        and #8
        bne +
        lda #ST_RACING
        sta _gamestatus
+       rts

.HandleCollision:
        jsr YCar_Explode                ;each car has a collision flag which is set when the car has collided with the background
        jsr BCar_Explode
        jsr UpdateStartPosition
        rts

.HandleOutrun:
        jsr TextDelay
        beq +
        rts
+       jsr UpdateStartPosition
        lda #ST_SETUPRACE
        sta _gamestatus
        rts

.HandleFinishedRace:
        jsr SetWinner
        jsr ShowRaceOverText
        jsr PrintBoard
        jsr StopCarSounds
        jsr PlayFinishedSound
        lda #ST_RACEOVER
        sta _gamestatus
        rts

.WaitForEnd:
        lda _boardinputflag     ;check if we should wait for player to enter name because of new record
        beq +
        jsr .WaitForPlayerName
        rts
+       lda _joy0
        and #JOY_START          ;player 1 - start button pressed?
        beq ++
        lda _noofplayers
        cmp #2
        beq +
        rts
+       lda _joy1               ;give both players the chance to end race
        and #JOY_START
        beq ++
        rts      
++      jsr HideText
        lda #ST_MENU
        sta _gamestatus
        rts

.WaitForPlayerName:
        jsr InputString         ;receive input and blink cursor
        bcs +                   
        rts
+       stz _boardinputflag
        lda _track
        jsr SetLeaderboardName
        jsr SaveLeaderboard
        jsr HideText
        lda #ST_MENU
        sta _gamestatus
        rts

;*** Game globals **********************************************************************************

;Status for game
ST_MENU         = 0     ;show start screen or menu
ST_SETUPRACE    = 1     ;draw track, position cars
ST_READYTORACE  = 2     ;wait for player/s to start race
ST_RACING       = 3     ;race on
ST_COLLISION    = 5     ;one car (or possibly both) has/have crashed
ST_OUTRUN       = 6     ;one car has outrun the other (if two players)
ST_FINISH       = 7     ;race is finished, announce winner
ST_RACEOVER     = 8     ;wait for player/s to continue game
ST_QUITGAME     = 9     ;end game

_gamestatus     !byte   0       
_noofplayers	!byte   1       ;number of players
_debug          !byte   0       ;DEBUG - flag for breaking into debugger

;*** Other source files ****************************************************************************

!src "libs/mathlib.asm"
!src "libs/veralib.asm"
!src "libs/filelib.asm"
!src "libs/textlib.asm"
!src "libs/helperslib.asm"
!src "libs/debuglib.asm"
!zone
!src "menu.asm"
!zone
!src "board.asm"
!zone
!src "map.asm"
!src "view.asm"
!src "camera.asm"
!zone;
!src "yellowcar.asm"
!zone
!src "bluecar.asm"
!zone
!src "carinteraction.asm"
!zone
!src "soundfx.asm"
!zone
!src "joystick.asm"
!zone
!src "screen.asm"
!zone
!src "spritetext.asm"
!zone
!src "graphics.asm"
!zone
!src "tracks.asm"
!zone
!src "leaderboard.asm"