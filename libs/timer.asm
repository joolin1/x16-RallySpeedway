;*** timer.asm **************************************************************************************
 
.TimeReset:
        stz .minutes
        stz .seconds
        stz .jiffies
        rts

.TimeAddSeconds:                ;IN: .A = number of seconds to add
        cmp #0                  
        bne +
        rts
+       tax
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

.TimeAddMinute:
        inc .minutes
        lda .minutes
        cmp #60
        beq +
        rts
+       stz .minutes            ;59:59:59 is max time
        rts

.TimeSubSeconds:                ;.A = number of seconds to subtract
        cmp #0
        bne +
        rts
+       tax
-       jsr .TimeSubSecond
        dex
        bne -
        rts

.TimeSubSecond:
        dec .seconds
        bmi +
        rts
+       lda #59
        sta .seconds
        dec .minutes
        bmi +
        rts
+       lda #59
        sta .minutes
        rts

.minutes    !byte 0             ;timer data
.seconds    !byte 0
.jiffies    !byte 0