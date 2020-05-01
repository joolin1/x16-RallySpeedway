;*** constants.asm *********************************************************************************

;Memory layout for screen and graphic resources
!addr L1_MAP_ADDR       = $0000                     ;       8 Kb | Layer 1 - the original text layer is by default located at $0000 an in front of layer 0
                                                    ;            | 80 cols (each 256 bytes) x 60 rows = 256 x 60 = $3c00 bytes but we only use 30 rows and 256 x 30 = $1e00
!addr L0_MAP_ADDR       = $2000                     ;       8 Kb | Layer 0 - game graphics layer. Both used in tile mode and text mode

!addr TILE_ADDR         = $4000                     ;      16 Kb | 128 tiles (room for) (16 rows x  8 bytes/row) -> 128 x 16 x  8 = $4000 bytes (16K)
!addr CARS_ADDR         = $8000                     ;            | 17 car sprites       (32 rows x 16 bytes/row) ->  17 x 32 x 16 = $2200 bytes 
!addr EXPLOSION_ADDR    = CARS_ADDR + $2200         ;       8 Kb | 12 explosion sprites (32 rows x 16 bytes/row) ->  12 x 32 x 16 = $1800 bytes
!addr TEXT_ADDR         = EXPLOSION_ADDR + $1800    ;      10 Kb | 10 text sprites       (64 rows x 16 bytes/row) ->  10 x 64 x 16 = $2800 bytes
                                                    ;Total 50 Kb | (memory free from $e200)

!addr CAR_PALETTES      = PALETTE + $20
!addr YCAR_PALETTE      = PALETTE + $20
!addr BCAR_PALETTE      = PALETTE + $40

;Menu status
M_SHOW_START_SCREEN 	= 0
M_UPDATE_START_SCREEN	= 1
M_SHOW_MAIN_MENU 		= 2
M_HANDLE_INPUT 			= 3

;Menu item mapping
START_RACE	=  1
ONE_PLAYER 	=  3
TWO_PLAYERS =  4
TRACK_1		=  6
TRACK_2		=  7
TRACK_3		=  8
TRACK_4		=  9
TRACK_5		= 10
QUIT_GAME	= 19

;Special characters
SPACE	 		= 32	;
MIDDLE_LINE_DIV	= 33 	;!
END_LINE_DIV	= 34 	;"
BLOCK			= 35	;#
FIRST_LINE_DIV 	= 38	;&
HAND     		= 40 	;hand is char 40-42 = ()*
COLON           = 58    ;:

;Constants for car behaviour
SKID_LIMIT = 16         ;how deep the turn needs to be before the car starts to skid
MAX_SPEED = 24          ;maximum speed that car accelerates to by itself when on road
MIN_SPEED = 14          ;minimum speed,the user can brake down to, when car is offroad the car will also slow down to this speed
MAX_EXTRA_ROTATION = 16 ;how much extra the car is rotated when skidding
SPEED_DELAY = 2         ;how fast the car is accelerating
BRAKE_DELAY = 4         ;how fast the car is braking/slowing down when off road
ANIMATION_DELAY = 4     ;how fast an exploding car is animated

CAR_START_DISTANCE = 24
PENALTY_TIME = 1        ;how much time that is added to a car that has been outrun
COLLISION_TIME = 1      ;how much time that is added for a car that has collided with the background 

;Sprite collisions
COLLISION_MASK = %00010000