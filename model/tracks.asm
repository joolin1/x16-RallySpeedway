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
_tilecollisionstatus:   !byte TILE_TERRAIN      ;first tile definition is of type terrain
                        !byte TILE_ROAD         ;...
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_ROAD
                        !byte TILE_FINISH
                        !byte TILE_FINISH
                        !byte TILE_OBSTACLE

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
_blockroadstatus:       !byte BLOCK_TERRAIN             ;first block definition is of type terrain
                        !byte BLOCK_CURVE1              ;...
                        !byte BLOCK_CURVE2
                        !byte BLOCK_CURVE3
                        !byte BLOCK_CURVE4
                        !byte BLOCK_EW_ROAD
                        !byte BLOCK_NS_ROAD
                        !byte BLOCK_CROSSING
                        !byte BLOCK_EW_STARTFINISH
                        !byte BLOCK_NS_STARTFINISH

;Global infor about current track
_track		        !byte 1	        ;selected track - track one is preselected
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
.errorstartmissing      !scr "route must start with a start block.",0
.errorfinishmissing     !scr "route must end with a finish block.",0
.errorroutebroken       !scr "route is broken.",0

SetTrack:
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
        lda .track_startblocks,y
        sta _xstartblock
        lda .track_startblocks+1,y
        sta _ystartblock

        jsr .CalculateRoute
        rts

.CalculateRoute:                        ;calculate route data for current track.
                                        ;OUT: if error carry is set, ZP0-ZP1 points to error message, ZP2-ZP3 = row and col where error was found.
        stz .finishedflag
        stz .errorflag
        
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
        bra .ReturnError        ;error, route does not start with a block is of type start/finish

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
        lda .direction
        sta (ZP0)
        rts

;*** Tracks data ***********************************************************************************

_route:                 !fill 1024,0    ;calculated route (every entry corresponds to the block map and contains which direction the route continues)

;Definitions for all tracks

.track_names:
                        !scr "Track 1",0
                        !scr "Track 2",0
                        !scr "Track 3",0
                        !scr "Track 4",0
                        !scr "Track 5",0

.track_startblocks:
                        !byte 0,0
                        !byte 2,29
                        !byte 4,2
                        !byte 2,2
                        !byte 2,2

;Track definitions
.tracks:       
.track1:
        !byte 8,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,3,5,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,2,8,5,5,5,5,5,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,6,0,0,0,0,0,0,0,6,0,0,0,2,5,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,3,1,0,0,0,0,0,0,3,5,5,5,4,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 5,5,7,5,5,5,5,1,0,0,0,0,0,0,0,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
        !byte 0,0,6,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,6,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,3,5,5,5,5,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,4,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

.track2:
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,2,8,1,5,5,5,5,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,6,0,6,0,0,0,0,0,6,0,0,0,5,5,5,1,0,0,0,5,5,5,5,5,5,5,5,5,1,0,0
        !byte 0,3,5,4,5,5,5,5,5,4,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0
        !byte 0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,3,5,5,5,5,5,1,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,3,5,5,5,5,5,5,5,4,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,4,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

.track3:
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,2,8,1,5,5,5,5,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,6,0,6,0,0,0,0,0,6,0,0,0,5,5,5,1,0,0,0,5,5,5,5,5,5,5,5,5,1,0,0
        !byte 0,3,5,4,5,5,5,5,5,4,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,3,5,5,5,5,5,1,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,3,5,5,5,5,5,5,5,4,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,4,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

.track4:
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,2,8,1,5,5,5,5,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,6,0,6,0,0,0,0,0,6,0,0,0,5,5,5,1,0,0,0,5,5,5,5,5,5,5,5,5,1,0,0
        !byte 0,3,5,4,5,5,5,5,5,4,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,3,5,5,5,5,5,1,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,3,5,5,5,5,5,5,5,4,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,4,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

.track5:
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,2,8,1,5,5,5,5,5,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,6,0,6,0,0,0,0,0,6,0,0,0,5,5,5,1,0,0,0,5,5,5,5,5,5,5,5,5,1,0,0
        !byte 0,3,5,4,5,5,5,5,5,4,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,3,5,5,5,5,5,1,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,3,5,5,5,5,5,5,5,4,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,0,0
        !byte 0,0,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,4,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

_blocks:
        ;0 - grass
        !word 24, 0, 0, 0 ,0, 0, 0, 0
        !word  0, 0, 0, 0, 0, 0,24, 0
        !word  0, 0, 0, 0, 0, 0, 0, 0
        !word  0, 0, 0,24, 0, 0, 0, 0
        !word  0, 0, 0, 0, 0, 0, 0, 0
        !word 24, 0, 0, 0, 0, 0, 0, 0
        !word  0, 0, 0, 0, 0,24, 0, 0
        !word  0, 0, 0, 0, 0, 0, 0, 0

        ;1 - curve 0-90
        !word    4,   5,   6,   6,   7,   8,   0,   0
        !word    3,   1,   1,   1,   1,   9,  10,   0
        !word    1,   1,   1,   1,   1,   1,  11,  12
        !word    1,   1,   1,   1,   1,   1,   1,  13
        !word    1,   1,   1,   1,   1,   1,   1,  14
        !word    1,   1,   1,   1,   1,   1,   1,  14
        !word   19,   1,   1,   1,   1,   1,   1,  15
        !word   20,  21,   1,   1,   1,   1,  17,  16

        ;2 - curve 90-180
        !word    0,   0,$408,$407,   6,   6,$405,$404
        !word    0,$40a,$409,   1,   1,   1,   1,$403
        !word $40c,$40b,   1,   1,   1,   1,   1,   1
        !word $40d,   1,   1,   1,   1,   1,   1,   1
        !word $40e,   1,   1,   1,   1,   1,   1,   1
        !word $40e,   1,   1,   1,   1,   1,   1,   1
        !word $40f,   1,   1,   1,   1,   1,   1,$413  
        !word $410,$411,   1,   1,   1,   1,$415,$414

        ;3 - curve 180-270
        !word $c10,$c11,   1,   1,   1,   1,$c15,$c14
        !word $c0f,   1,   1,   1,   1,   1,   1,$c13  
        !word $c0e,   1,   1,   1,   1,   1,   1,   1
        !word $c0e,   1,   1,   1,   1,   1,   1,   1
        !word $c0d,   1,   1,   1,   1,   1,   1,   1
        !word $c0c,$c0b,   1,   1,   1,   1,   1,   1
        !word    0,$c0a,$c09,   1,   1,   1,   1,$c03
        !word    0,   0,$c08,$c07,$806,$806,$c05,$c04

        ;4 - curve 270-360
        !word $814,$815,   1,   1,   1,   1,$811,$810
        !word $813,   1,   1,   1,   1,   1,   1,$80f
        !word    1,   1,   1,   1,   1,   1,   1,  14
        !word    1,   1,   1,   1,   1,   1,   1,  14
        !word    1,   1,   1,   1,   1,   1,   1,$80d
        !word    1,   1,   1,   1,   1,   1,$80b,$80c
        !word $803,   1,   1,   1,   1,$809,$80a,   0
        !word $804,$805,$806,$806,$807,$808,   0,   0

        ;5 - horizontal road
        !word    0,   0,   0,   0,   0,   0,   0,   0
        !word    2,   2,   2,   2,   2,   2,   2,   2
        !word    1,   1,   1,   1,   1,   1,   1,   1
        !word    1,   1,   1,   1,   1,   1,   1,   1
        !word    1,   1,   1,   1,   1,   1,   1,   1
        !word    1,   1,   1,   1,   1,   1,   1,   1
        !word $802,$802,$802,$802,$802,$802,$802,$802
        !word    0,   0,   0,   0,   0,   0,   0,   0

        ;6 - vertical road
        !word    0,$412,   1,   1,   1,   1,  18,   0
        !word    0,$412,   1,   1,   1,   1,  18,   0
        !word    0,$412,   1,   1,   1,   1,  18,   0
        !word    0,$412,   1,   1,   1,   1,  18,   0
        !word    0,$412,   1,   1,   1,   1,  18,   0
        !word    0,$412,   1,   1,   1,   1,  18,   0
        !word    0,$412,   1,   1,   1,   1,  18,   0
        !word    0,$412,   1,   1,   1,   1,  18,   0

        ;7 - crossing
        !word $814,$815,   1,   1,   1,   1,$c15,$c14
        !word $813,   1,   1,   1,   1,   1,   1,$c13
        !word    1,   1,   1,   1,   1,   1,   1,   1
        !word    1,   1,   1,   1,   1,   1,   1,   1
        !word    1,   1,   1,   1,   1,   1,   1,   1
        !word    1,   1,   1,   1,   1,   1,   1,   1
        !word   19,   1,   1,   1,   1,   1,   1,$413
        !word   20,  21,   1,   1,   1,   1,$415,$414

        ;8 - start/finish
        !word    0,   0,   0,   0,   0,   0,   0,   0
        !word    2,   2,$016,   2,   2,   2,   2,   2
        !word    1,   1,  23,   1,   1,   1,   1,   1
        !word    1,   1,  23,   1,   1,   1,   1,   1
        !word    1,   1,  23,   1,   1,   1,   1,   1
        !word    1,   1,  23,   1,   1,   1,   1,   1
        !word $802,$802,$816,$802,$802,$802,$802,$802
        !word    0,   0,   0,   0,   0,   0,   0,   0