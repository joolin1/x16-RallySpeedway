;*** Macros.asm ****************************************************************

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

!macro Inc16bit .addr {
        inc .addr
        bne +
        inc .addr+1
+       rts
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
