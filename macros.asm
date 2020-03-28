;*** Macros.asm ****************************************************************

!macro VPoke .addr, .data {                     ;.addr = address to change value of
        ldx #<.addr                             ;.data = absolute value (memory address which holds the value to set)
        stx VERA_ADDR_LO
        ldx #>.addr
        stx VERA_ADDR_MID
        ldx #$f
        stx VERA_ADDR_HI
        lda .data
        sta VERA_DATA0
}

!macro VPokeI .addr, .data {                    ;.addr = address to change value of
        ldx #<.addr                             ;.data = immediate value to set 
        stx VERA_ADDR_LO
        ldx #>.addr
        stx VERA_ADDR_MID
        ldx #$f
        stx VERA_ADDR_HI
        lda #.data
        sta VERA_DATA0
}

!macro VPoke .addr {                            ;.addr = address to change value of
        ldx #<.addr                             ;.A = value to set
        stx VERA_ADDR_LO
        ldx #>.addr
        stx VERA_ADDR_MID
        ldx #$f
        stx VERA_ADDR_HI
        sta VERA_DATA0
}

!macro VPokeSprites .addr, .count {             ;.addr = address of first sprite
        ldx #<.addr                             ;.count = number of continous sprites to set data to
        stx VERA_ADDR_LO                        ;.A = value to set
        ldx #>.addr
        stx VERA_ADDR_MID
        ldx #$4f
        stx VERA_ADDR_HI
        ldx #.count
-       sta VERA_DATA0
        dex
        bne -
}

!macro VPokeSpritesI .addr, .count, .data {     ;.addr = address of first sprite
        ldx #<.addr                             ;.count = number of continoues sprites to set data to
        stx VERA_ADDR_LO                        ;.data = immediate value to set
        ldx #>.addr
        stx VERA_ADDR_MID
        ldx #$4f
        stx VERA_ADDR_HI
        ldx #.count
        lda #.data
-       sta VERA_DATA0
        dex
        bne -
}

!macro DivideBy16 .address_lo {
        lsr .address_lo+1
        ror .address_lo
        lsr .address_lo+1
        ror .address_lo
        lsr .address_lo+1
        ror .address_lo
        lsr .address_lo+1
        ror .address_lo
}

!macro DivideBy32 .address_lo {
        lsr .address_lo+1
        ror .address_lo
        lsr .address_lo+1
        ror .address_lo
        lsr .address_lo+1
        ror .address_lo
        lsr .address_lo+1
        ror .address_lo
        lsr .address_lo+1
        ror .address_lo
}

!macro MultiplyBy16 .address_lo {
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1    
}

!macro MultiplyBy32 .address_lo {
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1    
        asl .address_lo
        rol .address_lo+1    
}

!macro MultiplyBy128 .address_lo {
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1
        asl .address_lo
        rol .address_lo+1  
}
