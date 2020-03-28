;*** Debug.asm - Temporary subroutines used for debugging, not part of the actual game *************

DebugSetLine:
    stz .cursorX
    sta .cursorY
    rts

.cursorX    !byte 0
.cursorY    !byte 0

DebugPrintLine:
    jsr DebugPrintNumber
    inc .cursorY
    lda .cursorY
    cmp #30
    bne +
    stz .cursorY    
+   stz .cursorX
    rts

DebugPrintNumber:
    ldx #$ff
    sec 
-   inx
    sbc #100
    bcs -
    adc #100
    jsr +

    ldx #$ff
    sec
--  inx
    sbc #10
    bcs --
    adc #10
    jsr +

    tax
+   pha
    txa
    clc
    adc #$30
    jsr DebugPrint
    pla
    rts

DebugPrint:
    ldx .cursorX
    stx VERA_ADDR_LO
    ldx .cursorY
    stx VERA_ADDR_MID
    ldx #0
    stx VERA_ADDR_HI
    sta VERA_DATA0
    inc .cursorX
    inc .cursorX
    rts

DebugBusyLoop:
    !byte $ff
--- ldx #255
--  ldy #80
-   dey
    bne -
    dex
    bne --
    rts
