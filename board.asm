;*** board.asm - board displayed when race is finished *********************************************

BOARD_COLOR = 12        ;grey 
BOARD_TEXT_COLOR = 1    ;white

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
        lda #(BOARD_COLOR<<4) + BOARD_TEXT_COLOR
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
        +PrintBoardShadow .width, .height, .startrow, .startcol               
}

!macro PrintBoardString .row, .col, .text {
        lda #(BOARD_COLOR<<4) + BOARD_TEXT_COLOR
        sta _color
        lda #.row
        sta _row
        lda #.col
        sta _col
        lda .text
        jsr VPrintString
}

!macro PrintBoardValue .row, .col, .value {
        lda #(BOARD_COLOR<<4) + BOARD_TEXT_COLOR
        sta _color
        lda #.row
        sta _row
        lda #.col
        sta _col
        lda .value
        jsr VPrintDecimalNumber
}

PrintBoard:
        lda _noofplayers
        cmp #1
        bne +
        jsr .PrintOnePlayerBoard
        rts
+       jsr .PrintTwoPlayerBoard
        rts

.PrintOnePlayerBoard:
        jsr .IsRecord
        bne +
        jmp ++ 
+       +PrintBoard 25, 11,  9,  7, .extsboard
        +PrintBoardValue    15, 21, _ycarcollisioncount
        +PrintBoardString   12,  8, .sboardrecord
        rts
++      +PrintBoard 25,  9,  9,  7, .sboard
        +PrintBoardValue    13, 21, _ycarcollisioncount 
        rts

.PrintTwoPlayerBoard:
        jsr .IsRecord
        bne +
        jmp ++ 
+       +PrintBoard 36, 14,  9,  2, .extdboard
        +PrintBoardValue    16, 17, _ycarcollisioncount
        +PrintBoardValue    17, 17, _ycarpenaltycount
        +PrintBoardValue    16, 28, _bcarcollisioncount
        +PrintBoardValue    17, 28, _bcarpenaltycount
        lda _ycarfinishflag
        beq +
        +PrintBoardString   12,  7, .dboardrecordycar
        rts
+       +PrintBoardString   12,  7, .dboardrecordbcar
        rts
++      +PrintBoard 36, 12,  9,  2, .dboard
        +PrintBoardValue    16, 17, _ycarcollisioncount
        +PrintBoardValue    17, 17, _ycarpenaltycount
        +PrintBoardValue    16, 28, _bcarcollisioncount
        +PrintBoardValue    17, 28, _bcarpenaltycount
        rts

.IsRecord
        lda #1  ;TODO!
        rts

.extsboard          !scr "                         ",0
                    !scr "                         ",0
.sboard             !scr "                         ",0
                    !scr "                         ",0
                    !scr "                         ",0
                    !scr "    race time            ",0
                    !scr "      crashes            ",0
                    !scr "  finish time            ",0
                    !scr "                         ",0
                    !scr " press start to continue ",0
                    !scr "                         ",0

.sboardrecord       !scr "new record - well done!",0

.extdboard          !scr "                                    ",0
                    !scr "                                    ",0
.dboard             !scr "                                    ",0
                    !scr "                                    ",0
                    !scr "                                    ",0
                    !scr "               yellow car blue car  ",0
                    !scr "     race time                      ",0
                    !scr "       crashes                      ",0
                    !scr "  outdistanced                      ",0
                    !scr "    time added                      ",0
                    !scr "   finish time                      ",0
                    !scr "                                    ",0
                    !scr "       press start to continue      ",0
                    !scr "                                    ",0 

.dboardrecordycar   !scr "new record by yellow car!",0
.dboardrecordbcar   !scr " new record by blue car! ",0