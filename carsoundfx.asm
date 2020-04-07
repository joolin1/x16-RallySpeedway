;*** soundfx.asm ***********************************************************************************

.StartEngineSound:
        lda #63                         ;set volume
        ora #3<<6                       ;set pan to both left and right
        +VPoke  .PSG_V0_PAN_VOL       
        +VPokeI .PSG_V0_WF_PW,5         ;set pulse length (waveform = 0)          
        +VPokeI .PSG_V0_FREQ_L,74       ;start with low frequency representing an idling car
        +VPokeI .PSG_V0_FREQ_H,0
        rts

.UpdateEngineSound:
        asl
        asl
        clc
        adc #74                         ;frequency = speed*4 + 74
        +VPoke .PSG_V0_FREQ_L

        inc .wavelengthdelay
        lda .wavelengthdelay
        and #8
        beq +
        +VPokeI .PSG_V0_WF_PW,5
        rts
+       +VPokeI .PSG_V0_WF_PW,15        
        rts

.StopEngineSound:
        +VPokeI .PSG_V0_PAN_VOL,0
        rts

.wavelengthdelay    !byte 0   

.StartSkiddingSound:
        lda #63                         ;set volume
        ora #3<<6                       ;set pan to both left and right
        +VPoke  .PSG_V1_PAN_VOL       
        +VPokeI .PSG_V1_WF_PW,15        ;set pulse length (waveform = 0)          
        +VPokeI .PSG_V1_FREQ_L,74       ;set a high frequency representing a skidding car
        +VPokeI .PSG_V1_FREQ_H,50
        rts

.StopSkiddingSound:
        +VPokeI .PSG_V1_PAN_VOL,0
        rts

.StopCarSound:
        +VPokeI .PSG_V0_PAN_VOL,0        
        +VPokeI .PSG_V1_PAN_VOL,0
        rts

.StartExplosionSound
        stz .explosiontimer
        lda #63                 ;set max volume
        ora #3<<6               ;set pan to both left and right
        +VPoke .PSG_V0_PAN_VOL
        lda #32                 ;set pulse length
        ora #3<<6               ;set waveform noise
        +VPoke  .PSG_V0_WF_PW
        +VPokeI .PSG_V0_FREQ_L,74
        +VPokeI .PSG_V0_FREQ_H,64
        rts

.PlayExplosionSound
        lda .explosiontimer
        cmp #60                 ;sound lasts 1 second
        beq +
        +VPokeI .PSG_V0_FREQ_L,74
        +VPokeI .PSG_V0_FREQ_H,64
        inc .explosiontimer
        rts

+       +VPokeI .PSG_V0_PAN_VOL,0
        rts

.explosiontimer          !byte 0
        