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

!macro PrintBoardValue .row, .col, .value {
        lda #.row
        sta _row
        lda #.col
        sta _col
        lda .value
        jsr VPrintDecimalNumber
}

!macro PrintYCarTime .row, .col {
        lda _color
        ldy #.row
        ldx #.col
        jsr YCar_DisplayTime    
}

!macro PrintBCarTime .row, .col {
        lda _color
        ldy #.row
        ldx #.col
        jsr BCar_DisplayTime    
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
        jsr .IsRecord
        bcc +
        jsr .PrintOnePlayerBoard
        rts
+       jsr .PrintOnePlayerRecordBoard
        rts
++      jsr .IsRecord
        bcc +
        jsr .PrintTwoPlayerBoard
        rts
+       jsr .PrintTwoPlayerRecordBoard
        rts

;*** private subroutines ***************************************************************************

.PrintOnePlayerBoard:
        +PrintBoard 25, 9, 9, 7, .sboard                ;print board
        jmp +

.PrintOnePlayerRecordBoard:
        +PrintBoard 25, 11, 9, 7, .sboard               ;print extended board
        +PrintBoardString 16, 7, .sboardrecord          ;print record message
        lda #BOARD_COLORS
        sta _color
+       +PrintBoardValue 13, 21, _ycarcollisioncount    ;print number of crashes
        +PrintYCarTime 14, 21                           ;print finish time
        lda _ycarcollisioncount
        jsr YCar_TimeSubSeconds
        +PrintYCarTime 12, 21                           ;print race time
        +InitBoardInput 18, 20
        rts

.PrintTwoPlayerBoard:
        +PrintBoard 36, 11, 9, 2, .dboard
        +PrintBoardString 18, 2, .dboardcontinue
        jmp ++

.PrintTwoPlayerRecordBoard:
        +PrintBoard 36, 13, 9, 2, .dboard
        lda _ycarfinishflag
        beq +
        lda #BOARD_YELLOW
        sta _color
        +PrintBoardString 18, 2, .dboardrecordycar
        bra ++
+       lda #BOARD_BLUE
        sta _color
        +PrintBoardString 18, 2, .dboardrecordbcar

++      lda #BOARD_YELLOW
        sta _color
        +PrintBoardString 12, 17, .dboardycar
        lda #BOARD_BLUE
        sta _color
        +PrintBoardString 12, 28, .dboardbcar
        lda #BOARD_COLORS
        sta _color
        +PrintBoardValue 14, 17, _ycarcollisioncount
        +PrintBoardValue 15, 17, _ycarpenaltycount
        +PrintBoardValue 14, 28, _bcarcollisioncount
        +PrintBoardValue 15, 28, _bcarpenaltycount

        +PrintYCarTime 16, 17           ;print yellow car finish time
        lda _ycarcollisioncount
        jsr YCar_TimeSubSeconds
        +PrintYCarTime 13, 17           ;print actual race time (without added penalty time)
        lda _ycarcollisioncount
        jsr YCar_TimeAddSeconds

        +PrintBCarTime 16, 28           ;print blue car finish time
        lda _bcarcollisioncount
        jsr BCar_TimeSubSeconds
        +PrintBCarTime 13, 28           ;print actual race time (without added penalty time)
        lda _bcarcollisioncount
        jsr BCar_TimeAddSeconds
        rts

.IsRecord
        clc
        rts
        lda _ycarfinishflag
        beq +
        lda _ycartime
        sta ZP0
        lda _ycartime+1
        sta ZP1
        lda _ycartime+2
        sta ZP2
        bra ++
+       lda _bcartime
        sta ZP0
        lda _bcartime+1
        sta ZP1
        lda _bcartime+2
        sta ZP2
++      lda _track
        jsr IsNewLeaderboardRecord
        bcc +
        rts
+       lda _track
        jsr SetLeaderboardRecord
        clc
        rts

;*** board data ************************************************************************************

_boardinputflag         !byte 0 ;flag set when waiting for player to enter new name for record

.sboard                 !scr "                         ",0
                        !scr "                         ",0
                        !scr "                         ",0
                        !scr "    race time            ",0
                        !scr "      crashes            ",0
                        !scr "  finish time            ",0
                        !scr "                         ",0
                        !scr " press start to continue ",0
                        !scr "                         ",0          ;one player, no record: print to this line
.sboardcontinue         !scr " enter name:             ",0
                        !scr "                         ",0          ;one player, new record: print to this line and replace "start to continue"-text with "new record"-text

.sboardrecord           !scr " new record - well done! ",0

.dboard                 !scr "                                    ",0
                        !scr "                                    ",0
                        !scr "                                    ",0
                        !scr "               yellow car blue car  ",0
                        !scr "     race time                      ",0
                        !scr "       crashes                      ",0
                        !scr "  outdistanced                      ",0
                        !scr "   finish time                      ",0
                        !scr "                                    ",0
                        !scr "                                    ",0
                        !scr "                                    ",0       ;two players, no record: print to this line and then add "press start to continue" above
.dboardcontinue         !scr "      press start to continue       ",0
                        !scr "                                    ",0       ;two players, new record: print to this line and then add "new record by NN car" above

.dboardrecordycar       !scr "     new record by yellow car!      ",0
.dboardrecordbcar       !scr "      new record by blue car!       ",0
.dboardycar             !scr "yellow car",0
.dboardbcar             !scr "blue car",0