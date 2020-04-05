;*** globals.asm ***********************************************************************************

_gamestatus     !byte   0       
_noofplayers	!byte   2	;number of players
_track		    !byte   1	;selected track
_xstartblock    !byte   2   ;race start position
_ystartblock    !byte   2
_startdirection !byte   0   ;race start direction

_debug          !byte   0   ;DEBUG - flag for breaking into debugger

;tables for which sprite (0-4) represents the current angle and how it is flipped (0 = no flip, 1 = horizontal flip, 2 vertical flip, 3 = flipped both ways)
_anglespritetable       !byte   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15
                        !byte  16,15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1                       
                        !byte   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15
                        !byte  16,15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1
_anglefliptable         !byte   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                        !byte   0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
                        !byte   1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
                        !byte   3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2

;table for sine and cosine values. Fractions in fixed point numbers used are represented by 4 bits. For example sin(45) = 0.707 * 16 = 11.3.
;NOTE! words are used because of the negative values!
_anglesin       !word   0,  2,  3,  5,  6,  8,  9, 10, 11, 12, 13, 14, 15, 15, 16, 16 ;sin angles 0-
_anglecos       !word  16, 16, 16, 15, 15, 14, 13, 12, 11, 10,  9,  8,  6,  5,  3,  2 ;sin angles 90-
                !word   0, -2, -3, -5, -6, -8, -9,-10,-11,-12,-13,-14,-15,-15,-16,-16 ;sin angles 180-
                !word -16,-16,-16,-15,-15,-14,-13,-12,-11,-10, -9, -8, -6, -5, -3, -2 ;sin angles 270-
                !word   0,  2,  3,  5,  6,  8,  9, 10, 11, 12, 13, 14, 15, 15, 16, 16 ;cos angles 270-