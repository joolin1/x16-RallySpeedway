;*** main.asm - Entry point for game, setup and main game loop *************************************

!cpu 65c02
!to "rallyspeedway.prg", cbm
!src "includes/x16.asm"

;*** Basic program ("10 SYS 2064") *****************************************************************

*=$0801
	!byte $0E,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00
*=$0810

;*** Game globals **********************************************************************************

;Status for game
ST_MENU         = 0     ;show start screen or menu
ST_SETUPRACE    = 1     ;init track and cars, reset time
ST_RESUMERACE   = 2     ;resume at last checkpoint, 
ST_READYTORACE  = 3     ;wait for player/s to start race
ST_RACING       = 4     ;race on
ST_PAUSED       = 5     ;game paused, quit/resume menu displayed
ST_COLLISION    = 6     ;one car (or possibly both) has/have crashed
ST_OUTDISTANCED = 7     ;one car has outdistanced the other (if two players)
ST_FINISH       = 8     ;race is finished, announce winner
ST_RACEOVER     = 9     ;wait for player/s to continue game
ST_QUITGAME     = 10    ;quit game

;Constants for car behaviour
SKID_LIMIT = 24         ;how deep the turn needs to be before the car starts to skid
MAX_SPEED = 18          ;maximum speed that car accelerates to by itself when on road
MIN_SPEED = 8           ;minimum speed,the user can brake down to, when car is offroad the car will also slow down to this speed
MAX_EXTRA_ROTATION = 16 ;how much extra the car is rotated when skidding
SPEED_DELAY = 4         ;how fast the car is accelerating
BRAKE_DELAY = 8         ;how fast the car is braking/slowing down when off road
ANIMATION_DELAY = 6     ;how fast an exploding car is animated
CAR_START_DISTANCE = 24 ;space between cars when two players

PENALTY_TIME = 1        ;NOT FULLY IMPLEMENTED - how much time that is added to a car that has been outdistanced
COLLISION_TIME = 1      ;NOT FULLY IMPLEMENTED - how much time that is added for a car that has collided with the background 

;*** Main program **********************************************************************************

.StartGame:
        ;init everything
        jsr LoadLeaderboard             ;load leaderboard, if not successful a new file will be created       
        jsr LoadGraphics                ;load tiles and sprites from disk to VRAM
        bcc +
        rts                             ;exit if some resource failed to load
+       lda #ST_MENU
        sta _gamestatus
        jsr InitScreenAndSprites
        jsr InitJoysticks               ;check which type of joysticks (game controllers) are being used 
        jsr .SetupIrqHandler

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

_gamestatus     !byte   0       
_noofplayers	!byte   1               ;number of players
_debug          !byte   0               ;DEBUG - flag for breaking into debugger

.SetupIrqHandler:
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
        jsr UpdateRaceView
+       jmp (.defaulthandler_lo)     

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

.GameTick:                              ;this subroutine is called every jiffy and advances the game one "frame"
        jsr GetJoys                     ;read game controllers and store for all routines to use           

        lda _gamestatus                 ;first of all check if game paused, then everything including sound effects should be freezed
        cmp #ST_PAUSED                  
        bne +
        jmp .HandlePause

+       jsr SfxTick                     ;update all sound effects that are currently playing

        lda _gamestatus
        cmp #ST_MENU                    ;show start screen and menu
        bne +
        jmp .ShowMenu
+       cmp #ST_SETUPRACE               ;set up race, prepare everything
        bne +
        jmp .SetUpRace
+       cmp #ST_RESUMERACE              ;resume race from last checkpoint
        bne +
        jmp .ResumeRace
+       cmp #ST_READYTORACE             ;ready to race, cars in position, waiting for user input to start/continue race
        bne +
        jmp .WaitForStart
+       cmp #ST_COLLISION               ;one car has collided, stop movement and animate explosion (in theory both cars can collide and explode at the same time)
        bne +
        jmp .HandleCollision
+       cmp #ST_OUTDISTANCED            ;one car has outdistanced the other (only when two players) 
        bne +
        jmp .HandleOutdistancing
+       cmp #ST_FINISH                  ;race finished, announce winner
        bne + 
        jmp .HandleFinishedRace
+       cmp #ST_RACEOVER                ;wait for players selection of how to continue game
        bne +
        jmp .WaitForEnd

        ;race is on
+       jsr .CheckForPause              ;check for pause before starting to change the model for next frame
        bcc +
        rts
+       jsr YCar_PrintDebugInformation  ;TEMP
        jsr YCar_ReactOnPlayerInput     ;adjust direction and speed based on player input
        jsr YCar_CarTick                ;Move car and take actions depending on new block and tile position
        lda _noofplayers
        cmp #1
        beq +
        jsr BCar_PrintDebugInformation  ;TEMP        
        jsr BCar_ReactOnPlayerInput
        jsr BCar_CarTick
        jsr CheckInteraction            ;check if one car has outdistanced the other or if cars have collided
+       jsr CheckRaceOver               ;check if cars have finished race and speed have slowed down to 0
        jsr UpdateMap                   ;update all tilemap information
        rts

.ShowMenu:
        ; inc _gamestatus                ;TEMP - skip menu, start race
	; jsr SetLayer0ToTileMode        ;TEMP
	; jsr ClearTextLayer             ;TEMP
        jsr MenuHandler                 ;comment out to skip status menu
        rts

.SetUpRace:
        jsr SetTrack                    ;set track
	jsr YCar_StartRace
        jsr YCar_Show
        lda _noofplayers
        cmp #1
        beq +
        jsr BCar_StartRace
        jsr BCar_Show
+	jsr InitMap                     ;update all tilemap information
        jsr UpdateRaceView
        lda #ST_READYTORACE
        sta _gamestatus
        rts

.ResumeRace:
        lda _noofplayers
        cmp #1
        beq +
        jsr SetStartPosition            ;if two players, set start position based on last location of cars
        jsr BCar_ResumeRace
        jsr BCar_Show
+       jsr YCar_ResumeRace
        jsr YCar_Show
	jsr InitMap                     ;update all tilemap information
        jsr UpdateRaceView
        lda #ST_READYTORACE
        sta _gamestatus
        rts

.WaitForStart:
        lda _joy0
        and _joy1
        and #JOY_UP             ;up pressed on any game control?
        bne +
        lda #ST_RACING
        sta _gamestatus
+       rts

.CheckForPause:
        lda _joy0
        and _joy1
        and #JOY_START          ;start pressed by any player?
        beq +
        clc
        rts
+       jsr StopCarSounds
        jsr ShowPauseMenu    
        lda #ST_PAUSED
        sta _gamestatus
        sec
        rts
 
.HandlePause:                   ;pause is made by just cutting sound and stop car movement
        jsr UpdatePauseMenu     ;OUT: .A = seleced menu item. -1 = nothing selected
        cmp #-1
        bne +
        rts
+       cmp #0
        beq +
        jsr YCar_Hide
        jsr BCar_Hide
        lda #ST_MENU
        sta _gamestatus         ;quit race
        rts
+       ldx #<L1_MAP_ADDR       ;delete menu by simply clearing text layer     
        ldy #>L1_MAP_ADDR
        jsr ClearTextLayer
        jsr PlayYCarEngineSound ;start engine sounds again
        lda _noofplayers
        cmp #1
        beq +
        jsr PlayBCarEngineSound
+       lda #ST_RACING          ;resume race exactly where we were (= do not initialize any car variables)
        sta _gamestatus
        rts

.HandleCollision:
        jsr YCar_Explode        ;each car has a collision flag which is set when the car has collided with the background
        jsr BCar_Explode
        rts

.HandleOutdistancing:
        jsr TextDelay
        beq +
        rts
+       lda #ST_RESUMERACE
        sta _gamestatus
        rts

.HandleFinishedRace:
        jsr SetWinnerAndRecord
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
        and _joy1
        and #JOY_START          ;start button pressed on any game control?
        beq +
        rts
+       jsr HideText
        jsr YCar_Hide
        jsr BCar_Hide
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
        jsr YCar_Hide
        jsr BCar_Hide
        lda #ST_MENU
        sta _gamestatus
        rts

;*** Other source files ****************************************************************************

;*** library files *********************
!zone
!src "libs/mathlib.asm"
!src "libs/veralib.asm"
!src "libs/filelib.asm"
!src "libs/textlib.asm"
!src "libs/helperslib.asm"
!src "libs/joysticklib.asm"

;*** View *****************************
!zone
!src "view/screen.asm"
!src "view/graphics.asm"
!src "view/tilemap.asm"
!zone
!src "gameplay/soundfx.asm"

;*** User interface *******************
!zone
!src "userinterface/menu.asm"
!zone
!src "userinterface/leaderboard.asm"
!zone
!src "userinterface/board.asm"
!zone
!src "userinterface/spritetext.asm"

;*** Model *****************************
!zone
!src "gameplay/yellowcar.asm"
!zone
!src "gameplay/bluecar.asm"
!zone
!src "gameplay/carinteraction.asm"
!zone
!src "gameplay/tracks.asm"
