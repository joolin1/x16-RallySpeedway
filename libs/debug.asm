;*** debuglib.asm - routines used for debugging and optimizing code ********************************

_debug                  !byte 0         ;DEBUG - flag for breaking into debugger

!macro CondBreakpoint {
        lda _debug
        beq +
        !byte $db
+
}

!macro ActivateCondBreakpoint {
        lda #1
        sta _debug
}

ChangeDebugColor:
        jsr VPoke                
        !word TRACKS_PALETTE + 4 * 2        
        !byte $00               
        jsr VPoke               
        !word TRACKS_PALETTE + 4 * 2 + 1        
        !byte $00               
        rts

RestoreDebugColor:
        jsr VPoke               
        !word TRACKS_PALETTE + 4 * 2        
        !byte $c5               
        jsr VPoke               
        !word TRACKS_PALETTE + 4 * 2 + 1        
        !byte $00               
        rts
