;*** tracks.asm - definitions of tracks ************************************************************

;Directions (360 deg = 256), used for route information
ROUTE_EAST      = 0     ;route continues to the east
ROUTE_NORTH     = 64    ;...
ROUTE_WEST      = 128
ROUTE_SOUTH     = 192
ROUTE_OFFROAD   = -1    ;not part of route

;Type of tiles (used for collision detection)
TILE_ROAD = 0                   ;car is on road
TILE_TERRAIN = 1                ;car is off road, slow down speed
TILE_OBSTACLE = 2               ;car has collided and will explode
TILE_FINISH = 3                 ;car has finished race 

;Table for character of tiles
_tilecollisionstatus:   !byte 0,0,0,0,1,0,0,1   ;road tiles come first. those with mostly grass will be considered as terrain
                        !byte 1,0,0,1,0,1,0,3
                        !byte 3,3,3,3,3,0,1,0   
                        !byte 0,1,0,0,0,0,0,0
                        !byte 2,2,2,1,1,1,1,1   ;the rest are obstacles (trees, houses, walls etc) and terrain
                        !byte 1,1,2,2,2,2,2,2
                        !byte 2,2,2,2,2,2,2,2
                        !byte 2,2,2,2,2,2,2,2
                        !byte 2,2,2,2,2,2,2,2
                        !byte 2,2,2,2,2,2,2,2

;Type of blocks
BLOCK_TERRAIN         = 0
BLOCK_EW_ROAD         = 1    ;road from east to west
BLOCK_NS_ROAD         = 2    ;road from north to south
BLOCK_CURVE1          = 3    ;curve   0- 90 deg
BLOCK_CURVE2          = 4    ;curve  90-180 deg
BLOCK_CURVE3          = 5    ;curve 180-270 deg
BLOCK_CURVE4          = 6    ;curve 270-360 deg
BLOCK_CROSSING        = 7
BLOCK_EW_STARTFINISH  = 8    ;road from east to west which marks start and finish
BLOCK_NS_STARTFINISH  = 9    ;road from north to south which marks start and finish

;Table for character of blocks
_blockroadstatus:
                        !byte  8,1,1,1,1,1,1,1,1,1,1,1,1,1              ;14 horizontal blocks
                        !byte  9,2,2,2,2,2,2,2,2,2,2,2,2,2              ;14 vertical blocks
                        !byte  1,2,3,4,5,6,1,1,1,1,2,2,2,2              ;14 narrow road blocks 
                        !byte  3,4,5,6,1,1,1,1,1,1,1,1,2,2              ;28 curve blocks
                        !byte  2,2,2,2,2,2,1,1,2,2,1,2,1,2
                        !byte  7,3,3,4,4,5,5,6,6,7,7,7                  ;12 crossings
                        !byte  1,1,2,2,1,1,2,2                          ; 8 t-junctions
                        !byte  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0      ;18 terrain blocks
                                                                        ;Total 108 blocks

;Global infor about current track
_track		        !byte 1	        ;selected track - track one is preselected (NOTE not zero-indexed!)
_xstartblock            !byte 0         ;start position
_ystartblock            !byte 0
_startdirection         !byte 0         ;start direction
_blockmap_lo            !byte 0         ;address of track map
_blockmap_hi            !byte 0
_route_lo               !byte 0         ;address of route map
_route_hi               !byte 0

;route variables
.row                    !byte 0
.col                    !byte 0
.direction              !byte 0
.finishedflag           !byte 0
.errorflag              !byte 0
.errormessage1          !scr "ERROR IN TRACK ",0
.errormessage2          !scr " ROW ",0
.errormessage3          !scr " COL ",0
.errorstartmissing      !scr ". ROUTE MUST START WITH A START BLOCK.",0
.errorfinishmissing     !scr ". ROUTE MUST END WITH A FINISH BLOCK.",0
.errorroutebroken       !scr ". ROUTE IS BROKEN.",0
.errorinfo              !scr " (ROWS AND COLS ARE ZERO-INDEXED.)",0
_routelength_lo:        !byte 0
_routelength_hi:        !byte 0
_route:                 !fill 1024,0    ;calculated route (every entry corresponds to the block map and contains which direction the route continues)

_trackdata         = $A000             ;locate tracks in 8 KB memory bank            
_tracknames        = _trackdata        ;5 track names * (17 characters + null) = 90
.track_startblocks = _trackdata + 90   ;5 zero-indexed start positions (row, col)
.tracks            = _trackdata + 100  ;5 tracks 32x32 blocks = 1024 bytes each

SetTrack:                       ;IN: _track = track number (1-5)
        ;set address for selected track
        lda #<.tracks           
        sta _blockmap_lo
        lda #>.tracks
        ldy _track
-       dey
        beq +
        clc
        adc #4                  ;add 4 to the higher byte = adding 1024 (32x32) to complete address
        bra -                   ;repeat to get offset for selected track
+       sta _blockmap_hi

        ;set start block for selected track
        lda _track
        dec
        asl
        tay
        lda .track_startblocks+1,y
        sta _xstartblock
        lda .track_startblocks,y
        sta _ystartblock

        jsr .CalculateRoute
        rts

VerifyTracks:                   ;Verify that all tracks have a coherent route
        lda _track
        sta .temptrack          ;save current track
        lda #1
-       pha
        sta _track
        jsr SetTrack
        bcc +
        pla
        jsr .PrintTrackError
        sec                     ;error occurred
        rts
+       pla
        inc
        cmp #6
        bne -
        lda .temptrack          ;restore current track
        sta _track
        clc                     ;no error
        rts

.temptrack      !byte 0

.PrintTrackError:               ;IN: .A = track, ZP0-ZP1 = error message, ZP2-ZP3 = row and col where error was found
        ldx ZP0                 
        phx                     ;push error message
        ldy ZP1
        phy
        ldx ZP3
        phx                     ;push col
        ldx ZP2                         
        phx                     ;push row
        pha                     ;push track number
        ldx #<.errormessage1
        ldy #>.errormessage1
        jsr KPrintString        ;print "error in track "

        pla
        jsr KPrintDigit         ;print number of track          

        ldx #<.errormessage2
        ldy #>.errormessage2
        jsr KPrintString        ;print " row "

        pla                     ;pull row
        jsr KPrintNumber        ;print row number

        ldx #<.errormessage3
        ldy #>.errormessage3
        jsr KPrintString        ;print " col "

        pla                     ;pull col
        jsr KPrintNumber        ;print col number

        ply                     ;pull error message
        plx
        jsr KPrintString        ;print error message

        ldx #<.errorinfo        ;print that rows and cols are zero-indexed
        ldy #>.errorinfo
        jsr KPrintString
        rts

.CalculateRoute:                        ;calculate route data for current track.
                                        ;OUT: if error carry is set, ZP0-ZP1 points to error message, ZP2-ZP3 = row and col where error was found.
        stz .finishedflag
        stz .errorflag
        stz _routelength_lo
        stz _routelength_hi
        
        ;1 - save address of route in pointers to be able to use macro for getting element in array
        lda #<_route
        sta _route_lo
        lda #>_route
        sta _route_hi

        ;2- clear route
        lda #<_route
        sta ZP0
        lda #>_route
        sta ZP1
        lda #ROUTE_OFFROAD
        ldy #32
--      ldx #32
-       sta (ZP0)
        +Inc16bit ZP0
        dex 
        bne -
        dey
        bne --

        ;3 - set and check start position
        lda _xstartblock
        sta .col
        lda _ystartblock
        sta .row 
        +GetElementInArray _blockmap_lo, 5, .row, .col  ;OUT: ZP0-ZP1 = address of block
        lda (ZP0)
        tay
        lda _blockroadstatus,y
        cmp #BLOCK_EW_STARTFINISH
        bne +
        lda #ROUTE_EAST
        sta .direction              ;start by going east
        sta _startdirection
        jsr .AddToRoute
        +IncAndWrap32 .col
        bra ++
+       cmp #BLOCK_NS_STARTFINISH   
        bne +
        lda #ROUTE_NORTH
        sta .direction              ;start by going north
        sta _startdirection
        jsr .AddToRoute
        +DecAndWrap32 .row
        bra ++
+       lda #<.errorstartmissing
        sta ZP0
        lda #>.errorstartmissing
        sta ZP1
        jmp .ReturnError        ;error, route does not start with a block is of type start/finish

        ;4 - track route through map

++      ;loop through every block in route
-       +GetElementInArray _blockmap_lo, 5, .row, .col   ;OUT: ZP0-ZP1 = address of block
        lda (ZP0)
        tay
        lda _blockroadstatus,y
        cmp #BLOCK_TERRAIN
        bne +
        lda #<.errorfinishmissing
        sta ZP0
        lda #>.errorfinishmissing
        sta ZP1
        bra .ReturnError        ;error, route does not end with a block of type start/finish
        rts

        ;add block to the route after checking that road is not broken between last block and current block 
+       ldx .direction
        cpx #ROUTE_EAST
        bne +
        jsr .RouteComingFromWest
        bra ++
+       cpx #ROUTE_NORTH
        bne +
        jsr .RouteComingFromSouth
        bra ++
+       cpx #ROUTE_WEST
        bne +
        jsr .RouteComingFromEast
        bra ++                       
+       jsr .RouteComingFromNorth       ;direction south (the only alternative left)

++      lda .errorflag
        beq +
        lda #<.errorroutebroken
        sta ZP0
        lda #>.errorroutebroken
        sta ZP1
        bra .ReturnError                ;route is broken (eg an east-west road is followed by a north-south road)
+       lda .finishedflag
        beq -                           ;continue route tracking with next block
        clc                             ;route tracking complete, no errors found!
        rts

.ReturnError:
        lda .row
        sta ZP2
        lda .col
        sta ZP3
        sec
        rts

.RouteComingFromWest:       
        cmp #BLOCK_CURVE1
        bne +
        lda #ROUTE_SOUTH        
        sta .direction
        jsr .AddToRoute
        +IncAndWrap32 .row
        rts
+       cmp #BLOCK_CURVE4
        bne +
        lda #ROUTE_NORTH
        sta .direction
        jsr .AddToRoute
        +DecAndWrap32 .row
        rts
+       cmp #BLOCK_EW_ROAD
        bne +
        lda #ROUTE_EAST
        sta .direction
        jsr .AddToRoute
        +IncAndWrap32 .col
        rts
+       cmp #BLOCK_CROSSING
        bne +
        lda #ROUTE_EAST
        sta .direction
        jsr .AddToRoute
        +IncAndWrap32 .col
        rts
+       cmp #BLOCK_EW_STARTFINISH
        bne +
        lda #ROUTE_EAST
        sta .direction
        jsr .AddToRoute
        lda #1
        sta .finishedflag
        rts
+       lda #1
        sta .errorflag          ;route is broken
        rts         

.RouteComingFromSouth:
        cmp #BLOCK_CURVE1
        bne +     
        lda #ROUTE_WEST
        sta .direction
        jsr .AddToRoute
        +DecAndWrap32 .col
        rts
+       cmp #BLOCK_CURVE2
        bne +
        lda #ROUTE_EAST
        sta .direction
        jsr .AddToRoute
        +IncAndWrap32 .col
        rts
+       cmp #BLOCK_NS_ROAD
        bne +
        lda #ROUTE_NORTH
        sta .direction
        jsr .AddToRoute
        +DecAndWrap32 .row
        rts
+       cmp #BLOCK_CROSSING
        bne +
        lda #ROUTE_NORTH
        sta .direction
        jsr .AddToRoute
        +DecAndWrap32 .row
        rts
+       cmp #BLOCK_NS_STARTFINISH
        bne +
        lda #ROUTE_NORTH
        sta .direction
        jsr .AddToRoute
        lda #1
        sta .finishedflag
        rts
+       lda #1
        sta .errorflag          ;route is broken
        rts         

.RouteComingFromEast:
        cmp #BLOCK_CURVE2
        bne +
        lda #ROUTE_SOUTH
        sta .direction
        jsr .AddToRoute
        +IncAndWrap32 .row
        rts
+       cmp #BLOCK_CURVE3
        bne +
        lda #ROUTE_NORTH
        sta .direction
        jsr .AddToRoute
        +DecAndWrap32 .row
        rts
+       cmp #BLOCK_EW_ROAD
        bne +
        lda #ROUTE_WEST
        sta .direction
        jsr .AddToRoute
        +DecAndWrap32 .col
        rts
+       cmp #BLOCK_CROSSING
        bne +
        lda #ROUTE_WEST
        sta .direction
        jsr .AddToRoute
        +DecAndWrap32 .col
        rts
+       cmp #BLOCK_EW_STARTFINISH
        bne +
        lda #ROUTE_WEST
        sta .direction
        jsr .AddToRoute
        lda #1
        sta .finishedflag
        rts
+       lda #1
        sta .errorflag          ;route is broken
        rts         

.RouteComingFromNorth:
        cmp #BLOCK_CURVE3
        bne +     
        lda #ROUTE_EAST
        sta .direction
        jsr .AddToRoute
        +IncAndWrap32 .col
        rts
+       cmp #BLOCK_CURVE4
        bne +
        lda #ROUTE_WEST
        sta .direction
        jsr .AddToRoute
        +DecAndWrap32 .col
        rts
+       cmp #BLOCK_NS_ROAD
        bne +
        lda #ROUTE_SOUTH
        sta .direction
        jsr .AddToRoute
        +IncAndWrap32 .row
        rts
+       cmp #BLOCK_CROSSING
        bne +
        lda #ROUTE_SOUTH
        sta .direction
        jsr .AddToRoute
        +IncAndWrap32 .row
        rts
+       cmp #BLOCK_NS_STARTFINISH
        bne +
        lda #ROUTE_SOUTH
        sta .direction
        jsr .AddToRoute
        lda #1
        sta .finishedflag
        rts
+       lda #1
        sta .errorflag          ;route is broken
        rts  

.AddToRoute:
        +GetElementInArray _route_lo, 5, .row, .col
        lda .direction                  ;add route direction to current block position
        sta (ZP0)
        +Inc16bit _routelength_lo       ;add 1 to route length
        rts

;*** block data ***********************************************************************************

_blocks:                               ;NOTE! Blocks of 128 bytes each will be loaded here!
                                       ;Make sure there is space!