;*** veralib.asm ****************************************************************

!macro VPoke .addr, .data {                     ;.addr = address to change value of
        ldx #<.addr                             ;.data = absolute value (memory address which holds the value to set)
        stx VERA_ADDR_L
        ldx #>.addr
        stx VERA_ADDR_M
        ldx #$01
        stx VERA_ADDR_H
        lda .data
        sta VERA_DATA0
}

!macro VPokeI .addr, .data {                    ;.addr = address to change value of
        ldx #<.addr                             ;.data = immediate value to set 
        stx VERA_ADDR_L
        ldx #>.addr
        stx VERA_ADDR_M
        ldx #$01
        stx VERA_ADDR_H
        lda #.data
        sta VERA_DATA0
}

!macro VPoke .addr {                            ;.addr = address to change value of
        ldx #<.addr                             ;.A = value to set
        stx VERA_ADDR_L
        ldx #>.addr
        stx VERA_ADDR_M
        ldx #$01
        stx VERA_ADDR_H
        sta VERA_DATA0
}

!macro VPokeSprites .addr, .count {             ;.addr = address of first sprite
        ldx #<.addr                             ;.count = number of continous sprites to set data to
        stx VERA_ADDR_L                         ;.A = value to set
        ldx #>.addr
        stx VERA_ADDR_M
        ldx #$41
        stx VERA_ADDR_H
        ldx #.count
-       sta VERA_DATA0
        dex
        bne -
}

!macro VPokeSpritesI .addr, .count, .data {     ;.addr = address of first sprite
        ldx #<.addr                             ;.count = number of continoues sprites to set data to
        stx VERA_ADDR_L                         ;.data = immediate value to set
        ldx #>.addr
        stx VERA_ADDR_M
        ldx #$41
        stx VERA_ADDR_H 
        ldx #.count
        lda #.data
-       sta VERA_DATA0
        dex
        bne -
}

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

