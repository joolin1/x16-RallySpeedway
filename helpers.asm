;*** helpers.asm - global helper routines **********************************************************

GetStringLength:                ;IN: .X .Y = address of string terminated with 0. OUT: .A = string length
        stx ZP0
        sty ZP1
        phy
        ldy #0
-       lda (ZP0),y
        beq +
        iny
        bra -
+       tya       
        ply
        rts

PrintString:                    ;IN: .X .Y = address of string terminated with 0.
        stx ZP0
        sty ZP1
        ldy #0
-       lda (ZP0),y
        bne +
        rts
+       jsr BSOUT
        iny
        bra -
        rts

PrintStringArrayElement:        ;IN: .X .Y = address of string array. .A = string index
        stx ZP0
        sty ZP1
        tax
-       lda (ZP0)
        beq +
        jsr .incAddr
        bra -
+       jsr .incAddr
        dex
        bne -
        ldx ZP0
        ldy ZP1
        jsr PrintString
        rts

.incAddr:
        inc ZP0
        bne +
        inc ZP1
+       rts

PrintDigit:                     ;IN: .A = digit to print
        tay
        lda .number,y
        jsr BSOUT
        rts

.number     !scr "0123456789"

VPoke:  ;routine for poking VRAM that takes inline parameters
        ; example: jsr VPoke           
        ;          !word SPR_CTRL
        ;          !byte 1

        ;First modify the return address in stack to point after the inline arguments (+ 3 bytes)

        clc
        tsx                 ;transfer stack pointer to x, points to next free byte in stack    
        lda $0101,x         ;load low byte of return address
        sta ZP0             ;and store it in zeropage location unused by KERNAL/BASIC
        adc #3              ;add 3 bytes (a word arg and a byte arg) to return address
        sta $0101,x         ;and store the low byte of the new return address
            
        lda $0102,x         ;load high byte of return address
        sta ZP1             ;and store it in next zeropage location unused by KERNAL/BASIC
        adc #0              ;add 0 to which includes the carry flag to complete a full 16-bit add
        sta $0102,x         ;and store the high byte of the return address
            
        ;Then use the original return address to access inline arguments
        
        ldy #1              ;The return address is actually pointing to the return address-1
        lda (ZP0),y         ;therefore access the first argument with an offset of 1 and so on
        sta VERA_ADDR_LO
            
        ldy #2
        lda (ZP0),y
        sta VERA_ADDR_MID

        lda #$f         
        sta VERA_ADDR_HI

        stz VERA_CTRL
        ldy #3
        lda (ZP0),y
        sta VERA_DATA0
        rts