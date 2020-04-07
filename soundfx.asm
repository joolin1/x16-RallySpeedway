StartClashSound:     
        stz .clashtimer
        lda #63                     ;set max volume
        ora #3<<6                   ;set pan to both left and right
        +VPoke PSG_V4_PAN_VOL
        lda #32                     ;set pulse length
        ora #0<<6                   ;set waveform
        +VPoke  PSG_V4_WF_PW
        +VPokeI PSG_V4_FREQ_L,30
        +VPokeI PSG_V4_FREQ_H,1
        rts

PlayClashSound
        lda .clashtimer
        cmp #10                     ;very short sound
        beq +
        +VPokeI PSG_V4_FREQ_L,30
        +VPokeI PSG_V4_FREQ_H,1
        inc .clashtimer
        rts

+       +VPokeI PSG_V4_PAN_VOL,0
        rts

.clashtimer:    !byte 0

StartOutrunSound:
        stz .outruncount
        stz .outruntimer
        lda #63                     ;set max volume
        ora #3<<6                   ;set pan to both left and right
        +VPoke PSG_V4_PAN_VOL
        lda #32                     ;set pulse length
        ora #0<<6                   ;set waveform
        +VPoke  PSG_V4_WF_PW
        +VPokeI PSG_V4_FREQ_L,0
        +VPokeI PSG_V4_FREQ_H,20
        rts

PlayOutrunSound:
-       lda .outruntimer
        cmp #10                     ;very short sound
        beq +
        +VPokeI PSG_V4_FREQ_L,0
        +VPokeI PSG_V4_FREQ_H,20
        inc .outruntimer
        rts

+       stz .outruntimer
        inc .outruncount
        lda .outruncount
        cmp #3                      ;play sound three times
        bne -
        +VPokeI PSG_V4_PAN_VOL,0
        rts        

.outruntimer    !byte 0
.outruncount    !byte 0