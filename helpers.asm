;*** helpers.asm - global helper routines **********************************************************

CopyMem:                ;IN: ZP0, ZP1 = src. ZP2, ZP3 = dest. ZP4, ZP5 = number of bytes.      
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
        sta VERA_ADDR_L
            
        ldy #2
        lda (ZP0),y
        sta VERA_ADDR_M

        lda #1         
        sta VERA_ADDR_H

        stz VERA_CTRL
        ldy #3
        lda (ZP0),y
        sta VERA_DATA0
        rts