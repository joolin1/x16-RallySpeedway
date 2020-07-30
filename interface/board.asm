;*** board.asm - board displayed when race is finished *********************************************

BOARD_COLORS = $c1      ;bg color = grey, fg color = white 
BOARD_YELLOW = $c7      ;bg color = grey, fg color = yellow
BOARD_BLUE   = $c6      ;bg color = grey, fg color = blue  

;Special characters used for board shadow effect
BOTTOM_RIGHT_BORDER = 27
BOTTOM_LEFT_BORDER  = 28
TOP_RIGHT_BORDER    = 29
RIGHT_BORDER        = 31
BOTTOM_BORDER       = 36

;*** marcros for printing board ********************************************************************

!macro PrintBoardShadow .width, .height, .startrow, .startcol {
        ;print bottom shadow
        lda #$0b                ;bg = transparent, fg = black
        sta _color

        lda #.startrow + .height
        sta _row
        lda #.startcol
        sta _col
        lda #BOTTOM_LEFT_BORDER
        jsr VPrintChar
        ldx #.width - 1
-       lda #BOTTOM_BORDER
        phx
        jsr VPrintChar
        plx
        dex
        bne -
        lda #BOTTOM_RIGHT_BORDER
        jsr VPrintChar

        ;print right shadow
        lda #.startrow
        sta _row
        lda #.startcol + .width
        sta _col
        lda #TOP_RIGHT_BORDER
        jsr VPrintChar
        dec _col
        inc _row
        ldy #.height-1
-       lda #RIGHT_BORDER
        phy
        jsr VPrintChar
        ply
        dec _col
        inc _row
        dey
        bne -
}

!macro PrintBoard .width, .height, .startrow, .startcol, .text {
        +PrintBoardShadow .width, .height, .startrow, .startcol
        lda #BOARD_COLORS
        sta _color
        lda #<.text
        sta ZP0
        lda #>.text
        sta ZP1
        lda #.startrow
        sta _row
        ldy #.height
-       lda #.startcol
        sta _col
        phy
        jsr VPrintString
        ply
        dey
        bne -              
}

!macro PrintBoardString .row, .col, .text {
        lda #.row
        sta _row
        lda #.col
        sta _col
        lda #<.text
        sta ZP0
        lda #>.text
        sta ZP1
        jsr VPrintString
}

!macro PrintCarTime .row, .col, .time {
        +SetPrintParams .row, .col, BOARD_COLORS
        +SetParams .time, .time+1, .time+2
        jsr VPrintTime    
}

!macro PrintAddedTime .row, .col, .seconds {
        +SetPrintParams .row, .col, BOARD_COLORS
        lda .seconds
        jsr VPrintSeconds
}

!macro InitBoardInput .row, .col {
        lda #.row
        sta _row
        lda #.col
        sta _col
        lda #LEADERBOARD_NAME_LENGTH
        jsr InitInputString
        lda #1
        sta _boardinputflag
}

;*** public subroutines ****************************************************************************

PrintBoard:
        lda _noofplayers
        cmp #1
        bne ++
        lda _isrecord
        bne +
        jsr .PrintOnePlayerBoard
        rts
+       jsr .PrintOnePlayerRecordBoard
        rts
++      lda _isrecord
        bne +
        jsr .PrintTwoPlayerBoard
        rts
+       jsr .PrintTwoPlayerRecordBoard
        rts

;*** private subroutines ***************************************************************************

.PrintOnePlayerBoard:
        +PrintBoard 25, 9, 9, 7, .sboard                ;print board
        jsr .PrintOnePlayerData
        rts

.PrintOnePlayerRecordBoard:
        +PrintBoard 25, 11, 9, 7, .sboard               ;print extended board
        lda #BOARD_YELLOW
        sta _color
        +PrintBoardString 16, 7, .sboardrecord          ;print record message
        jsr.PrintOnePlayerData
        +InitBoardInput 18, 20
        lda #BOARD_COLORS
        sta _color
        rts

.PrintOnePlayerData:
        lda #BOARD_COLORS
        sta _color
        +PrintAddedTime 13,24,_ycarcollisioncount       ;print added time due to crashes
        +PrintCarTime 14, 21, _ycartime                 ;print finish time
        lda _ycarcollisioncount
        clc
        adc _ycarpenaltycount
        jsr YCar_TimeSubSeconds
        +PrintCarTime 12, 21, _ycartime                 ;print race time
        rts

.PrintTwoPlayerBoard:
        +PrintBoard 36, 11, 9, 2, .dboard
        jsr .PrintTwoPlayerData
        rts

.PrintTwoPlayerRecordBoard:
        +PrintBoard 36, 13, 9, 2, .dboard
        lda _winner                                     ;announce which car holds the new record (can also be both!)
        bne +
        lda #BOARD_YELLOW
        sta _color
        +PrintBoardString 18, 2, .dboardrecordbothcars
        bra ++
+       cmp #1
        bne +
        lda #BOARD_YELLOW
        sta _color
        +PrintBoardString 18, 2, .dboardrecordycar
        bra ++
+       lda #BOARD_BLUE
        sta _color
        +PrintBoardString 18, 2, .dboardrecordbcar
++      jsr .PrintTwoPlayerData
        +InitBoardInput 20,20
        lda #BOARD_COLORS
        sta _color
        rts

.PrintTwoPlayerData:
        lda #BOARD_YELLOW
        sta _color
        +PrintBoardString 12, 17, .dboardycar
        lda #BOARD_BLUE
        sta _color
        +PrintBoardString 12, 28, .dboardbcar
        lda #BOARD_COLORS
        sta _color
        +PrintAddedTime 14, 20, _ycarcollisioncount
        +PrintAddedTime 15, 20, _ycarpenaltycount
        +PrintAddedTime 14, 31, _bcarcollisioncount
        +PrintAddedTime 15, 31, _bcarpenaltycount

        +PrintCarTime 16, 17, _ycartime ;print yellow car finish time
        lda _ycarcollisioncount
        clc
        adc _ycarpenaltycount
        jsr YCar_TimeSubSeconds
        +PrintCarTime 13, 17, _ycartime ;print actual race time (without added penalty time)

        +PrintCarTime 16, 28, _bcartime ;print blue car finish time
        lda _bcarcollisioncount
        clc
        adc _bcarpenaltycount
        jsr BCar_TimeSubSeconds
        +PrintCarTime 13, 28, _bcartime ;print actual race time (without added penalty time)
        rts

;*** board data ************************************************************************************

_boardinputflag         !byte 0 ;flag set when waiting for player to enter new name for record

.sboard                 !scr "                         ",0
                        !scr "                         ",0
                        !scr "                         ",0
                        !scr "   race time             ",0
                        !scr "     crashes    +        ",0
                        !scr "  total time             ",0
                        !scr "                         ",0
                        !scr " press start to continue ",0
                        !scr "                         ",0          ;one player, no record: print no further than this

                        !scr " enter name:             ",0
                        !scr "                         ",0          ;one player, new record: print to the end and replace "start to continue"-text with "new record"-text

.sboardrecord           !scr " new record - well done! ",0

.dboard                 !scr "                                    ",0
                        !scr "                                    ",0
                        !scr "                                    ",0
                        !scr "               yellow car blue car  ",0
                        !scr "    race time                       ",0
                        !scr "      crashes    +          +       ",0
                        !scr " outdistanced    +          +       ",0
                        !scr "   total time                       ",0
                        !scr "                                    ",0
                        !scr "      press start to continue       ",0
                        !scr "                                    ",0       ;two players, no record: print no further than this and then add "press start to continue" above
                        
                        !scr "      enter name:                   ",0
                        !scr "                                    ",0       ;two players, new record: print to the end and replace "start to continue"-text with "new record"-text

.dboardrecordycar       !scr "     new record by yellow car!      ",0
.dboardrecordbcar       !scr "      new record by blue car!       ",0
.dboardrecordbothcars   !scr "      new record by both cars!      ",0
.dboardycar             !scr "yellow car",0
.dboardbcar             !scr "blue car",0