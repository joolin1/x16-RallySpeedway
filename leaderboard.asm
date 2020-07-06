;*** leaderboard.asm *******************************************************************************

LoadLeaderboard
        lda #<.leaderboardname
        sta ZP0
        lda #>.leaderboardname
        sta ZP1
        lda #<_leaderboard
        sta ZP2
        lda #>_leaderboard
        sta ZP3
        lda #0
        sta ZP4
        jsr LoadFile            ;call filehandler
        bcc +
        jsr SaveLeaderboard     ;if load fails, create a new file
+       rts

SaveLeaderboard
        lda #<.leaderboardname
        sta ZP0
        lda #>.leaderboardname
        sta ZP1
        lda #<_leaderboard
        sta ZP2
        lda #>_leaderboard
        sta ZP3
        lda #<.leaderboard_end
        sta ZP4
        lda #>.leaderboard_end
        sta ZP5
        jsr SaveFile            ;call filehandler
        rts  

ResetLeaderboard                ;copy default leaderboard to leaderboard
        lda #<_default_leaderboard
        sta ZP0
        lda #>_default_leaderboard
        sta ZP1
        lda #<_leaderboard
        sta ZP2
        lda #>_leaderboard
        sta ZP3
        lda #.leaderboard_end-_leaderboard
        sta ZP4
        lda #0
        sta ZP5
        jsr CopyMem
        rts

CopyMem                 ;IN: ZP0, ZP1 = src. ZP2, ZP3 = dest. ZP4, ZP5 = number of bytes.      
-       lda (ZP0)
        sta (ZP2)
        +Inc16bit ZP0
        +Inc16bit ZP2
        +Dec16bit ZP4
        lda ZP4
        bne -
        lda ZP5
        bne -
        rts

.leaderboardname        !raw "X16-RALLYSPEEDWAY/LEADERBOARD.BIN",0

_leaderboard                                    ;data are read from file
_track_recordnames      !scr "-----     ",0
                        !scr "-----     ",0
                        !scr "-----     ",0
                        !scr "-----     ",0
                        !scr "-----     ",0

_track_records          !byte 0,0,0             ;track 1 - minutes, second, jiffies
                        !byte 0,0,0             ;track 2
                        !byte 0,0,0             ;track 3
                        !byte 0,0,0             ;track 4
                        !byte 0,0,0             ;track 5
.leaderboard_end

_default_leaderboard
                        !scr "JOHAN     ",0
                        !scr "-----     ",0
                        !scr "ALBIN     ",0
                        !scr "-----     ",0
                        !scr "VALTER    ",0
                        !fill 15,0