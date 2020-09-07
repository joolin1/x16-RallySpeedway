;*** debuglib.asm - routines used for debugging and optimizing code ********************************

_debug                  !byte 0         ;DEBUG - flag for breaking into debugger

!macro CondBreakpoint {
        lda _debug
        beq +
        !byte $db
+
}

!macro SetCondBreakpoint {
        lda #1
        sta _debug
}

ChangeDebugColor:
        jsr VPoke                
        !word PALETTE+10        
        !byte $00               
        jsr VPoke               
        !word PALETTE+11        
        !byte $00               
        rts

RestoreDebugColor:
        jsr VPoke               
        !word PALETTE+10        
        !byte $c5               
        jsr VPoke               
        !word PALETTE+11        
        !byte $00               
        rts
