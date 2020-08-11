;*** Menu.asm - Start screen, menu, annoncements ******************************* 

;Menu status
M_SHOW_START_SCREEN 	= 0
M_UPDATE_START_SCREEN	= 1
M_SHOW_MAIN_MENU 		= 2
M_HANDLE_INPUT 			= 3
M_CONFIRM_RESET 		= 4
M_CONFIRM_QUIT			= 5

;Menu item mapping
START_RACE	=  1
ONE_PLAYER 	=  3
TWO_PLAYERS =  4
TRACK_1		=  6
TRACK_2		=  7
TRACK_3		=  8
TRACK_4		=  9
TRACK_5		= 10
RESET_BEST  = 16
QUIT_GAME	= 18

;Special characters used in menu
END_LINE_DIV	= 34 	;"
BLOCK			= 35	;#
MIDDLE_LINE_DIV	= 37 	;%
FIRST_LINE_DIV 	= 38	;&
HAND    		= 60    ;hand is char 60-62 = <=>

MenuHandler:
	lda .menumode

	;show start screen
	cmp #M_SHOW_START_SCREEN
	bne +
	jsr ShowStartScreen
	inc .menumode					;go to next mode - update start screen (change bg colors)
	rts

	;update start screen
+	cmp #M_UPDATE_START_SCREEN
	bne ++
	jsr UpdateRandomBgColor
	jsr UpdateRandomBgColor
	lda _joy0
	cmp #$ff				
	beq +
	inc .menumode           		;if anything at all is pressed, go to next mode - show menu 
+   rts

	;show menu
++  cmp #M_SHOW_MAIN_MENU
	bne +
	jsr ShowMainMenu				
	lda #M_HANDLE_INPUT				;next go to input menu mode
	sta .menumode
	lda #1
	sta .inputwait					;wait for controller to be released before accepting input again
	stz .inactivitytimer_lo			;reset timer that takes user back to start screen after 30 secs inactivity
	stz .inactivitytimer_hi	
	rts

	;wait for confirmation
+	cmp #M_CONFIRM_RESET
	bne ++
	jsr GETIN
	cmp #A_Y
	bne +
	jsr ResetLeaderboard
	jsr UpdateMainMenu
	lda #M_HANDLE_INPUT
	sta .menumode
	jsr SaveLeaderboard
	rts
+	cmp #A_N
	bne +
	jsr UpdateMainMenu
	lda #M_HANDLE_INPUT
	sta .menumode
+	rts

++	cmp #M_CONFIRM_QUIT
	bne ++
	jsr GETIN
	cmp #A_Y
	bne +
	jsr UpdateMainMenu
	lda #M_SHOW_START_SCREEN
	sta .menumode				;set menu mode to start screen in case user starts game again
	lda #ST_QUITGAME
	sta _gamestatus				;set game status to break main loop, clean up and exit
	rts
+	cmp #A_N
	bne +
	jsr UpdateMainMenu
	lda #M_HANDLE_INPUT
	sta .menumode
+	rts

	;handle user input
++	cmp #M_HANDLE_INPUT
	beq +
	rts

+   lda .inactivitytimer_hi
	cmp #7
	beq +
	jsr HandleUserInput
	rts

+	lda #M_SHOW_START_SCREEN
	sta .menumode	
	rts

.menumode				!byte 0
.inactivitytimer_lo		!byte 0		;timer to measure user inactivity
.inactivitytimer_hi		!byte 0

;*** Private methods ***********************************************************

HandleUserInput:
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

	;handle up/down
	jsr ClearHand
	lda _joy0
	bit #JOY_UP					;up?
	bne +
	jsr DecreaseHandRow

+	lda _joy0
	bit #JOY_DOWN				;down?
	bne +
	jsr IncreaseHandrow

	;handle button
+	lda _joy0	
	bit #JOY_BUTTON_A			;button a?
	beq +
	jsr PrintHand
	lda #1
	sta .inputwait
	rts

+	lda .handrow
	cmp #START_RACE			
	bne +						
	jsr CloseMainMenu
	rts

+	cmp #ONE_PLAYER
	bne +
	lda #1
	sta .oneplayer
	lda #$0b
	sta .twoplayers
	lda #1
	sta _noofplayers
	jsr UpdateMainMenu
	rts

+	cmp #TWO_PLAYERS
	bne +
	lda #1
	sta .twoplayers
	lda #$0b
	sta .oneplayer
	lda #2
	sta _noofplayers
	jsr UpdateMainMenu
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
	jsr UpdateMainMenu
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
	jsr UpdateMainMenu
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
	jsr UpdateMainMenu
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
	jsr UpdateMainMenu
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
	jsr UpdateMainMenu			;update menu to reflect new selection in text colors
    rts

+	cmp #RESET_BEST
	bne +
	ldx #$81
	stx _color
	jsr .PrintConfirmationQuestion
	lda #M_CONFIRM_RESET
	sta .menumode
	rts

+	cmp #QUIT_GAME
	bne +
	ldx #$41
	stx _color
	jsr .PrintConfirmationQuestion
	lda #M_CONFIRM_QUIT
	sta .menumode
+	rts

.inputwait	!byte 0			;boolean, when true wait for user to release controller

.PrintConfirmationQuestion:		;IN: .A = row to print question
	sta _row
	lda #10
	sta _col
	lda #<.confirmation_question
	sta ZP0
	lda #>.confirmation_question
	sta ZP1
	jsr VPrintString
	jsr PrintHand
	rts

IncreaseHandrow:
-	inc .handrow
	lda .handrow
	cmp #MENU_ROW_COUNT
	bne +
	lda #0
	sta .handrow
+	tay
	lda .mainmenu,y
	beq -
 	rts

DecreaseHandRow:
-	dec .handrow
	lda .handrow
	bpl +
	lda #MENU_ROW_COUNT-1
	sta .handrow
+	tay
	lda .mainmenu,y
	beq -
	rts

ClearHand:
	lda #8					;print hand from col 4 to 6
	sta	VERA_ADDR_L
	lda	.handrow
	sta	VERA_ADDR_M
	lda	#$20				;increment 2, leave color
	sta	VERA_ADDR_H
	lda #S_SPACE
	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0							
	rts

PrintHand:
	lda #8					;print hand from col 4 to 6
	sta	VERA_ADDR_L
	lda	.handrow
	sta	VERA_ADDR_M
	lda	#$20				;increment 2, leave color
	sta	VERA_ADDR_H
	lda #HAND
	sta VERA_DATA0
	lda #HAND+1
	sta VERA_DATA0
	lda #HAND+2
	sta VERA_DATA0							
	rts

.handrow	!byte 0

ShowStartScreen:
	jsr .InitScreen
	;lda #0
	; +VPoke PALETTE+22			;change dark grey to black, otherwise we cannot show black because orginal black is transparent
	; +VPoke PALETTE+23

	lda #<.startscreenbgblocks	;set block table pointer as in parameter
	sta .blocktable_lo
	lda #>.startscreenbgblocks
	sta .blocktable_hi
	jsr FillLayer0WithColorBlocks

	;Fill layer 1 with text and dividers
	stz .currentrow
	stz .textrow
	lda #<.startscreentext
	sta .text_lo
	lda #>.startscreentext
	sta .text_hi
	lda #<.startscreentextcolors
	sta .textcolors_lo
	lda #>.startscreentextcolors
	sta .textcolors_hi

	lda #FIRST_LINE_DIV
	jsr PrintLineLayer1

	lda #14						;print 14 rows of text including empty rows
-	pha
	jsr PrintTextLineLayer1
	lda #MIDDLE_LINE_DIV
	jsr PrintLineLayer1	
	pla
	dec
	bne -

	lda #S_SPACE
	jsr PrintLineLayer1
	lda #END_LINE_DIV
	jsr PrintLineLayer1
    rts

ShowMainMenu:						;print complete menu including setting layers, clear layers and print all text
	jsr .InitScreen	
	lda #<.mainmenubgblocks			;set block table pointer as in parameter
	sta .blocktable_lo
	lda #>.mainmenubgblocks
	sta .blocktable_hi
	jsr FillLayer0WithColorBlocks	;print color blocks on background layer
	lda #1							;put selection hand on first row
	sta .handrow

UpdateMainMenu:						;just print everything with current colors
	stz .currentrow
	stz .textrow
	lda #<.mainmenutext
	sta .text_lo
	lda #>.mainmenutext
	sta .text_hi
	lda #<.mainmenu
	sta .textcolors_lo
	lda #>.mainmenu
	sta .textcolors_hi

	lda #FIRST_LINE_DIV
	jsr PrintLineLayer1
	
	jsr PrintTextLineLayer1 		;"start race"
	lda #MIDDLE_LINE_DIV
	jsr PrintLineLayer1

	jsr PrintTextLineLayer1			;"one player"
	jsr PrintTextLineLayer1			;"two players"
	lda #MIDDLE_LINE_DIV
	jsr PrintLineLayer1	

	jsr PrintTextLineLayer1			;"track 1", "track 2"...
	jsr PrintTextLineLayer1
	jsr PrintTextLineLayer1
	jsr PrintTextLineLayer1
	jsr PrintTextLineLayer1
	lda #MIDDLE_LINE_DIV
	jsr PrintLineLayer1	

	jsr PrintTextLineLayer1			;"load trax"
	jsr PrintTextLineLayer1			;"make trax"
	jsr PrintTextLineLayer1			;"save trax"
	lda #MIDDLE_LINE_DIV
	jsr PrintLineLayer1	

	jsr PrintTextLineLayer1			;"Reset leaderboard"
	lda #MIDDLE_LINE_DIV
	jsr PrintLineLayer1	

	jsr PrintTextLineLayer1			;"quit game"
	lda #END_LINE_DIV
	jsr PrintLineLayer1

	jsr PrintTextLineLayer1			;(empty row)
	jsr PrintTextLineLayer1			;"Leaderboard"
	jsr PrintTextLineLayer1			;"Time Name"
	jsr PrintTextLineLayer1			;"Track 1"
	jsr PrintTextLineLayer1			;"Track 2"
	jsr PrintTextLineLayer1			;"Track 3"
	jsr PrintTextLineLayer1			;"Track 4"
	jsr PrintTextLineLayer1			;"Track 5"
	jsr PrintTextLineLayer1			;(empty row)

	lda #BLOCK
	jsr PrintLineLayer1
	jsr PrintLeaderboard

	jsr PrintHand
	rts

.InitScreen:
    jsr SetLayer0ToTextMode
	ldx #<L0_MAP_ADDR
	ldy #>L0_MAP_ADDR
	jsr ClearTextLayer
	ldx #<L1_MAP_ADDR
	ldy #>L1_MAP_ADDR
	jsr ClearTextLayer
	rts

CloseMainMenu:
	; lda #$33
	; +VPoke PALETTE+22		;Restore black to dark grey
	; lda #$03
	; +VPoke PALETTE+23
	jsr SetLayer0ToTileMode
	ldx #<L1_MAP_ADDR
	ldy #>L1_MAP_ADDR
	jsr ClearTextLayer
	lda #M_SHOW_MAIN_MENU
	sta .menumode			;prepare for the next time the menu handler will be called, then we skip start screen and go directly to the main menu
	lda #START_RACE
	sta _gamestatus         ;update game status to start race, the menu handler will no longer be called
	rts

;*** Methods on layer 0 ********************************************************

FillLayer0WithColorBlocks:
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

UpdateRandomBgColor:		;update two following random rows with new random color
	lda #$20
	sta VERA_ADDR_H
	lda #>L0_MAP_ADDR
-	jsr GetRandomNumber
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

	jsr GetRandomNumber
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

GetRandomNumber:
	lda .randomnumber
	beq +
	asl
	beq ++					;if the input was $80, skip the EOR
	bcc ++
+   eor #$1d
++  sta .randomnumber
	rts

.randomnumber	!byte 0

;*** methods on layer 1 ********************************************************

PrintLineLayer1:			;IN: .A = screen code of char
	stz	VERA_ADDR_L
	ldx	.currentrow
	stx	VERA_ADDR_M
	ldx	#$10				;increment 1
	stx	VERA_ADDR_H
	cmp #S_SPACE
	bne +
	ldy #$00				;transparent if empty row
	bra ++
+	ldy #$0b				;bg = transparent, fg = black
++	ldx #40
-	sta VERA_DATA0			;.A = char						
	sty VERA_DATA0			;color
	dex
	bne -
	inc .currentrow
	rts

PrintTextLineLayer1:
	stz	VERA_ADDR_L
	lda	.currentrow
	sta	VERA_ADDR_M
	lda	#$10				;increment 1
	sta	VERA_ADDR_H

	;get start address for text
	lda .text_lo
	sta ZP0					
	lda .text_hi
	sta ZP1
	ldx .textrow
	beq +
-	lda #40					;add row * 40, 40 = length of each text row
	clc
	adc ZP0
	sta ZP0
	lda #0
	adc ZP1
	sta ZP1
	dex
	bne -

	;get start address for text colors
+	lda .textcolors_lo
	sta ZP2
	lda .textcolors_hi
	sta ZP3
	ldy .currentrow

	;print line (= 40 characters)
	ldx #40
- 	lda (ZP0)			;read char
	sta VERA_DATA0
	lda (ZP2),y			;read color (same for whole line)
	sta VERA_DATA0
	lda	#1
	clc
	adc	ZP0
	sta	ZP0
	lda	#0
	adc	ZP1
	sta	ZP1
	dex
	bne -
	inc .currentrow
	inc .textrow
	rts

.textrow		!byte 0
.currentrow		!byte 0
.text_lo		!byte 0
.text_hi		!byte 0
.blocktable_lo	!byte 0
.blocktable_hi	!byte 0
.textcolors_lo	!byte 0
.textcolors_hi	!byte 0

;*** Start screen and menu data ************************************************

.colors										;colors that are used for background blocks
		!byte	14 ;light blue
		!byte	 9 ;brown
		!byte	 7 ;yellow
		!byte	15 ;light grey 12 ;grey
		!byte    8 ;orange
		!byte	 4 ;violet/purple
		!byte	12 ;grey
		!byte	10 ;light red 

.startscreentext:
!scr "                                        "
!scr "   john karlin's rally speedway v 0.1   "
!scr "                                        "
!scr "       a tribute to the original        "
!scr "           atari and c64 game           "
!scr "            by john anderson            "
!scr "                                        "
!scr "                                        "
!scr "           a free gift to all           "
!scr "       friends of retro computers       "
!scr "                                        "
!scr "      press button a for start menu     "
!scr "                                        "
!scr "                                        "

.startscreenbgblocks
!byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,0		;table for how many rows each block is, zero terminated

.startscreentextcolors
!byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

.mainmenutext
!scr "          start the race                "
!scr "          one player                    "
!scr "          two players                   "
!scr "          track 1                       "
!scr "          track 2                       "
!scr "          track 3                       "
!scr "          track 4                       "
!scr "          track 5                       "
!scr "          load trax                     "
!scr "          make trax                     "
!scr "          save trax                     "
!scr "          reset leaderboard             "
!scr "          quit game                     "
!scr "                                        "
!scr "      leaderboard                       "
!scr "              time     name             "
!scr "      track 1                           "
!scr "      track 2                           "
!scr "      track 3                           "
!scr "      track 4                           "
!scr "      track 5                           "
!scr "                                        "

.reset_leaderboard		!scr "reset leaderboard  ",0
.confirmation_question	!scr "are you sure (y/n)?",0

.mainmenubgblocks
!byte 2,3,6,4,2,2,10,0				;table for how many rows each block is, zero terminated

MENU_ROW_COUNT = 20

.mainmenu	 						;menu rows with colors, , 1 = white color, $b = non transparent 
				!byte 0				;0 = divider row, not a menu item
.startrace		!byte 1  			;1 = white color
				!byte 0
.oneplayer		!byte 1
.twoplayers		!byte $b			;$b = nontransparent black color representing that item not selected
				!byte 0
.track1			!byte 1
.track2			!byte $b
.track3			!byte $b
.track4			!byte $b
.track5			!byte $b
				!byte 0
.loadtrax		!byte 1
.maketrax		!byte 1
.savetrax		!byte 1
				!byte 0
.resetbest		!byte 1
				!byte 0
.quitgame		!byte 1
				!byte 0
				!byte 1,1,1,1,1,1,1,1,1	;leaderboard rows (not part of the actual menu)

