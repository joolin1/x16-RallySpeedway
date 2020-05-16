;*** constants.asm *********************************************************************************

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