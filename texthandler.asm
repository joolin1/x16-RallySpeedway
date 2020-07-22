;*** texthandler.asm *******************************************************************************

;*** Global variables for cursor position (not used by KERNAL) *************************************

_row    !byte 0                 ;current row
_col    !byte 0                 ;current column
_color  !byte 0                 ;text color (bg color = upper nybble, fg color = lower nybble)

KEY_CURSOR = 59
TEXTBOX_COLORS = $b1            ;bg and fg (= text) color
CURSOR_REVERSE_COLOR = $bb      ;color for invincible cursor
MAX_STRING_INPUT = 20
CURSOR_DELAY = 30

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
        rts

.InitTextBox:
        lda #TEXTBOX_COLORS         ;initialize a "text box" by printing spaces with black bg and a cursor
        sta _color
        lda #KEY_CURSOR
        jsr VPrintChar
        ldx .inputlength
        dex
-       phx
        lda #KEY_SPACE
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
        lda #KEY_SPACE
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
+       cmp #KEY_BACKSPACE      ;backspace?
        beq .InputBackspace
        cmp #KEY_RETURN         ;return?
        beq .InputReturn
        cmp #KEY_SPACE          ;space?
        beq .InputChar
        cmp #KEY_HYPHEN         ;-.0123456789?
        bcs +
        rts
+       cmp #KEY_NINE+1
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
        lda #KEY_CURSOR
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
        lda #KEY_CURSOR         ;delete previous letter by replacing it with the cursor char
        jsr VPrintChar
        lda .inputpos
        cmp .inputlength
        beq +                   ;do not print a space if at rightmost position
        lda #KEY_SPACE
        jsr VPrintChar          ;delete previous cursor by replacing it with a space            
        dec _col
+       dec _col
        dec .inputpos
        ldy .inputpos
        lda #KEY_SPACE
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
        lda #KEY_CURSOR
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

VPrintString:                    ;IN: ZP0, ZP1 = address of string terminated with 0. OUT: ZP0, ZP1 = address of string termination + 1 (to make printing of a string array easier)
-       lda (ZP0)
        beq +
        jsr VPrintChar
        +Inc16bit ZP0
        bra -
+       inc _row
        +Inc16bit ZP0
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