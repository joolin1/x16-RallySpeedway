;*** textlib.asm *******************************************************************************

S_CURSOR                = 0     ;char for cursor
TEXTBOX_COLORS          = $b1   ;bg and fg (= text) color
CURSOR_REVERSE_COLOR    = $bb   ;color for invisible cursor
MAX_STRING_INPUT        = 20
CURSOR_DELAY            = 30

;*** Global variables for cursor position (not used by KERNAL) *************************************

_row    !byte 0                 ;current row
_col    !byte 0                 ;current column
_color  !byte 0                 ;text color (bg color = upper nybble, fg color = lower nybble)

!macro SetPrintParams .row, .col {
        lda #.row
        sta _row
        lda #.col
        sta _col
} 

!macro SetPrintParams .row, .col, .color {
        lda #.row
        sta _row
        lda #.col
        sta _col
        lda #.color
        sta _color
} 

;*** String handling *******************************************************************************

GetStringLength:                ;IN: ZP0, ZP1 = address of string terminated with 0. OUT: .A = string length
        phy
        ldy #0
-       lda (ZP0),y
        beq +
        iny
        bra -
+       tya       
        ply
        rts

SetString:                      ;IN: ZP0, ZP1 = address of source string. ZP2, ZP3 = address of destination string
        jsr GetStringLength
        sta ZP4
        stz ZP5
        jsr CopyMem
        rts

GetStringInArray:               ;IN: ZP0, ZP1 = address of string array. .A = string index. OUT: ZP0, ZP1 = address of string
        tax
        beq ++                  ;if index = 0 then just return address of first string
-       lda (ZP0)               ;loop until we find 0 (= termination of string)
        beq +
        +Inc16bit ZP0
        bra -
+       +Inc16bit ZP0           ;set address to first character of next string
        dex                     
        bne -                   ;if not this string, find then next
++      rts  

;TruncateString:                 ;NOT FINISHED - IN: ZP0, ZP1 = address of string. .A = new string length
;         sta ZP2
;         ldy #-1
; -       iny
;         cpy ZP2                 ;reached new string length?
;         beq +                   
;         lda (ZP0),y             ;if not load next char
;         cmp #0                  ;check if char is termination char (= 0)
;         bne -
;         lda #KEY_SPACE          ;if it is, overwrite with a space
;         sta (ZP0),y
;         bra -                   
; +       stz (ZP0),Y             ;terminate string at new length      
;         rts

;*** Text input ************************************************************************************

InitInputString:
        cmp #MAX_STRING_INPUT
        bmi +
        lda #MAX_STRING_INPUT
+       sta .inputlength
        lda _col
        sta .inputstart
        stz .inputpos
        jsr .InitTextBox
        jsr .InitString
-       jsr GETIN                   ;empty keyboard buffer before starting to receive input
        cmp #0
        bne -
        rts

.InitTextBox:
        lda #TEXTBOX_COLORS         ;initialize a "text box" by printing spaces with black bg and a cursor
        sta _color
        lda #S_CURSOR
        jsr VPrintChar
        ldx .inputlength
        dex
-       phx
        lda #A_SPACE
        jsr VPrintChar
        plx
        dex
        bne -       
        lda _col                    ;move column back to where string input starts
        sec
        sbc .inputlength
        sta _col
        clc
        rts

.InitString:
        lda #A_SPACE
        ldy .inputlength
-       sta .inputstring-1,y
        dey
        bne -
        rts

InputString:                    ;IN: .A = string length. OUT: ZP0, ZP1 = address of string, carry flag set = input finished
        lda .inputpos
        jsr GETIN
        cmp #0
        bne +
        jsr .UpdateCursorColor  ;let cursor blink when textbox idle
        jsr .UpdateCursor
        clc
        rts

        ;check for allowed characters
+       cmp #A_BACKSPACE
        beq .InputBackspace
        cmp #A_RETURN
        beq .InputReturn
        cmp #A_SPACE
        beq .InputChar
        cmp #A_HYPHEN           ;-.0123456789?
        bcs +
        rts
+       cmp #A_NINE+1
        bcc .InputChar
        sec
        sbc #$40
        cmp #27                 ;a-z?
        bcc .InputChar
        clc
        rts

.InputChar:
        ldy .inputpos
        cpy .inputlength
        beq +
        sta .inputstring,y
        jsr VPrintChar
        inc .inputpos
        ldy .inputpos
        cpy .inputlength
        beq +
        lda #S_CURSOR
        jsr VPrintChar
        dec _col
+       clc
        rts

.InputBackspace:
        lda _col
        cmp .inputstart
        bne +                  
        clc                     ;nothing to do if already at leftmost position
        rts
+       dec _col
        lda #S_CURSOR           ;delete previous letter by replacing it with the cursor char
        jsr VPrintChar
        lda .inputpos
        cmp .inputlength
        beq +                   ;do not print a space if at rightmost position
        lda #A_SPACE
        jsr VPrintChar          ;delete previous cursor by replacing it with a space            
        dec _col
+       dec _col
        dec .inputpos
        ldy .inputpos
        lda #A_SPACE
        sta .inputstring,y
        clc
        rts

.InputReturn:
        ;ldy .inputpos
        ; lda #0                ;uncomment to terminate string, for now always return same length
        ; sta .inputstring,y    
        lda #<.inputstring
        sta ZP0
        lda #>.inputstring
        sta ZP1
        stz .inputpos
        stz .inputlength
        sec                     ;flag input finished
        rts

.UpdateCursorColor:
        dec .cursordelay
        lda .cursordelay
        beq +
        rts
+       lda #CURSOR_DELAY
        sta .cursordelay
        lda .cursorcolor
        cmp #TEXTBOX_COLORS
        bne +
        lda #CURSOR_REVERSE_COLOR
        sta .cursorcolor
        rts
+       lda #TEXTBOX_COLORS
        sta .cursorcolor
        rts

.UpdateCursor:
        lda .inputpos
        cmp .inputlength
        bne +
        rts
+       lda .cursorcolor
        sta _color
        lda #S_CURSOR
        jsr VPrintChar
        dec _col
        lda #TEXTBOX_COLORS
        sta _color
        rts

.cursorcolor    !byte TEXTBOX_COLORS
.cursordelay    !byte CURSOR_DELAY

.inputstart     !byte 0
.inputpos       !byte 0
.inputlength    !byte 0
.inputstring    !fill MAX_STRING_INPUT,0
                !byte 0

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
        +Inc16bit ZP0
        bra -
+       +Inc16bit ZP0
        dex
        bne -
        ldx ZP0
        ldy ZP1
++      jsr KPrintString
        rts

KPrintNumber:                   ;IN .A = number to print (max 99!)
        cmp #10
        bcc KPrintDigit
        asl
        tay
        lda .digitstable,y
        jsr BSOUT
        lda .digitstable+1,y
        jsr BSOUT
        rts

KPrintDigit:                     ;IN: .A = digit to print
        tay
        lda .digittable,y
        jsr BSOUT
        rts

;*** Print to VERA directly ************************************************************************

VPrintLineBreak:                ;IN: .A = screen code for character
        stz VERA_ADDR_L
        ldy _row
        sty VERA_ADDR_M
        ldy #$10
        sty VERA_ADDR_H      
        ldy _color
        ldx #40       
-       sta VERA_DATA0
        sty VERA_DATA0
        dex
        bne -
        inc _row
        rts

VPrintString:                    ;IN: ZP0, ZP1 = address of string terminated with 0. OUT: ZP0, ZP1 = address of string termination + 1 (to make printing of a string array easier)
        lda _col
        asl
        sta VERA_ADDR_L
        lda _row
        sta VERA_ADDR_M
        lda #$10
        sta VERA_ADDR_H      
        ldy _color
-       lda (ZP0)
        beq +    
        sta VERA_DATA0
        sty VERA_DATA0
        +Inc16bit ZP0
        bra -
+       inc _row                ;increase row and
        +Inc16bit ZP0           ;increase pointer possibly to a string that follows directly after
        rts

VPrintStringInArray:            ;IN: ZP0, ZP1 = address of string array. .A = string index. OUT: ZP0, ZP1 = address of string
        jsr GetStringInArray
        jsr VPrintString
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

!macro VPrintDecimalDigit {     ;IN: .A = digit to print
        clc
        adc #48                 ;48 = screen code for "0"
        jsr VPrintChar
}

VPrintLargeDecimalNumber:       ;Print 3 digit decimal number with leading zero(s) (000-999). IN: ZP0, ZP1 = number in decimal mode to print
        lda ZP1
        and #15
        +VPrintDecimalDigit
+       lda ZP0                 ;(will continue with next subroutine and then return)

VPrintDecimalNumber:            ;Print 2 digit decimal number with leading zero (0-99). IN: .A = number in decimal mode to print
        pha
        lsr
        lsr
        lsr
        lsr
        +VPrintDecimalDigit
        pla
        and #15
        +VPrintDecimalDigit
        rts

VPrintNumber:                   ;IN: .A = number to print
        ldx #$ff
        sec 
-       inx
        sbc #100
        bcs -
        adc #100
        jsr +

        ldx #$ff
        sec
--      inx
        sbc #10
        bcs --
        adc #10
        jsr +

        tax
+       pha
        txa
        clc
        adc #$30
        jsr VPrintChar
        pla
        rts

VPrintHexNumber:                ;IN: .A = number to print
        pha
        lsr
        lsr
        lsr
        lsr
        tay
        lda .hexdigits,y
        jsr VPrintChar
        pla
        and #15
        tay
        lda .hexdigits,y
        jsr VPrintChar
        rts

!macro VPrintHex16Number .addr {
        lda .addr+1
        jsr VPrintHexNumber
        lda .addr
        jsr VPrintHexNumber
}

.hexdigits      !scr "0123456789abcdef"

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

VPrintSeconds:                  ;IN: .A = seconds
        asl
        tay
        lda .digitstable,y
        jsr VPrintChar
        lda .digitstable+1,y
        jsr VPrintChar
        lda #<.secondtime
        sta ZP0
        lda #>.secondtime
        sta ZP1
        jsr VPrintString
        rts
        
.secondtime     !scr ":00",0

VPrintTime:                     ;IN: ZP0 = minutes, ZP1 = seconds, ZP2 = jiffies
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

        lda #S_COLON
        sta VERA_DATA0
        stx VERA_DATA0

        lda ZP1
        jsr .VPrintSeconds

        lda #S_COLON
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
        lda .digitstable,y
        sta VERA_DATA0
        stx VERA_DATA0
        lda .digitstable+1,y
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
.digittable     !scr "0123456789"
.digitstable    !scr "00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899"
.jiffiestable   !scr "000000000000101010101010202020202020303030303030404040404040505050505050606060606060707070707070808080808080909090909090"

;*** Conversion ************************************************************************************

Petscii2Screen:                 ;IN: .A = petscii code. OUT: .A = screen code
        cmp #$20		;if A<32 then...
	bcc .dRev
	cmp #$60		;if A<96 then...
	bcc .d1
	cmp #$80		;if A<128 then...
	bcc .d2
	cmp #$a0		;if A<160 then...
	bcc .d3
	cmp #$c0		;if A<192 then...
	bcc .d4
	cmp #$ff		;if A<255 then...
	bcc .dRev
	lda #$7e		;A=255, then A=126
	rts
.d1:	and #$3f		;if A=32..95 then strip bits 6 and 7
	rts     		
.d2:	and #$5f		;if A=96..127 then strip bits 5 and 7
	rts
.d3:	ora #$40		;if A=128..159, then set bit 6
	rts
.d4:    eor #$c0		;if A=160..191 then flip bits 6 and 7
	rts
.dRev:	eor #$80		;flip bit 7 (reverse on when off and vice versa)
        rts