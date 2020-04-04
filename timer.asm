;*** timer.asm **************************************************************************************

COLON = 58      ;screen code for ":"    
color = ZP0 

.TimeReset:
        stz .minutes
        stz .seconds
        stz .jiffies
        rts

.TimeAddSeconds:
        tax                     ;.A = number of seconds to add
-       jsr .TimeAddSecond
        dex
        bne -
        rts

.TimeTick:
        inc .jiffies            ;interrupt is triggered once every 1/60 second. That is why we add exactly this.
        lda .jiffies
        cmp #60
        beq +
        rts

+       stz .jiffies

.TimeAddSecond:
        inc .seconds
        lda .seconds
        cmp #60
        beq +
        rts

+       stz .seconds
        inc .minutes
        lda .minutes
        cmp #60
        beq +
        rts

+       stz .minutes            ;59:59:59 is max time
        rts

.DisplayTime:                   ;.A = text color, .X = column, .Y = row
        sta color
        txa
        asl
        sta VERA_ADDR_L        ;set start column      
        sty VERA_ADDR_M       ;set row
        lda #$10
        sta VERA_ADDR_H
        ldx color

        lda .minutes
        jsr .PrintMinutes

        lda #COLON
        sta VERA_DATA0
        stx VERA_DATA0

        lda .seconds
        jsr .PrintSeconds

        lda #COLON
        sta VERA_DATA0
        stx VERA_DATA0

        lda .jiffies
        jsr .PrintJiffies
        rts

.PrintMinutes:
.PrintSeconds:
        asl
        tay
        lda .secondstable,y
        sta VERA_DATA0
        stx VERA_DATA0
        lda .secondstable+1,y
        sta VERA_DATA0
        stx VERA_DATA0
        rts

.PrintJiffies:
        asl
        tay
        lda .jiffiestable,y
        sta VERA_DATA0
        stx VERA_DATA0
        lda .jiffiestable+1,y
        sta VERA_DATA0
        stx VERA_DATA0
        rts

.minutes    !byte 0             ;timer data
.seconds    !byte 0
.jiffies    !byte 0

;tables for showing seconds and minutes, jiffies is converted to tenths of a second
.secondstable   !scr "000102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556575859"
.jiffiestable   !scr "000000000000101010101010202020202020303030303030404040404040505050505050606060606060707070707070808080808080909090909090"
