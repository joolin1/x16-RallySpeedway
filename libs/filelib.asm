;*** filelib.asm ***********************************************************************************

LOAD_TO_RAM = 0
LOAD_TO_VRAM_BANK0 = 2

LoadFile:                       ;IN: ZP0, ZP1 = filename, ZP2, ZP3 = load address, ZP4 = 0 = load, 1 = verify, 2 = VRAM bank 0, 3 = VRAM bank 1...
        jsr GetStringLength     ;will return length of filename in .A
        ldx ZP0
        ldy ZP1
        jsr SETNAM
        lda #$02
        ldx #$08                ;device
        ldy #$00  
        jsr SETLFS
        ldx ZP2                 ;load address  
        ldy ZP3  
        lda ZP4                 ;load details
        jsr LOAD
        rts

SaveFile:                       ;IN: ZP0, ZP1 = filename, ZP2, ZP3 = save address, ZP4, ZP5 = end address+1
        jsr GetStringLength     ;will return length of filename in .A
        ldx ZP0
        ldy ZP1
        jsr SETNAM
        lda #$02
        ldx #$08                ;device
        ldy #$00  
        jsr SETLFS
        lda #ZP2                ;zero page register holding start address
        ldx ZP4                 ;end address+1  
        ldy ZP5                   
        jsr SAVE
        rts

PrintIOErrorMessage:                    ;IN: .A = error number, ZP0, ZP1 = filename
        pha
        ldx ZP0
        ldy ZP1
        phx
        phy
        ldx #<.message1
        ldy #>.message1
        jsr KPrintString                ;print "failed to load"          
        ply
        plx
        jsr KPrintString                ;print filename
        ldx #<.message2
        ldy #>.message2
        jsr KPrintString                ;print "i/o error"
        pla
        pha
        jsr KPrintDigit                 ;print error number
        pla
        ldx #<.errorarray
        ldy #>.errorarray
        jsr KPrintStringArrayElement    ;print error message
        rts 

;Error messages
.message1       !scr 13,"FAILED TO LOAD ",0
.message2       !scr 13,"I/O ERROR #",0
.errorarray     !scr 0
                !scr ": TOO MANY FILES",0
                !scr ": FILE OPEN",0
                !scr ": FILE NOT OPEN",0
                !scr ": FILE NOT FOUND",0
                !scr ": DEVICE NOT PRESENT",0
                !scr ": NOT INPUT FILE",0
                !scr ": NOT OUTPUT FILE",0
                !scr ": MISSING FILENAME",0
                !scr ": ILLEGAL DEVICE NUMBER",0