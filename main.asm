;*** main.asm - Entry point for game, setup and main game loop *************************************

!cpu 65c02
!to ".\\works\\prg\\rallyspeedway.prg", cbm
!src "includes/x16.asm"
!src "includes/zsound.asm"

;*** Basic program ("10 SYS 2064") *****************************************************************

*=$0801
	!byte $0E,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00
*=$0810

;*** Game globals **********************************************************************************

;Status for game
ST_MENU           = 0   ;show start screen or menu
ST_SETUPRACE      = 1   ;init track and cars, reset time
ST_RESUMERACE     = 2   ;resume at last checkpoint, 
ST_READYTORACE    = 3   ;wait for player/s to start race
ST_RACING         = 4   ;race on
ST_PAUSED         = 5   ;game paused, quit/resume menu displayed
ST_SETUPCOLLISION = 6   ;init collision
ST_COLLISION      = 7   ;one car (or possibly both) has/have crashed
ST_OUTDISTANCED   = 8   ;one car has outdistanced the other (if two players)
ST_FINISH         = 9   ;race is finished, announce winner
ST_RACEOVER       = 10  ;wait for player/s to continue game
ST_QUITGAME       = 11  ;quit game

;Constants for car behaviour
SKID_LIMIT = 24         ;how deep the turn needs to be before the car starts to skid
MIN_SPEED = 8           ;minimum speed,the user can brake down to, when car is offroad the car will also slow down to this speed
LOW_MAX_SPEED = 19      ;definition of max speeds
NORMAL_MAX_SPEED = 22
HIGH_MAX_SPEED = 25
MAX_EXTRA_ROTATION =    24;16 ;how much extra the car is rotated when skidding
SPEED_DELAY = 4         ;how fast the car is accelerating
BRAKE_DELAY = 8         ;how fast the car is braking/slowing down when off road or skidding
ANIMATION_DELAY = 6     ;how fast an exploding car is animated
CAR_START_DISTANCE = 24 ;space between cars when two players

PENALTY_TIME = 1        ;NOT FULLY IMPLEMENTED - how much time that is added to a car that has been outdistanced
COLLISION_TIME = 1      ;NOT FULLY IMPLEMENTED - how much time that is added for a car that has collided with the background 

;*** Main program **********************************************************************************

.StartGame:
        ;init everything
        jsr LoadLeaderboard             ;load leaderboard, if not successful a new file will be created       
        jsr LoadResources               ;load graphic and sound resources
        bcc +
        rts                             ;exit if some resource failed to load
+       jsr VerifyTracks                ;make sure there are coherent routes on all tracks
        bcc +
        rts
+       lda #ST_MENU
        sta _gamestatus
        jsr InitScreenAndSprites
        jsr InitJoysticks               ;check which type of joysticks (game controllers) are being used 
       	jsr Z_init_player               ;init ZSound
        jsr SetRandomNumberSeed
        jsr .SetupIrqHandler

        ;main loop
-       !byte $cb		        ;wait for an interrupt to trigger (ACME does not know the opcode WAI)
        lda .vsynctrigger               ;check if interrupt was triggered by on vertical blank
        beq -
        ;jsr ChangeDebugColor
        jsr .GameTick
        ;jsr RestoreDebugColor
        stz .vsynctrigger     
        lda _gamestatus
        cmp #ST_QUITGAME 
        bne -
        jsr .EndGame
        rts

_gamestatus             !byte 0       
_noofplayers	        !byte 1      
_max_speed              !byte NORMAL_MAX_SPEED
.defaulthandler_lo 	!byte 0
.defaulthandler_hi	!byte 0
.vsynctrigger           !byte 0
.sprcoltrigger          !byte 0

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
	lda #5                          ;enable vertical blanking and sprite collision interrupts
	sta VERA_IEN
	cli
        rts

.IrqHandler:
        lda VERA_ISR
        sta VERA_ISR
        bit #4                          ;sprite collision interrupt?
        beq +        
        ldx .sprcoltrigger
        bne +
        and #%11110000                  ;keep only collision info
        sta .sprcoltrigger
        jmp (.defaulthandler_lo)
+       bit #1                          ;vertical blank interrupt?
        beq +
        sta .vsynctrigger
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
        jsr Z_stopmusic
        jsr RestoreScreenAndSprites
        rts

.GameTick:                              ;this subroutine is called every jiffy and advances the game one "frame"
        jsr GetJoys                     ;read game controllers and store for all routines to use           

        lda _joy_playback               ;first of all check if demo race
        beq +
        jsr GetRealJoy0
        cmp #JOY_NOTHING_PRESSED
        beq +
        jmp .HandleFinishedRace         ;abort demo race if anything is pressed on first controller

+       lda _gamestatus                 ;second check if game paused, then everything including sound effects should be freezed
        cmp #ST_PAUSED                  
        bne +
        jmp .HandlePause

+       jsr SfxTick                     ;update all sound effects
        jsr Z_playmusic                 ;continue to play music if something is currently playing
        lda #TRACK_BANK                 ;music is in different ram banks, default bank is track bank
        sta RAM_BANK

        lda _gamestatus
        cmp #ST_RACING                  ;race is on
        bne +
        jmp .RaceTick
+       cmp #ST_MENU                    ;show start screen and menu
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
        jmp .ReadyToRace
+       cmp #ST_SETUPCOLLISION
        bne +
        jmp .SetUpCollision
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
        jmp .RaceOver
+       rts

.RaceTick:
+       jsr .CheckForPause              ;check for pause before starting to change the model for next frame
        bcc +
        rts
+       ;jsr YCar_PrintDebugInformation  ;TEMP
        jsr Traffic_Tick
        jsr YCar_CarTick                ;Move car and take actions depending on new block and tile position
        lda _noofplayers
        cmp #1
        beq +
        ;jsr BCar_PrintDebugInformation  ;TEMP        
        jsr BCar_CarTick
        jsr CheckInteraction            ;check if one car has outdistanced the other
+       lda .sprcoltrigger
        beq ++
        bit #YCAR_TCAR_COLLISION
        beq +
        lda #0
        jsr SetTrafficClash 
        stz .sprcoltrigger
        lda .sprcoltrigger
+       bit #BCAR_TCAR_COLLISION        ;blue car has collided with traffic
        beq +
        lda #1
        jsr SetTrafficClash 
        stz .sprcoltrigger
        lda .sprcoltrigger
+       bit #YCAR_BCAR_COLLISION
        beq ++
        jsr SetClash                    ;yellow and blue car have collided (only if two players of course)    
        stz .sprcoltrigger              ;immediately open for new collision interrupts
++      jsr CheckIfRaceOver             ;check for winner and if race is completely over (= cars have stopped)
        jsr UpdateMap                   ;update all tilemap information
        rts

.ShowMenu:
        jsr EnableLayers
        jsr MenuHandler
        rts

.SetUpRace:
        jsr SetTrack                    ;set track
        jsr InitTraffic
        jsr Traffic_Show
        jsr InitCarInteraction
	jsr YCar_StartRace
        jsr YCar_Show
        jsr DisplayYCarBadge
        lda _noofplayers
        cmp #1
        beq +
        jsr BCar_StartRace
        jsr BCar_Show
        jsr DisplayBCarBadge
+	jsr InitMap                     ;update all tilemap information
        jsr UpdateRaceView
        jsr EnableLayer0
        lda #ST_READYTORACE
        sta _gamestatus
        ;jsr StartJoyRecording          ;uncomment when a race should be recorded
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
        stz .sprcoltrigger              ;open up for new sprite collision interrupts
        rts

.ReadyToRace:
        ; jsr Traffic_Tick        ;let traffic start even before rage begins
        ; jsr Traffic_UpdateSprites
        jsr .CheckForPause
        bcs +
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
        jsr PrintCarInfo        ;make sure text is visible if it happens to be blinking
        jsr UpdatePauseMenu     ;OUT: .A = seleced menu item. -1 = nothing selected
        cmp #-1
        bne +
        rts
+       cmp #0
        beq +
        jsr HideCars
        jsr HideBadges
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

.SetUpCollision:
        jsr StopCarSounds
        jsr PlayExplosionSound
        jsr PrintCarInfo        ;make sure text is visible if it happens to be blinking
        jsr BlowUpCars          ;start explosion, one or in rare cases both cars will blow up
        jsr Traffic_Tick        ;continue traffic
        jsr Traffic_UpdateSprites
        lda #ST_COLLISION
        sta _gamestatus
        rts

.HandleCollision:
        jsr BlowUpCars          ;continue explosion
        jsr Traffic_Tick        ;continue traffic
        jsr Traffic_UpdateSprites
        lda _ycarcollisionflag
        bne +
        lda _bcarcollisionflag
        bne +
        lda #ST_RESUMERACE
        sta _gamestatus
+       rts

.HandleOutdistancing:
        jsr PrintCarInfo        ;make sure text is visible if it happens to be blinking
        jsr TextDelay
        beq +
        rts
+       lda #ST_RESUMERACE
        sta _gamestatus
        rts

.HandleFinishedRace:
        jsr StopCarSounds
        lda _joy_playback
        bne .CloseTrack         ;go directly to menu after a demo race
        jsr PrintCarInfo        ;make sure text is visible if it happens to be blinking
        jsr CheckForRecord
        jsr ShowRaceOverText
        jsr PrintBoard
        lda #ZSM_NAMEENTRY_BANK 
        jsr StartMusic
+       lda #ST_RACEOVER
        sta _gamestatus
        ;jsr EndJoyRecording     ;uncomment when a race should be recorded
        rts

.RaceOver:
        lda _boardinputflag     ;check if we should wait for player to enter name because of new record
        beq +
        jsr .WaitForPlayerName
        rts
+       lda _joy0
        and _joy1
        and #JOY_BUTTON_B       ;B button pressed on any game control?
        beq .CloseTrack
        rts

.WaitForPlayerName:
        jsr InputString         ;receive input and blink cursor
        bcs +                   
        rts
+       stz _boardinputflag
        lda _track
        jsr SetLeaderboardName
        jsr SaveLeaderboard     ;and then continue with closing track ...

.CloseTrack:
        jsr HideText
        jsr HideCars
        jsr HideBadges
        jsr DisableLayer0       ;temporary disable layer 0 while preparing main menu
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
!src "libs/debug.asm"

;*** View *****************************
!zone
!src "view/screen.asm"
!src "view/resources.asm"
!src "view/tilemap.asm"
!src "view/soundfx.asm"
!src "view/carsprites.asm"
!src "view/textsprites.asm"
!src "view/badgesprites.asm"

;*** User interface *******************
!zone
!src "userinterface/menu.asm"
!zone
!src "userinterface/leaderboard.asm"
!zone
!src "userinterface/board.asm"

;*** Model *****************************
!zone
!src "model/yellowcar.asm"
!zone
!src "model/bluecar.asm"
!zone
!src "model/carinteraction.asm"
!zone
!src "model/trafficcars.asm"
!zone
!src "model/tracks.asm"
