;*** main.asm - Entry point for game,setup and main game loop **************************************
!cpu 65c02
!to "rallyspeedway.prg", cbm
!src "x16-rallyspeedway/x16.asm"
!src "x16-rallyspeedway/macros.asm"
!src "x16-rallyspeedway/constants.asm"

*=$0801
	!byte $0E,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00
*=$0810

;*** Main program ***********************************************************************

.StartGame:
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
        lda _gamestatus               
        cmp #ST_MENU                    ;show start screen and menu
        bne +
        bra .ShowMenu
+       cmp #ST_SETUPRACE               ;set up race, prepare everything
        bne +
        bra .SetUpRace
+       cmp #ST_READYTORACE             ;ready to race, cars in position, waiting for user input to start/continue race
        bne +
        bra .WaitForStart
+       cmp #ST_COLLISION               ;one car has collided, animate explosion
        bne +
        bra .HandleCollision
+       cmp #ST_OUTRUN                  ;one car has outrun the other (only two players) 
        bne +
        bra .HandleOutrun
+       cmp #ST_RACEOVER                ;race over, announce winner
        bne + 
        ;bra AnnounceWinner             ;TODO

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
        jsr DetectClash                 ;check if one car has outrun the other or if cars have collided
+       jsr UpdateCamera                ;set camera, i e what part of the map that will be displayed
        rts

.ShowMenu:
        ;inc _gamestatus                ;TEMP - skip menu, start race
	;jsr SetLayer0ToTileMode        ;TEMP
	;jsr ClearTextLayer1            ;TEMP
        jsr YCar_Hide                   ;comment out to skip status menu
        jsr BCar_Hide                   ;comment out to skip status menu
        jsr MenuHandler                 ;comment out to skip status menu
        jsr YCar_TimeReset
        jsr BCar_TimeReset
        rts

.SetUpRace:
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

.HandleCollision:
        jsr YCar_Explode                ;each car has a collision flag which is set when the car has collided with the background
        jsr BCar_Explode
        jsr UpdateStartPosition
        rts

.HandleOutrun:
        jsr YCar_Hide
        jsr BCar_Hide
        lda _bcaroutrun
        jsr ShowPenaltyText
        jsr PlayOutrunSound
        jsr UpdateStartPosition
        rts

;*** Other source files ****************************************************************************

!zone
!src "x16-rallyspeedway/menu.asm"
!zone
!src "x16-rallyspeedway/map.asm"
!src "x16-rallyspeedway/view.asm"
!src "x16-rallyspeedway/camera.asm"
!zone;
!src "x16-rallyspeedway/yellowcar.asm"
!zone
!src "x16-rallyspeedway/bluecar.asm"
!zone
!src "x16-rallyspeedway/interaction.asm"
!src "x16-rallyspeedway/soundfx.asm"
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
!src "x16-rallyspeedway/globals.asm"
!src "x16-rallyspeedway/tracks.asm"