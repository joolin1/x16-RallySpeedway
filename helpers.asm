;*** helpers.asm - global helper routines **********************************************************

;*** I/O *******************************************************************************************



;*** String handling *******************************************************************************

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

;*** Print using kernal **************************************************************************** 

KPrintString:                    ;IN: .X .Y = address of string terminated with 0.
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

KPrintStringArrayElement:        ;IN: .X .Y = address of string array. .A = string index
        stx ZP0
        sty ZP1
        tax
        beq ++
-       lda (ZP0)
        beq +
        jsr .incAddr
        bra -
+       jsr .incAddr
        dex
        bne -
        ldx ZP0
        ldy ZP1
++      jsr KPrintString
        rts

.incAddr:
        inc ZP0
        bne +
        inc ZP1
+       rts

KPrintDigit:                     ;IN: .A = digit to print
        tay
        lda .number,y
        jsr BSOUT
        rts

.number     !scr "0123456789"

;*** Print to VERA directly ************************************************************************

_row    !byte 0                 ;current row
_col    !byte 0                 ;current column
_color  !byte 0                 ;text color (bg color = upper nybble, fg color = lower nybble)

VPrintString:                    ;IN: ZP0, ZP1 = address of string terminated with 0.
-       lda (ZP0)
        inc ZP0
        bne +
        inc ZP1
+       cmp #0
        beq +
        jsr VPrintChar
        bra -
+       inc _row
        rts

VPrintStringArrayElement:       ;IN: ZP0, ZP1 = address of string array. .A = string index
        tax
        beq ++                  ;if index = 0 then print directly
-       lda (ZP0)               ;loop until we find 0 (= termination of string)
        beq +
        +Inc16bit ZP0
        bra -
+       +Inc16bit ZP0           ;set address to first character of next string
        dex                     
        bne -                   ;if not this string, find then next
++      jsr VPrintString
        rts

VPrintChar:                     ;IN: .A = screen code of character
        tax
        lda _col
        asl
        sta VERA_ADDR_L
        lda _row
        sta VERA_ADDR_M
        lda #$10
        sta VERA_ADDR_H      
        stx VERA_DATA0
        lda _color
        sta VERA_DATA0
        inc _col
        rts

VPrintDecimalNumber:            ;IN: .A = number to print in decimal mode
        pha
        lsr
        lsr
        lsr
        lsr
        beq +
        jsr VPrintDecimalDigit
+       pla
        and #15
        jsr VPrintDecimalDigit
        rts

VPrintDecimalDigit:             ;IN: .A = digit to print
        clc
        adc #48
        jsr VPrintChar
        rts

VPrintNullableTime:
        lda ZP0
        bne VPrintTime
        lda ZP1
        bne VPrintTime
        lda ZP2
        bne VPrintTime
        lda #<.nulltime
        sta ZP0
        lda #>.nulltime
        sta ZP1
        jsr VPrintString
        rts

.nulltime       !scr "--:--:--",0

VPrintTime:                     ;ZP0 = minutes, ZP1 = seconds, ZP2 = jiffies
        lda _col
        asl
        sta VERA_ADDR_L         ;set start column      
        lda _row
        sta VERA_ADDR_M         ;set row
        lda #$10
        sta VERA_ADDR_H
        ldx _color

        lda ZP0
        jsr .VPrintMinutes

        lda #COLON
        sta VERA_DATA0
        stx VERA_DATA0

        lda ZP1
        jsr .VPrintSeconds

        lda #COLON
        sta VERA_DATA0
        stx VERA_DATA0

        lda ZP2
        jsr .VPrintJiffies
        inc _row
        rts

.VPrintMinutes:
.VPrintSeconds:
        asl
        tay
        lda .secondstable,y
        sta VERA_DATA0
        stx VERA_DATA0
        lda .secondstable+1,y
        sta VERA_DATA0
        stx VERA_DATA0
        rts

.VPrintJiffies:
        asl
        tay
        lda .jiffiestable,y
        sta VERA_DATA0
        stx VERA_DATA0
        lda .jiffiestable+1,y
        sta VERA_DATA0
        stx VERA_DATA0
        rts

;tables for showing seconds and minutes, jiffies is converted to tenths of a second
.secondstable   !scr "000102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556575859"
.jiffiestable   !scr "000000000000101010101010202020202020303030303030404040404040505050505050606060606060707070707070808080808080909090909090"

;***************************************************************************************************

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