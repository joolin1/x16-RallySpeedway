;*** ZSound definitions

;ZSound uses zeropage $22 -$2D

!addr ZSOUND_ADDR   = $9766        ;ZSound is located at end of fixed RAM
!addr ZSM_ADDR      = $A000        ;ZSM music is in banked RAM            

;ZSOUND jump table
!addr Z_init_player	= $9766
!addr Z_playmusic	= $9769
!addr Z_playmusic_IRQ	= $976c
!addr Z_startmusic	= $976f
!addr Z_stopmusic	= $9772
!addr Z_set_music_speed	= $9775
!addr Z_set_loop	= $9778
!addr Z_force_loop	= $977b
!addr Z_disable_loop	= $977e
!addr Z_set_callback	= $9781
!addr Z_clear_callback	= $9784
!addr Z_get_music_speed	= $9787
!addr Z_init_pcm	= $978a
!addr Z_start_digi	= $978d
!addr Z_play_pcm	= $9790
!addr Z_stop_pcm	= $9793
!addr Z_set_pcm_volume  = $9796