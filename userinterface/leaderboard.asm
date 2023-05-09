;*** leaderboard.asm *******************************************************************************

LEADERBOARD_COLORS = $c1
LEADERBOARD_ROW = 21
LEADERBOARD_COL = 1
LEADERBOARD_TIME_COL = LEADERBOARD_COL + 18
LEADERBOARD_NAME_COL = LEADERBOARD_COL + 27
LEADERBOARD_NAME_LENGTH = 11
LEADERBOARD_NUMBER_OF_TRACKS = 5

;*** Public ****************************************************************************************

PrintLeaderboard:

        ;print headings
        +SetPrintParams LEADERBOARD_ROW, LEADERBOARD_COL, LEADERBOARD_COLORS
        lda #<.heading
        sta ZP0
        lda #>.heading
        sta ZP1
        jsr VPrintString

        ;print name of tracks
        inc _row
        lda #<_tracknames
        sta ZP0
        lda #>_tracknames
        sta ZP1
        lda #LEADERBOARD_NUMBER_OF_TRACKS
-       pha
        jsr VPrintString
        pla
        dec
        bne -

	;print record times
        +SetPrintParams LEADERBOARD_ROW+2, LEADERBOARD_TIME_COL, LEADERBOARD_COLORS
        ldy #0
-	lda .leaderboard_records,y
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
	cpy #LEADERBOARD_NUMBER_OF_TRACKS*3	;3 values for each track
	bne -

	;print names of record holders
        +SetPrintParams LEADERBOARD_ROW+2, LEADERBOARD_NAME_COL, LEADERBOARD_COLORS
        lda #0
-	ldx #<.leaderboard_names
	stx ZP0
	ldx #>.leaderboard_names
	stx ZP1
	pha
	jsr VPrintStringInArray
	pla
	inc
	cmp #LEADERBOARD_NUMBER_OF_TRACKS
	bne -
        rts

SetLeaderboardName:                             ;IN: .A = track number. ZP0, ZP1 = address of new name.
        ldx ZP0
        stx .newname
        ldx ZP1
        stx .newname + 1                        ;store new name temporarily
        ldx #<.leaderboard_names
        stx ZP0
        ldx #>.leaderboard_names
        stx ZP1
        dec                                     ;decrease .A because array is zero-indexed
        jsr GetStringInArray                    ;get current name
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
        rts

.newname        !byte 0,0

GetLeaderboardRecord:                           ;IN: .A = track number. OUT: ZP0 = minutes, ZP1 = seconds, ZP2 = jiffies
        jsr .GetTimeIndex
        tay
        lda .leaderboard_records,y
        sta ZP0
        lda .leaderboard_records+1,y
        sta ZP1
        lda .leaderboard_records+2,y
        sta ZP2
        rts

SetLeaderboardRecord:                           ;IN: .A = track number. ZP0 = minutes, ZP1 = seconds, ZP2 = jiffies
        jsr .GetTimeIndex
        tay
        lda ZP0
        sta .leaderboard_records,y
        lda ZP1
        sta .leaderboard_records+1,y
        lda ZP2
        sta .leaderboard_records+2,y        
        rts

IsNewLeaderboardRecord:                         ;IN: .A = track number. ZP0-ZP2 = time. OUT: .C = clear if time < current record
        ldx ZP0
        stx ZP3
        ldx ZP1
        stx ZP4
        ldx ZP2
        stx ZP5                                 ;time to compare in ZP3-ZP5
        jsr GetLeaderboardRecord                ;leaderboard time in ZP0-ZP2
        lda ZP0
        bne +
        lda ZP1
        bne +
        lda ZP2
        bne +
        clc                                     ;answer is yes if leaderboard record is 00:00:00 which means that no record exists
        rts
+       jsr IsTimeLess                          ;carry flag will be clear if less 
        rts

LoadLeaderboard:
        lda #<.leaderboardname
        sta ZP0
        lda #>.leaderboardname
        sta ZP1
        lda #<.leaderboard
        sta ZP2
        lda #>.leaderboard
        sta ZP3
        lda #LOAD_TO_RAM
        sta ZP4
        lda #FILE_HAS_HEADER
        sta ZP5
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

;*** Private ***************************************************************************************

.GetTimeIndex:                                  ;IN: .A = track number. OUT: .A = index for record in record array
        dec
        tax
        lda #0
-       cpx #0
        beq +
        clc
        adc #3
        dex
        bra -
+       rts

.leaderboardname        !raw "@:LEADERBOARD.BIN",0

.heading                !scr "%%%%%%%%%%%% leaderboard %%%%%%%%%%%%%",0

.leaderboard            ;data are read from file
.leaderboard_names      !fill LEADERBOARD_NUMBER_OF_TRACKS*12,0 ;each name is max 11 chars long
.leaderboard_records    !fill LEADERBOARD_NUMBER_OF_TRACKS*3 ,0 ;each time takes 3 bytes (minutes, seconds and jiffies)
.leaderboard_end

.default_leaderboard    !for i,1,LEADERBOARD_NUMBER_OF_TRACKS { !scr "-----      ",0 }
                        !fill LEADERBOARD_NUMBER_OF_TRACKS*3,0