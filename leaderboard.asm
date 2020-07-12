;*** leaderboard.asm *******************************************************************************

LEADERBOARD_ROW = 23
LEADERBOARD_COL = 18
LEADERBOARD_NAME_OFFSET = 9
LEADERBOARD_NAME_LENGTH = 10

PrintLeaderboard:
	;print record times
	lda #BOARD_COLORS       ;fg = grey, fg = white
	sta _color
	lda #LEADERBOARD_ROW
	sta _row
	ldy #0
-	lda #LEADERBOARD_COL
	sta _col
	lda .leaderboard_records,y
	sta ZP0
	lda .leaderboard_records+1,y
	sta ZP1
	lda .leaderboard_records+2,y
	sta ZP2
	phy
	jsr VPrintNullableTime
	ply
	iny
	iny
	iny
	cpy #5*3	;5 tracks, 3 values for each track
	bne -

	;print names of record holders
	ldx #BOARD_COLORS
	stx _color
	ldx #LEADERBOARD_ROW
	stx _row
	lda #0
-	ldx #LEADERBOARD_COL + LEADERBOARD_NAME_OFFSET
	stx _col
	ldx #<.leaderboard_names
	stx ZP0
	ldx #>.leaderboard_names
	stx ZP1
	pha
	jsr VPrintStringInArray
	pla
	inc
	cmp #5
	bne -
	rts

LeaderboardInputInit:
	lda #LEADERBOARD_ROW
        clc
        adc .leaderboard_new_record_flag
	sta _row
	lda #LEADERBOARD_COL + LEADERBOARD_NAME_OFFSET
	sta _col
        lda #LEADERBOARD_NAME_LENGTH
	jsr InputStringInit
        rts

GetLeaderboardUpdateFlag:                       ;OUT: .A = track number (zero indexed). -1 if not set
        lda .leaderboard_new_record_flag
        rts

SetLeaderboardUpdateFlag:                       ;IN: .A = track number (zero-indexed)
        sta .leaderboard_new_record_flag
        rts

UpdateLeaderboardName:                          ;IN: ZP0, ZP1 = address of new name.
        lda ZP0
        sta .newname
        lda ZP1
        sta .newname + 1                        ;store new name temporarily
        lda #<.leaderboard_names
        sta ZP0
        lda #>.leaderboard_names
        sta ZP1
        lda .leaderboard_new_record_flag
        cmp #-1                                 ;return if update flag is not set
        bne +
        rts
+       jsr GetStringInArray                    ;get current name
        lda ZP0
        sta ZP2
        lda ZP1
        sta ZP3                                 ;ZP2, ZP3 = current name
        lda .newname
        sta ZP0
        lda .newname + 1
        sta ZP1                                 ;ZP1, ZP2 = new name
        lda #LEADERBOARD_NAME_LENGTH
        sta ZP4
        stz ZP5                                 ;ZP4, ZP5 = string length
        jsr CopyMem                             ;update name
        lda #-1
        sta .leaderboard_new_record_flag
        rts

.newname        !byte 0,0

LoadLeaderboard:
        lda #<.leaderboardname
        sta ZP0
        lda #>.leaderboardname
        sta ZP1
        lda #<.leaderboard
        sta ZP2
        lda #>.leaderboard
        sta ZP3
        lda #0
        sta ZP4
        jsr LoadFile            ;call filehandler
        bcc +
        jsr SaveLeaderboard     ;if load fails, create a new file
+       rts

SaveLeaderboard:
        lda #<.leaderboardname
        sta ZP0
        lda #>.leaderboardname
        sta ZP1
        lda #<.leaderboard
        sta ZP2
        lda #>.leaderboard
        sta ZP3
        lda #<.leaderboard_end
        sta ZP4
        lda #>.leaderboard_end
        sta ZP5
        jsr SaveFile            ;call filehandler
        rts  

ResetLeaderboard:               ;copy default leaderboard to leaderboard
        lda #<.default_leaderboard
        sta ZP0
        lda #>.default_leaderboard
        sta ZP1
        lda #<.leaderboard
        sta ZP2
        lda #>.leaderboard
        sta ZP3
        lda #.leaderboard_end-.leaderboard
        sta ZP4
        lda #0
        sta ZP5
        jsr CopyMem
        rts

.leaderboard_new_record_flag    !byte -1 ;TEMP!  ;flag that name of record holder should be updated. Values 0-4 = track 1-4

.leaderboardname        !raw "X16-RALLYSPEEDWAY/LEADERBOARD.BIN",0

.leaderboard                                    ;data are read from file
.leaderboard_names      !scr "-----     ",0
                        !scr "-----     ",0
                        !scr "-----     ",0
                        !scr "-----     ",0
                        !scr "-----     ",0

.leaderboard_records    !byte 0,0,0             ;track 1 - minutes, second, jiffies
                        !byte 0,0,0             ;track 2
                        !byte 0,0,0             ;track 3
                        !byte 0,0,0             ;track 4
                        !byte 0,0,0             ;track 5
.leaderboard_end

.default_leaderboard
                        !scr "-----     ",0
                        !scr "-----     ",0
                        !scr "-----     ",0
                        !scr "-----     ",0
                        !scr "-----     ",0
                        !fill 15,0