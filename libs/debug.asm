;*** debug.asm - routines used for debugging and optimizing code ***********************************

ChangeDebugColor:
        jsr VPoke               ;TEMP 
        !word PALETTE+10        ;TEMP
        !byte $00               ;TEMP
        jsr VPoke               ;TEMP
        !word PALETTE+11        ;TEMP
        !byte $00               ;TEMP
        rts

RestoreDebugColor:
        jsr VPoke               ;TEMP
        !word PALETTE+10        ;TEMP
        !byte $c5               ;TEMP
        jsr VPoke               ;TEMP
        !word PALETTE+11        ;TEMP
        !byte $00               ;TEMP
        rts