;*** mathlib.asm - functions, macros and precalculated tables ***************************************************************

;*** 16 bit arithmetics ****************************************************************************

!macro Inc16bit .addr {
        inc .addr
        bne +
        inc .addr+1
+
}

!macro Dec16bit .addr {
        dec .addr
        bpl +
        dec .addr+1
+
}

!macro Countdown16bit .addr {           ;decrease to 0, then stop
        lda .addr
        bne +
        lda .addr+1
        bne +
        bra ++
+       dec .addr
        bpl ++
        dec .addr+1
        bpl ++
        stz .addr                       ;if reached $ffff set $0000
        stz .addr+1
++
}

!macro Add16 .addr1_lo, .addr2_lo {     ;OUT: .X = result lo, .Y = result hi
        lda .addr1_lo
        clc
        adc .addr2_lo
        tax
        lda .addr1_hi
        adc .addr2_hi
        tay        
}

!macro Add16 .addr_lo, .value_lo, .value_hi {     ;OUT: result in .addr_lo and .addr_lo+1
        lda .addr_lo
        clc
        adc #.value_lo
        sta .addr_lo
        lda .addr_lo+1
        adc  #.value_hi
        sta .addr_lo+1        
}

!macro Sub16 .addr1_lo, .addr2_lo {     ;OUT: .X = result lo, .Y = result hi
        lda .addr1_lo
        sec
        sbc .addr2_lo
        tax
        lda .addr1_lo+1
        sbc .addr2_lo+1
        tay        
}

!macro Sub16 .addr_lo, .value_lo, .value_hi {     ;OUT: result in .addr_lo and .addr_lo+1
        lda .addr_lo
        sec
        sbc .value_lo
        sta .addr_lo
        lda .addr_lo+1
        sbc .value_hi
        sta .addr_lo+1
}

!macro Abs16 .address_lo {
        lda .address_lo+1       
        bit #$80
        beq +
        eor #$ff                        ;if negative convert from minus to plus
        sta .address_lo+1                        
        lda .address_lo
        eor #$ff
        inc
        sta .address_lo
+
}

!macro Cmp16 .addr1_lo, .addr2_lo {             ;OUT: carry clear if num 1 < num 2
        lda .addr1_lo+1         ;start with comparing high bytes
        cmp .addr2_lo+1
        bcc +                   ;if number 1 hi <  number 2 hi then number 1 < number 2
        bne +                   ;if number 1 hi <> number 2 hi then number 2 > number 2
        lda .addr1_lo           ;if number 1 hi =  number 2 hi then compare low bytes to see which number is lowest
        cmp .addr2_lo
+
}

!macro Cmp16 .addr_lo, .value_lo, .value_hi {   ;OUT: carry clear if num 1 < num 2
        lda .addr_lo+1
        cmp #.value_hi
        bcc +
        bne +
        lda .addr_lo
        cmp #.value_lo
+
}

!macro IsEqual16 .addr_lo {
        lda .addr_lo
        bne +
        lda .addr_lo+1
+
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

;*** Decimal arithmetics ***************************************************************************

!macro ConvertBinToDec .binaddr, .decaddr_lo {
        sed	
	lda #0
	sta .decaddr_lo
	sta .decaddr_lo+1
        lda .binaddr
        sta ZP0
	ldx #8  		;the number of source bits
-	asl ZP0 	        ;shift out one bit
	lda .decaddr_lo	        ;and add into result
	adc .decaddr_lo
	sta .decaddr_lo
	lda .decaddr_lo+1       ;propagating any carry
	adc .decaddr_lo+1
	sta .decaddr_lo+1
	dex		        ;and repeat for next bit
	bne -
        cld
}

!macro Convert16BinToDec .binaddr_lo, .decaddr_lo {
        sed	
        lda #0
	sta .decaddr_lo
	sta .decaddr_lo+1
        sta .decaddr_lo+2
        lda .binaddr_lo
        sta ZP0
        lda .binaddr_lo+1
        sta ZP1
        ldx #16                 ;the number of source bits    
-	asl ZP0                 ;shift out one bit
	rol ZP1
	lda .decaddr_lo	        ;and add into result
	adc .decaddr_lo
	sta .decaddr_lo
	lda .decaddr_lo+1	;propagating any carry
	adc .decaddr_lo+1
	sta .decaddr_lo+1
	lda .decaddr_lo+2       ;...thru whole result
	adc .decaddr_lo+2
	sta .decaddr_lo+2
	dex		        ;and repeat for next bit
	bne -
	cld
}

!macro Countdown16bitDec .addr {        ;decrease decimal number to 0, then stop
        sed
        lda .addr
        bne +
        lda .addr+1
        bne +
        bra ++
+       lda .addr
        sec
        sbc #1
        sta .addr
        lda .addr+1
        sbc #0
        sta .addr+1        
++      cld
}

;*** Random Numbers ********************************************************************************

SetRandomSeed:
        jsr SetRandom1Seed
        jsr SetRandom2Seed
        rts

SetRandomSeedZero:
        stz .randomnumber
        stz .rndseed1
        stz .rndseed2
        rts

SetRandom1Seed:
        jsr RDTIM
        sta .randomnumber
        rts

SetRandom2Seed:
        jsr RDTIM
        sta .rndseed1
        stx .rndseed2
        rts

GetRandomNumber1:
	lda .randomnumber       ;OUT: .A = pseudo random number between 0 and $ff
	beq +
	asl
	beq ++		        ;if the input was $80, skip the EOR
	bcc ++
+   eor #$1d
++  sta .randomnumber
	rts

.randomnumber	!byte 0

GetRandomNumber2:		;Super Mario World version
	lda .rndseed1           ;;OUT: .A = pseudo random number between 0 and $ff
	asl
	asl
	sec
	adc .rndseed1
	sta .rndseed1
	asl .rndseed2
	lda #$20
	bit .rndseed2
	bcc +
	beq +++
	bne ++
+	bne +++
++	inc .rndseed2
+++	lda .rndseed2
	eor .rndseed1
	rts
.rndseed1	!byte $12
.rndseed2	!byte $7b

;*** Various ***************************************************************************************

!macro IncAndWrap32 .pos {
        lda .pos
        inc
        and #31
        sta .pos
}

!macro DecAndWrap32 .pos {
        lda .pos
        dec
        and #31
        sta .pos
}

!macro DecToZero .val {
        dec .val
        bpl +
        stz .val
+        
}

;*** Time comparison. Time is represented by three bytes (minutes, seconds, jiffies) ***************

AreTimesEqual:                  ;IN: ZP0-ZP2 = time 1, ZP3-ZP5 = time 2.
        lda ZP0
        cmp ZP3
        beq +
        rts
+       lda ZP1
        cmp ZP4
        beq +
        rts
+       lda ZP2
        cmp ZP5
        rts

IsTimeLessThanNullableTime:     ;IN: ZP0-ZP2 = time 1, ZP3-ZP5 = time 2. OUT: .C clear if time 2 < time 1 or time 1 = NULL
        lda ZP0
        bne IsTimeLess
        lda ZP1
        bne IsTimeLess
        lda ZP2
        bne IsTimeLess
        clc                     ;if time is = 0 then time is NULL and the other time is considered less.        
        rts

IsTimeLess:             ;IN: ZP0-ZP2 = time 1, ZP3-ZP5 = time 2. OUT: .C clear if time 2 < time 1
        lda ZP3
        cmp ZP0         ;time 1 < time 2 (minutes)?
        beq +           ;continue with seconds if equal
        rts             ;(carry will be clear if less)
+       lda ZP4
        cmp ZP1         ;time 1 < time 2 (seconds)?
        beq +           ;continue with jiffies if equal
        rts             ;(carry will be clear if less)
+       lda ZP5
        cmp ZP2
        rts             ;(carry will be clear if less, otherwise set)

;*** Precalculated Tables **************************************************************************

;Table for sine and cosine values. Fractions in fixed point numbers used are represented by 4 bits. For example sin(45) = 0.707 * 16 = 11.3.
;NOTE! words are used because of the negative values!
_anglesin       !word   0,  2,  3,  5,  6,  8,  9, 10, 11, 12, 13, 14, 15, 15, 16, 16 ;sin angles 0-
_anglecos       !word  16, 16, 16, 15, 15, 14, 13, 12, 11, 10,  9,  8,  6,  5,  3,  2 ;sin angles 90-
                !word   0, -2, -3, -5, -6, -8, -9,-10,-11,-12,-13,-14,-15,-15,-16,-16 ;sin angles 180-
                !word -16,-16,-16,-15,-15,-14,-13,-12,-11,-10, -9, -8, -6, -5, -3, -2 ;sin angles 270-
                !word   0,  2,  3,  5,  6,  8,  9, 10, 11, 12, 13, 14, 15, 15, 16, 16 ;cos angles 270-

;Table for atan2 - which angle a vector (x,y) have relative to origo. Just for the first quadrant. 
_atantable:     ;rows x = 0 to 31, columns y = 0 to 31
        !byte	-1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte	64,32,19,13,10, 8, 7, 6, 5, 5, 4, 4, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1
        !byte	64,45,32,24,19,16,13,11,10, 9, 8, 7, 7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3
        !byte	64,51,40,32,26,22,19,16,15,13,12,11,10, 9, 9, 8, 8, 7, 7, 6, 6, 6, 6, 5, 5, 5, 5, 5, 4, 4, 4, 4
        !byte	64,54,45,38,32,27,24,21,19,17,16,14,13,12,11,11,10, 9, 9, 8, 8, 8, 7, 7, 7, 6, 6, 6, 6, 6, 5, 5
        !byte	64,56,48,42,37,32,28,25,23,21,19,17,16,15,14,13,12,12,11,10,10,10, 9, 9, 8, 8, 8, 7, 7, 7, 7, 7
        !byte	64,57,51,45,40,36,32,29,26,24,22,20,19,18,16,16,15,14,13,12,12,11,11,10,10,10, 9, 9, 9, 8, 8, 8
        !byte	64,58,53,48,43,39,35,32,29,27,25,23,22,20,19,18,17,16,15,14,14,13,13,12,12,11,11,10,10,10, 9, 9
        !byte	64,59,54,49,45,41,38,35,32,30,27,26,24,22,21,20,19,18,17,16,16,15,14,14,13,13,12,12,11,11,11,10
        !byte	64,59,55,51,47,43,40,37,34,32,30,28,26,25,23,22,21,20,19,18,17,16,16,15,15,14,14,13,13,12,12,12
        !byte	64,60,56,52,48,45,42,39,37,34,32,30,28,27,25,24,23,22,21,20,19,18,17,17,16,16,15,14,14,14,13,13
        !byte	64,60,57,53,50,47,44,41,38,36,34,32,30,29,27,26,25,23,22,21,20,20,19,18,18,17,16,16,15,15,14,14
        !byte	64,61,57,54,51,48,45,42,40,38,36,34,32,30,29,27,26,25,24,23,22,21,20,20,19,18,18,17,16,16,16,15
        !byte	64,61,58,55,52,49,46,44,42,39,37,35,34,32,30,29,28,27,25,24,23,23,22,21,20,20,19,18,18,17,17,16
        !byte	64,61,58,55,53,50,48,45,43,41,39,37,35,34,32,31,29,28,27,26,25,24,23,22,22,21,20,19,19,18,18,17
        !byte	64,61,59,56,53,51,48,46,44,42,40,38,37,35,33,32,31,29,28,27,26,25,24,24,23,22,21,21,20,19,19,18
        !byte	64,61,59,56,54,52,49,47,45,43,41,39,38,36,35,33,32,31,30,29,27,27,26,25,24,23,22,22,21,21,20,19
        !byte	64,62,59,57,55,52,50,48,46,44,42,41,39,37,36,35,33,32,31,30,29,28,27,26,25,24,24,23,22,22,21,20
        !byte	64,62,59,57,55,53,51,49,47,45,43,42,40,39,37,36,34,33,32,31,30,29,28,27,26,25,25,24,23,23,22,21
        !byte	64,62,60,58,56,54,52,50,48,46,44,43,41,40,38,37,35,34,33,32,31,30,29,28,27,26,26,25,24,24,23,22
        !byte	64,62,60,58,56,54,52,50,48,47,45,44,42,41,39,38,37,35,34,33,32,31,30,29,28,27,27,26,25,25,24,23
        !byte	64,62,60,58,56,54,53,51,49,48,46,44,43,41,40,39,37,36,35,34,33,32,31,30,29,28,28,27,26,26,25,24
        !byte	64,62,60,58,57,55,53,51,50,48,47,45,44,42,41,40,38,37,36,35,34,33,32,31,30,29,29,28,27,26,26,25
        !byte	64,62,60,59,57,55,54,52,50,49,47,46,44,43,42,40,39,38,37,36,35,34,33,32,31,30,30,29,28,27,27,26
        !byte	64,62,61,59,57,56,54,52,51,49,48,46,45,44,42,41,40,39,38,37,36,35,34,33,32,31,30,30,29,28,27,27
        !byte	64,62,61,59,58,56,54,53,51,50,48,47,46,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,30,29,28,28
        !byte	64,62,61,59,58,56,55,53,52,50,49,48,46,45,44,43,42,40,39,38,37,36,35,34,34,33,32,31,30,30,29,28
        !byte	64,62,61,59,58,57,55,54,52,51,50,48,47,46,45,43,42,41,40,39,38,37,36,35,34,34,33,32,31,31,30,29
        !byte	64,63,61,60,58,57,55,54,53,51,50,49,48,46,45,44,43,42,41,40,39,38,37,36,35,34,34,33,32,31,31,30
        !byte	64,63,61,60,58,57,56,54,53,52,50,49,48,47,46,45,43,42,41,40,39,38,38,37,36,35,34,33,33,32,31,31
        !byte	64,63,61,60,59,57,56,55,53,52,51,50,48,47,46,45,44,43,42,41,40,39,38,37,37,36,35,34,33,33,32,31
        !byte	64,63,61,60,59,57,56,55,54,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,36,35,34,33,33,32