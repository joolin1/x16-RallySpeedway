;*** badgesprites.asm - handle badges used for framing text ****************************************

BADGE_SPRITE0 = $FC00 + ((TEXTSPRITE_COUNT + 2 + 1)* 8)     ;first badge sprite is after sprite 0, two car sprites and all text sprites) 
BADGE_SPRITE1 = BADGE_SPRITE0 + 8
BADGE_SIZE = 256

InitBadgeSprites:
        ;init badge sprites
        +VPokeI BADGE_SPRITE0 + 2, 4                    ;x-position
        +VPokeI BADGE_SPRITE0 + 3, 0
        +VPokeI BADGE_SPRITE1 + 2, 29
        +VPokeI BADGE_SPRITE1 + 3, 1
        +VPokeSpritesI BADGE_SPRITE0 + 4, 2, 221        ;y-position
        +VPokeSpritesI BADGE_SPRITE0 + 5, 2, 0
        +VPokeSpritesI BADGE_SPRITE0 + 7, 2, %01100000  ;height = 16, width = 32, palette offset = 0
        rts

DisplayYCarBadge:
        +VPokeI BADGE_SPRITE0    , <(BADGES_ADDR >> 5)    ;always start with red color
        +VPokeI BADGE_SPRITE0 + 1, >(BADGES_ADDR >> 5)
        +VPokeI BADGE_SPRITE0 + 6, 8                      ;Z-depth = between layer 0 and 1
        rts

DisplayBCarBadge:
        +VPokeI BADGE_SPRITE1,     <(BADGES_ADDR >> 5)    ;always start with red color
        +VPokeI BADGE_SPRITE1 + 1, >(BADGES_ADDR >> 5)
        +VPokeI BADGE_SPRITE1 + 6, 8                      ;Z-depth = between layer 0 and 1
        rts

SetYCarBadgeToGreen:
        +VPokeI BADGE_SPRITE0,     <((BADGES_ADDR + BADGE_SIZE) >> 5)
        +VPokeI BADGE_SPRITE0 + 1, >((BADGES_ADDR + BADGE_SIZE) >> 5)
        rts

SetBCarBadgeToGreen:
        +VPokeI BADGE_SPRITE1,     <((BADGES_ADDR + BADGE_SIZE) >> 5)
        +VPokeI BADGE_SPRITE1 + 1, >((BADGES_ADDR + BADGE_SIZE) >> 5)
        rts

HideBadges:
        +VPokeSpritesI BADGE_SPRITE0 + 6, 2, 0          ;disable by setting Z-depth to 0
        rts 