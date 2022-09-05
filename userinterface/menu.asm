;*** Menu.asm - Start screen, menu, annoncements *******************************

;Menu status
M_START_MUSIC			= 0
M_SHOW_TITLE_IMAGE      = 1
M_UPDATE_TITLE_IMAGE    = 2
M_START_DEMO_RACE       = 3
M_END_DEMO_RACE         = 4
M_SHOW_CREDITS 			= 5
M_UPDATE_CREDITS		= 6
M_SHOW_MAIN_MENU 		= 7
M_HANDLE_INPUT 			= 8

;Menu item mapping
START_RACE		= 0
ONE_PLAYER 		= 1
TWO_PLAYERS 	= 2
TRACK_1			= 3
TRACK_2			= 4
TRACK_3			= 5
TRACK_4			= 6
TRACK_5			= 7
LOW_SPEED   	= 8
NORMAL_SPEED 	= 9
HIGH_SPEED	 	= 10
RESET_BEST  	= 11
QUIT_GAME		= 12

MENU_ITEMS_COUNT = 13

;Special characters used in menu
END_LINE_DIV	= 34 	;"
BLOCK			= 35	;#
MIDDLE_LINE_DIV	= 37 	;%
FIRST_LINE_DIV 	= 38	;&

;Colors
MENU_WHITE = $01
MENU_BLACK = $0b

SHORT_INACTIVITY_DELAY	 = 3	;title image and credit screen will take turns when user is inactive. 7 = 30 sec (= 7 * 256 / 60)
LONG_INACTIVITY_DELAY	 = 7    ;menu will go to credit screen when user for is inactive for a longer period of time

;*** Public methods ********************************************************************************

MenuHandler:
	lda .menumode

	;start title music
	cmp #M_START_MUSIC
	bne +
	lda #ZSM_TITLE_BANK
	jsr StartMusic					;start title music
	inc .menumode					;go to show title image
	rts								

	;show title image
+	cmp #M_SHOW_TITLE_IMAGE
	bne +
	jsr .ShowTitleImage
	stz .inactivitytimer_lo
	stz .inactivitytimer_hi
	inc .menumode					;go to update title image mode
	rts

	;update title image
+   cmp #M_UPDATE_TITLE_IMAGE
	bne ++
	+Inc16bit .inactivitytimer_lo
	lda .inactivitytimer_hi
	cmp #SHORT_INACTIVITY_DELAY
	bne +	
	lda #M_START_DEMO_RACE
	sta .menumode
	rts
+	lda _joy0
	cmp #$ff
	beq +
	lda #M_SHOW_MAIN_MENU
	sta .menumode					;go to menu when user presses something
+	rts

	;set up demo race
++	cmp #M_START_DEMO_RACE
	bne +
	jsr .SaveMenuSelections
	jsr .StartDemoRace
	lda #M_END_DEMO_RACE
	sta .menumode
	rts

	;clean up after demo race
+	cmp #M_END_DEMO_RACE
	bne +
    jsr EndJoyPlayback
	jsr .RestoreMenuSelections		;after demo race, restore menu selections
	jsr SetRandomSeed				;start randomize in a more unpredictable way after the demo race
	lda #M_SHOW_CREDITS
	sta .menumode
	rts

	;show credits screen
+	cmp #M_SHOW_CREDITS
	bne +
	jsr .ShowCreditsScreen
	stz .inactivitytimer_lo
	stz .inactivitytimer_hi
	inc .menumode					;go update credit screen mode
	rts

	;update credits screen
+	cmp #M_UPDATE_CREDITS
	bne ++
	+Inc16bit .inactivitytimer_lo
	lda .inactivitytimer_hi
	cmp #SHORT_INACTIVITY_DELAY
	bne +
	lda #M_SHOW_TITLE_IMAGE
	sta .menumode					;go to title image when user inactive
	rts
+	jsr .UpdateRandomBgColor
	jsr .UpdateRandomBgColor
	lda _joy0
	cmp #$ff
	beq +
	lda #M_SHOW_MAIN_MENU
	sta .menumode           		;go to menu when user presses something
+   rts

	;show menu
++  cmp #M_SHOW_MAIN_MENU
	bne +
	jsr .ShowMainMenu
	lda #ZSM_MENU_BANK
	jsr StartMusic					;switch to menu music
	lda #M_HANDLE_INPUT				;go to input menu mode
	sta .menumode
	lda #1
	sta .inputwait					;wait for controller to be released before accepting input again
	stz .inactivitytimer_lo
	stz .inactivitytimer_hi
	rts

	;handle user input
++	cmp #M_HANDLE_INPUT
	beq +
	rts

+   lda .inactivitytimer_hi
	cmp #LONG_INACTIVITY_DELAY
	beq +
	jsr .HandleUserInput
	rts

+   lda #ZSM_TITLE_BANK
	jsr StartMusic					;switch to title music
	lda #M_SHOW_CREDITS
	sta .menumode					;go to back to title image when user inactive
	rts

.menumode				!byte 0
.inactivitytimer_lo		!byte 0		;timer to measure user inactivity
.inactivitytimer_hi		!byte 0

;*** Private methods *******************************************************************************

.HandleUserInput:
	lda _joy0
	cmp #JOY_NOTHING_PRESSED	;prevent repeating
	bne ++
	stz .inputwait				;nothing pressed - ready for input again
	inc .inactivitytimer_lo		;increase timer for user's inactivity
	bne +
	inc .inactivitytimer_hi
+	rts

++  lda .inputwait				;if true skip reading controller
	beq +
	rts

+	lda #1
	sta .inputwait				;flag that something has been pressed so we can wait until controller released before accepting new input
	stz .inactivitytimer_lo		;reset timer user's inactivity
	stz .inactivitytimer_hi

	jsr .HandleUpDown
	jsr .HandleLeftRight
	jsr .HandleButton
	lda .resetconfirmationflag
	bne +
	lda .quitconfirmationflag
	bne +
	lda _gamestatus
	cmp #ST_SETUPRACE
	beq +
	jsr .UpdateMainMenu
+	rts

.HandleUpDown:					;up down moves hand up and down
	lda _joy0
	bit #JOY_UP					;up?
	bne +
	jsr .DecreaseHandrow
	stz .resetconfirmationflag	;cancel possibel confirmation questions if user moves away from question
	stz .quitconfirmationflag
	rts
+	bit #JOY_DOWN				;down?
	bne +
	jsr .IncreaseHandrow
	stz .resetconfirmationflag	;cancel possibel confirmation questions if user moves away from question
	stz .quitconfirmationflag
+	rts

.IncreaseHandrow:
	jsr .ClearHand
	inc .handrow
	lda .handrow
	cmp #MENU_ITEMS_COUNT
	bne +
	stz .handrow
+	rts

.DecreaseHandrow:
	jsr .ClearHand
	dec .handrow
	bpl +
	lda #MENU_ITEMS_COUNT-1
	sta .handrow
+	rts

.handrow	!byte 0

.HandleLeftRight:				;left right toggles true/false for confirmation questions.
	lda .resetconfirmationflag
	bne +
	lda .quitconfirmationflag
	bne +
	rts
+   lda _joy0
 	bit #JOY_LEFT				;left?
	bne +
	lda .answer					
	bne +
	lda #1
	sta .answer					;set answer to true if false
	jsr .PrintCurrentAnswer
	rts
+	lda _joy0
	bit #JOY_RIGHT				;right?
	bne +
	lda .answer
	beq +
	stz .answer					;set answer to false if true
	jsr .PrintCurrentAnswer
+	rts

.inputwait	!byte 0				;boolean, when true wait for user to release controller

.HandleButton:
	;button a pressed?
	lda _joy0
	bit #JOY_BUTTON_A
	beq +
	rts

	;take action depending on current menu item
+	lda .handrow
	cmp #START_RACE
	bne +
	jsr Z_stopmusic
	lda #M_SHOW_MAIN_MENU
	sta .menumode			;prepare for the next time the menu handler will be called, after race go to main menu
	jsr .CloseMainMenu
	rts

+	cmp #ONE_PLAYER
	bne +
	lda #1
	sta .oneplayer
	lda #$0b
	sta .twoplayers
	lda #1
	sta _noofplayers
	rts

+	cmp #TWO_PLAYERS
	bne +
	lda #1
	sta .twoplayers
	lda #$0b
	sta .oneplayer
	lda #2
	sta _noofplayers
	rts

+	cmp #TRACK_1
	bne +
	lda #1
	sta .track1
	lda #$0b
	sta .track2
	sta .track3
	sta .track4
	sta .track5
	lda #1
	sta _track
	rts

+	cmp #TRACK_2
	bne +
	lda #1
	sta .track2
	lda #$0b
	sta .track1
	sta .track3
	sta .track4
	sta .track5
	lda #2
	sta _track
	rts

+	cmp #TRACK_3
	bne +
	lda #1
	sta .track3
	lda #$0b
	sta .track1
	sta .track2
	sta .track4
	sta .track5
	lda #3
	sta _track
	rts

+	cmp #TRACK_4
	bne +
	lda #1
	sta .track4
	lda #$0b
	sta .track1
	sta .track2
	sta .track3
	sta .track5
	lda #4
	sta _track
	rts

+	cmp #TRACK_5
	bne +
	lda #1
	sta .track5
	lda #$0b
	sta .track1
	sta .track2
	sta .track3
	sta .track4
	lda #5
	sta _track
    rts

+ 	cmp #LOW_SPEED
	bne +
	lda #1
	sta .lowspeed
	lda #$0b
	sta .normalspeed
	sta .highspeed
	lda #LOW_MAX_SPEED
	sta _max_speed
	rts

+ 	cmp #NORMAL_SPEED
	bne +
	lda #1
	sta .normalspeed
	lda #$0b
	sta .lowspeed
	sta .highspeed
	lda #NORMAL_MAX_SPEED
	sta _max_speed
	rts

+ 	cmp #HIGH_SPEED
	bne +
	lda #1
	sta .highspeed
	lda #$0b
	sta .lowspeed
	sta .normalspeed
	lda #HIGH_MAX_SPEED
	sta _max_speed
	rts

+	cmp #RESET_BEST
	bne +
	jsr .HandleResetLeaderboard

+	cmp #QUIT_GAME
	bne +
	jsr .HandleQuitGame
+	rts

.StartDemoRace:				;a demo race is almost like an ordinary race, the main difference is that controller data are fetched from a saved file
	lda #1					;demo race recording contains two players, track 1, normal max speed
	sta _noofplayers
	lda #NORMAL_MAX_SPEED
	sta _max_speed
	lda #1
	sta _track
	jsr SetRandomSeedZero	;randomize everything in the same way when displaying demo race
	jsr StartJoyPlayback
	jsr .CloseMainMenu
	rts

.SaveMenuSelections:
	lda _noofplayers		;save current selections in menu
	sta .noofplayers
	lda _track
	sta .track
	lda _max_speed
	sta .max_speed
	rts

.RestoreMenuSelections:
	lda .noofplayers		;restore current selections in menu
	sta _noofplayers
	lda .max_speed
	sta _max_speed
	lda .track
	sta _track
	rts

.CloseMainMenu:
	ldx #<L1_MAP_ADDR
	ldy #>L1_MAP_ADDR
	jsr ClearTextLayer
	jsr DisableLayer0		;temporary disable layer 0 while preparing racing track
	jsr SetLayer0ToTileMode
	lda #ST_SETUPRACE
	sta _gamestatus         ;update game status to start race, the menu handler will no longer be called
	rts

.HandleResetLeaderboard:
	lda .resetconfirmationflag
	bne +
	jsr .PrintConfirmationQuestion
	lda #1
	sta .resetconfirmationflag
	rts
+	stz .resetconfirmationflag
	lda .answer
	beq +
	jsr ResetLeaderboard
	jsr PrintLeaderboard
	lda #M_HANDLE_INPUT
	sta .menumode
	jsr SaveLeaderboard
	rts
+	lda #M_HANDLE_INPUT
	sta .menumode
	rts

.resetconfirmationflag	!byte 0		;flag that confirmation question is waiting for an answer

.HandleQuitGame:
	lda .quitconfirmationflag
	bne +
	jsr .PrintConfirmationQuestion
	lda #1
	sta .quitconfirmationflag
	rts
+	stz .quitconfirmationflag	
	lda .answer
	beq +
	lda #M_START_MUSIC
	sta .menumode					;set menu mode to start screen in case user starts game again
	lda #ST_QUITGAME
	sta _gamestatus					;set game status to break main loop, clean up and exit
	rts
+	lda #M_HANDLE_INPUT
	sta .menumode
	rts

.quitconfirmationflag	!byte 0		;flag that confirmation question is waiting for an answer

.PrintConfirmationQuestion:		;IN: .A = row to print question
	stz .answer					;default answer is "no"
	ldy .handrow
	lda .menuitems,y
	sta _row
	lda #10
	sta _col
	lda #MENU_BLACK
	sta _color
	lda #<.confirmation_question
	sta ZP0
	lda #>.confirmation_question
	sta ZP1
	jsr VPrintString
	jsr .PrintCurrentAnswer
	jsr .PrintHand
	rts

.PrintCurrentAnswer:
	ldy .handrow
	lda .menuitems,y
	sta _row				;IN: .A = row to print answer (a colored "Y/N")
	lda .answer
	bne +
	ldx #MENU_WHITE			;answer is no
	ldy #MENU_BLACK 
	bra ++
+	ldx #MENU_BLACK			;answer is yes
	ldy #MENU_WHITE
++	lda #YES_POSITION		;print "Y" in right color
	sta _col
	sty _color
	lda #S_Y
	phx
	jsr VPrintChar
	plx
	lda #NO_POSITION		;print "N" in right color
	sta _col
	stx _color
	lda #S_N
	jsr VPrintChar
	rts

.answer		!byte 0				;boolean, "yes" = true, "no" = false
YES_POSITION = 25
NO_POSITION  = 27

.ClearHand:
	lda #<.clearhandtext
	sta ZP0
	lda #>.clearhandtext
	sta ZP1	
	bra +
.PrintHand:
	lda #<.handtext
	sta ZP0
	lda #>.handtext
	sta ZP1
+	lda #4				;print hand from col 4 to 6
	sta _col
	ldy .handrow
	lda .menuitems,y
	sta _row
	tay
	lda .menurows,y
	sta _color
	jsr VPrintString
	rts

;*** Draw start screen and menu ********************************************************************

!macro	PrintLineBreaks .blocktable {
	stz _row
	ldx #0
-	lda .blocktable,x
	beq +
	clc
	adc _row
	sta _row
	lda #MIDDLE_LINE_DIV
	phx
	jsr VPrintLineBreak
	dec _row				;(subroutine increases row)
	plx
	inx
	bra -
+
}

.PrintFirstAndLastDividers:
	+SetPrintParams 0,0,$0b
	lda #FIRST_LINE_DIV
	jsr VPrintLineBreak

	+SetPrintParams 29,0,$0b
	lda #END_LINE_DIV
	jsr VPrintLineBreak
	rts

.ShowTitleImage:
	ldx #<L1_MAP_ADDR
	ldy #>L1_MAP_ADDR
	jsr ClearTextLayer
	jsr SetLayer0ToBitmapMode	;display title image by simply switching to bitmap mode
	rts

.InitScreen:
	ldx #<L0_MAP_ADDR
	ldy #>L0_MAP_ADDR
	jsr ClearTextLayer
	ldx #<L1_MAP_ADDR
	ldy #>L1_MAP_ADDR
	jsr ClearTextLayer
    jsr SetLayer0ToTextMode
	rts

.ShowCreditsScreen:
	jsr .InitScreen

	lda #<.startscreenbgblocks	;set block table pointer as in parameter
	sta .blocktable_lo
	lda #>.startscreenbgblocks
	sta .blocktable_hi
	jsr .FillLayer0WithColorBlocks
	jsr .PrintFirstAndLastDividers
	+PrintLineBreaks .startscreenbgblocks

	+SetPrintParams 3,0,$01
	lda #<.startscreentext
	sta ZP0
	lda #>.startscreentext
	sta ZP1
	lda #STARTSCREEN_ROW_COUNT
-	pha
	jsr VPrintString
	inc _row
	pla
	dec
	bne -
	rts

.ShowMainMenu:						;print complete menu including setting layers, clear layers and print all text
	jsr .InitScreen
	lda #<.menubgblocks			;set block table pointer as in parameter
	sta .blocktable_lo
	lda #>.menubgblocks
	sta .blocktable_hi
	jsr .FillLayer0WithColorBlocks	;print color blocks on background layer
	stz .handrow					;put selection hand on first row
	jsr PrintLeaderboard
	jsr .PrintFirstAndLastDividers
	+PrintLineBreaks .menubgblocks

.UpdateMainMenu:
	;print menu items
	lda #<.menutext
	sta ZP0
	lda #>.menutext
	sta ZP1
	stz _row
	lda #10
	sta _col
	ldx #0
-	phx
	lda .menurows,x
	sta _color
	jsr VPrintString
	plx
	inx
	cpx #MENU_ROW_COUNT
	bne -

	;print track names
	lda #<_tracknames
	sta ZP0
	lda #>_tracknames
	sta ZP1
	lda #6
	sta _row
	ldx #1
-	lda #10
	sta _col
	lda #10
	cpx _track
	beq +
	lda #$0b
	bra ++
+	lda #$01			;highlight selected track	
++	sta _color
	phx
	jsr VPrintString
	plx
	inx
	cpx #6
	bne -
	
	jsr .PrintHand
	rts

;*** Methods on layer 0 ********************************************************

.FillLayer0WithColorBlocks:
	lda .blocktable_lo
	sta ZP0
	lda .blocktable_hi
	sta ZP1
	lda	#$10				;increment 1
	sta	VERA_ADDR_H
	lda #>L0_MAP_ADDR
	sta	VERA_ADDR_M

	ldy #0					;color and block index
--- lda (ZP0),y				;get number of rows for current block
	beq +					;if 0 then return, table with number of rows for each block is terminated with 0
	tax
	lda #<L0_MAP_ADDR
	sta	VERA_ADDR_L			;set col 0
	phy
	tya
	and #7
	tay
	lda .colors,y			;get current color
	ply
	asl
	asl
	asl
	asl						;shift color to 4 upper bits = bg color
	sta ZP2
--	phx

	jsr .FillLayer0Row

	lda #<L0_MAP_ADDR
	sta	VERA_ADDR_L		;set col 0
	inc VERA_ADDR_M		;next row with same color
	plx
	dex
	bne --
	iny
	bra ---
+	rts

.FillLayer0Row:
	ldx #40					;40 columns in row
-	lda #S_SPACE
	sta VERA_DATA0			;write space character, only bg color is relevant
	lda ZP2
	sta VERA_DATA0			;write bg color that is read from table
	dex
	bne -
	rts

.UpdateRandomBgColor:		;update two following random rows with new random color
	lda #$20
	sta VERA_ADDR_H
	lda #>L0_MAP_ADDR
-	jsr GetRandomNumber1
	and #30
	cmp #28					;get even random number from 0-26
	bcc +
	bra -
+	clc
	adc #>L0_MAP_ADDR
	sta VERA_ADDR_M			;set random row
	lda #<L0_MAP_ADDR
	inc
	sta VERA_ADDR_L			;set col 0 second byte which contains color information

	jsr GetRandomNumber1
	and #7					;only 8 colors in table
	tay
	lda .colors,y			;load random color
	asl
	asl
	asl
	asl
	ldx #40
-	sta VERA_DATA0
	dex
	bne -
	ldy #<L0_MAP_ADDR
	iny
	sty VERA_ADDR_L		;set col 0
	inc VERA_ADDR_M		;next row
	ldx #40
-	sta VERA_DATA0
	dex
	bne -
	rts

.blocktable_lo	!byte 0
.blocktable_hi	!byte 0

;*** Start screen and menu data ************************************************

.colors										;colors that are used for background blocks
		!byte	14 ;light blue
		!byte	 9 ;brown
		!byte	 7 ;yellow
		!byte	15 ;light grey
		!byte    8 ;orange
		!byte	 4 ;violet/purple
		!byte	12 ;grey
		!byte	10 ;light red

.startscreenbgblocks
!byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,0		;table for how many rows each block is, zero terminated

.startscreentext:
!scr "   john karlin's rally speedway 2020",0
!scr 0
!scr "     a tribute to the original game",0
!scr "       for atari and commodore 64",0
!scr "           by john anderson",0
!scr 0
!scr "             copyright 2022",0
!scr "          by johan k;rlin and",0
!scr "        clergy games productions",0
!scr "          all rights reserved",0
!scr 0
!scr "             version 1.1",0

STARTSCREEN_ROW_COUNT = 12

.menubgblocks
!byte 2,3,6,4,2,2,10,0				;table for how many rows each block is, zero terminated

.menutext
!scr 0
!scr "start the race",0
!scr 0
!scr "one player",0
!scr "two players",0
!scr 0
!scr 0	;(track names)
!scr 0
!scr 0
!scr 0
!scr 0
!scr 0
!scr "low speed",0
!scr "normal speed",0
!scr "high speed",0
!scr 0
!scr "reset leaderboard   ",0	;add extra spaces to overwrite confirmation question if user says no
!scr 0
!scr "quit game           ",0	;add extra spaces to overwrite confirmation question if user says no
!scr 0

.confirmation_question	!scr "are you sure? (y/n)?",0

.handtext		!scr "<=>",0 ;char 60-62 = characters that form a hand
.clearhandtext	!scr "   ",0

.menuitems 		!byte 1,3,4,6,7,8,9,10,12,13,14,16,18	;which menu rows that represent menu items

.menurows	 						;menu rows table that holds information about both color and selection.
				!byte $b			; 1 = white color = selected (when relevant)
.startrace		!byte 1  			;$b = nontransparent black = not selected
				!byte $b
.oneplayer		!byte 1
.twoplayers		!byte $b
				!byte $b
.track1			!byte 1
.track2			!byte $b
.track3			!byte $b
.track4			!byte $b
.track5			!byte $b
				!byte $b
.lowspeed		!byte $b
.normalspeed	!byte 1
.highspeed		!byte $b
				!byte $b
.resetbest		!byte 1
				!byte $b
.quitgame		!byte 1
				!byte $b

MENU_ROW_COUNT = 20

.noofplayers	!byte 0			;used to store current selections when a demo race is about to start
.max_speed		!byte 0
.track			!byte 0