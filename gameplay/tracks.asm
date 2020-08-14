;*** tracks.asm - definitions of tracks ************************************************************

;Directions (360 deg = 256)
.EAST   = 0
.NORTH  = 64
.WEST   = 128
.SOUTH  = 192

;Tile status used for collision detection
TILE_ROAD = 0                   ;car is on road
TILE_TERRAIN = 1                ;car is off road, slow down speed
TILE_OBSTACLE = 2               ;car has collided and will explode
TILE_FINISH = 3                 ;car has finished race 

;Table for character of tiles
_tilecollisionstatus:   !byte TILE_TERRAIN
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
                        !byte TILE_ROAD
                        !byte TILE_FINISH
                        !byte TILE_FINISH
                        !byte TILE_OBSTACLE

;Type of blocks
.TERRAIN         = 0
.EW_ROAD         = 1    ;road from east to west
.NS_ROAD         = 2    ;road from north to south
.CURVE1          = 3    ;curve   0- 90 deg
.CURVE2          = 4    ;curve  90-180 deg
.CURVE3          = 5    ;curve 180-270 deg
.CURVE4          = 6    ;curve 270-360 deg
.CROSSING        = 7
.EW_START_FINISH = 8    ;road from east to west which marks start and finish
.NS_START_FINISH = 9    ;road from north to south which marks start and finish

;Mapping between block definitions and types
_blockroadstatus:       !byte .TERRAIN          ;block definition 0 = terrain
                        !byte .CURVE1           ;block definition 1 = a curve 0-90 deg
                        !byte .CURVE2           ;...
                        !byte .CURVE3
                        !byte .CURVE4
                        !byte .EW_ROAD
                        !byte .NS_ROAD
                        !byte .CROSSING
                        !byte .EW_START_FINISH

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

!macro IncBlockPos .pos {
        lda .pos
        inc
        and #31
        sta .pos
}

!macro DecBlockPos .pos {
        lda .pos
        dec
        and #31
        sta .pos
}

.CalculateRoute:                        ;calculate route data for current track

        stz .routefinishedflag
        
        ;save address of route in pointers to be able to use macro for getting element in array
        lda #<_route
        sta _route_lo
        lda #>_route
        sta _route_hi

        ;clear route
        lda #<_route
        sta ZP0
        lda #>_route
        sta ZP1
        lda #-1
        ldy #32
--      ldx #32
-       sta (ZP0)
        +Inc16bit ZP0
        dex 
        bne -
        dey
        bne --

        ;set start position
        lda _xstartblock
        sta .col
        lda _ystartblock
        sta .row 

        ;check start position
        +GetElementInArray _blockmap_lo, 5, .row, .col  ;OUT: ZP0-ZP1 = address of block
        lda (ZP0)
        !byte $ff
        tay
        lda _blockroadstatus,y
        cmp #.EW_START_FINISH
        bne +
        lda #.EAST
        sta .angle              ;start by going east
        sta _startdirection
        jsr .AddToRoute
        +IncBlockPos .col
        bra ++
+       cmp #.NS_START_FINISH   
        bne +
        lda #.NORTH
        sta .angle              ;start by going north
        sta _startdirection
        jsr .AddToRoute
        +DecBlockPos .row
        bra ++
+       sec                     ;flag error, start block is not of type start/goal
        rts

        ;track route through block map

++      ;get type of current block
-       +GetElementInArray _blockmap_lo, 5, .row, .col   ;OUT: ZP0-ZP1 = address of block
        lda (ZP0)
        tay
        lda _blockroadstatus,y
        cmp #.TERRAIN
        bne +
        sec                             ;road continues directly into the terrain, set carry to flag error
        rts

        ;add block to the route after checking that road is not broken between last block and current block 
+       ldx .angle
        cpx #.EAST
        bne +
        jsr .RouteComingFromWest
        bra ++
+       cpx #.NORTH
        bne +
        jsr .RouteComingFromSouth
        bra ++
+       cpx #.WEST
        bne +
        jsr .RouteComingFromEast
        bra ++                       
+       jsr .RouteComingFromNorth       ;direction south (the only alternative left)

++      bcc +
        rts                             ;route is broken (eg an east-west road is followed by a north-south road)
+       lda .routefinishedflag
        beq -                           ;continue route tracking with next block
        clc                             ;route tracking finished, no errors found
        !byte $ff
        rts

.RouteComingFromWest:       
        cmp #.CURVE1
        bne +     
        lda #.SOUTH
        sta .angle
        jsr .AddToRoute
        +IncBlockPos .row
        clc
        rts
+       cmp #.CURVE4
        bne +
        lda #.NORTH
        sta .angle
        jsr .AddToRoute
        +DecBlockPos .row
        clc
        rts
+       cmp #.EW_ROAD
        bne +
        lda #.EAST
        sta .angle
        jsr .AddToRoute
        +IncBlockPos .col
        clc
        rts
+       cmp #.CROSSING
        bne +
        lda #.EAST
        sta .angle
        jsr .AddToRoute
        +IncBlockPos .col
        clc
        rts
+       cmp #.EW_START_FINISH
        bne +
        lda #.EAST
        sta .angle
        jsr .AddToRoute
        lda #1
        sta .routefinishedflag
        clc
        rts
+       sec                     ;route is broken
        rts         

.RouteComingFromSouth:
        cmp #.CURVE1
        bne +     
        lda #.WEST
        sta .angle
        jsr .AddToRoute
        +DecBlockPos .col
        clc
        rts
+       cmp #.CURVE2
        bne +
        lda #.EAST
        sta .angle
        jsr .AddToRoute
        +IncBlockPos .col
        clc
        rts
+       cmp #.NS_ROAD
        bne +
        lda #.NORTH
        sta .angle
        jsr .AddToRoute
        +DecBlockPos .row
        clc
        rts
+       cmp #.CROSSING
        bne +
        lda #.NORTH
        sta .angle
        jsr .AddToRoute
        +DecBlockPos .row
        clc
        rts
+       cmp #.NS_START_FINISH
        bne +
        lda #.NORTH
        sta .angle
        jsr .AddToRoute
        lda #1
        sta .routefinishedflag
        clc
        rts
+       sec                     ;route is broken
        rts         

.RouteComingFromEast:
        cmp #.CURVE2
        bne +     
        lda #.SOUTH
        sta .angle
        jsr .AddToRoute
        +IncBlockPos .row
        clc
        rts
+       cmp #.CURVE3
        bne +
        lda #.NORTH
        sta .angle
        jsr .AddToRoute
        +DecBlockPos .row
        clc
        rts
+       cmp #.EW_ROAD
        bne +
        lda #.WEST
        sta .angle
        jsr .AddToRoute
        +DecBlockPos .col
        clc
        rts
+       cmp #.CROSSING
        bne +
        lda #.WEST
        sta .angle
        jsr .AddToRoute
        +DecBlockPos .col
        clc
        rts
+       cmp #.EW_START_FINISH
        bne +
        lda #.WEST
        sta .angle
        jsr .AddToRoute
        lda #1
        sta .routefinishedflag
        clc
        rts
+       sec                     ;route is broken
        rts         

.RouteComingFromNorth:
        cmp #.CURVE3
        bne +     
        lda #.EAST
        sta .angle
        jsr .AddToRoute
        +IncBlockPos .col
        clc
        rts
+       cmp #.CURVE4
        bne +
        lda #.WEST
        sta .angle
        jsr .AddToRoute
        +DecBlockPos .col
        clc
        rts
+       cmp #.NS_ROAD
        bne +
        lda #.SOUTH
        sta .angle
        jsr .AddToRoute
        +IncBlockPos .row
        clc
        rts
+       cmp #.CROSSING
        bne +
        lda #.SOUTH
        sta .angle
        jsr .AddToRoute
        +IncBlockPos .row
        clc
        rts
+       cmp #.NS_START_FINISH
        bne +
        lda #.SOUTH
        sta .angle
        jsr .AddToRoute
        lda #1
        sta .routefinishedflag
        clc
        rts
+       sec                     ;route is broken
        rts  

.AddToRoute:
        +GetElementInArray _route_lo, 5, .row, .col
        lda .angle
        sta (ZP0)
        rts

.row                    !byte 0
.col                    !byte 0
.angle                  !byte 0
.routefinishedflag      !byte 0

;Current track info
_track		        !byte 1	        ;selected track - track one is preselected
_xstartblock            !byte 0         ;start position
_ystartblock            !byte 0
_startdirection         !byte 0         ;start direction
_blockmap_lo            !byte 0         ;address of track map
_blockmap_hi            !byte 0
_route_lo               !byte 0         ;address of route map
_route_hi               !byte 0
_route                  !fill 1024,0    ;calculated route (every entry corresponds to the block map and contains which direction the route continues)

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

        ;8 - start/goal
        !word    0,   0,   0,   0,   0,   0,   0,   0
        !word    2,   2,$016,   2,   2,   2,   2,   2
        !word    1,   1,  23,   1,   1,   1,   1,   1
        !word    1,   1,  23,   1,   1,   1,   1,   1
        !word    1,   1,  23,   1,   1,   1,   1,   1
        !word    1,   1,  23,   1,   1,   1,   1,   1
        !word $802,$802,$816,$802,$802,$802,$802,$802
        !word    0,   0,   0,   0,   0,   0,   0,   0