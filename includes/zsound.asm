; Zsound JMP Table API addresses.
; modify the value of ZSOUND_LOAD_ADDR whenever changes to the ZSOUND.BIN require
; a different load point in memory.

ZSOUND_LOAD_ADDR = $0810

; ============================================ZSM Music Player API========

;call this once before making any other calls to ZSM player.
Z_init_player       = ZSOUND_LOAD_ADDR

;music advance routine to be called once per frame
Z_playmusic         = Z_init_player+3       ; NOT IRQ SAFE: (Clobbers VERA/RAM Bank)
Z_playmusic_IRQ     = Z_playmusic+3         ; Safe to call during IRQ

; Playback control functions:
Z_startmusic        = Z_playmusic_IRQ+3     ; A=bank XY=ADDRESS of ZSM in memory
Z_stopmusic         = Z_startmusic+3        ; No args.
Z_set_music_speed   = Z_stopmusic+3         ; XY = tick rate (hz) of music
Z_set_loop          = Z_set_music_speed+3   ; A=number of loops to play (0=infinite)
Z_force_loop        = Z_set_loop+3          ; A=number of loops to play (0=infinite)
Z_disable_loop      = Z_force_loop+3        ; no args.
Z_set_callback      = Z_disable_loop+3      ; XY=address for callback handler
Z_clear_callback    = Z_set_callback+3      ; no args
Z_get_music_speed   = Z_clear_callback+3    ; no args (returns in XY)

;ZCM Digital Audio API
Z_init_pcm          = Z_get_music_speed+3
Z_start_digi        = Z_init_pcm+3
Z_play_pcm          = Z_start_digi+3
Z_stop_pcm          = Z_play_pcm+3
Z_set_pcm_volume    = Z_stop_pcm+3

; ;*** ZSound definitions

; ;ZSound uses zeropage $22 -$2D

; !addr ZSOUND_ADDR   = $9766        ;ZSound is located at end of fixed RAM        

; ;ZSOUND jump table
; !addr Z_init_player	= $9766
; !addr Z_playmusic	= $9769
; !addr Z_playmusic_IRQ	= $976c
; !addr Z_startmusic	= $976f
; !addr Z_stopmusic	= $9772
; !addr Z_set_music_speed	= $9775
; !addr Z_set_loop	= $9778
; !addr Z_force_loop	= $977b
; !addr Z_disable_loop	= $977e
; !addr Z_set_callback	= $9781
; !addr Z_clear_callback	= $9784
; !addr Z_get_music_speed	= $9787
; !addr Z_init_pcm	= $978a
; !addr Z_start_digi	= $978d
; !addr Z_play_pcm	= $9790
; !addr Z_stop_pcm	= $9793
; !addr Z_set_pcm_volume  = $9796