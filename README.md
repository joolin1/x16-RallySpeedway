# x16-RallySpeedway
A topdown racing game for the retro computer Commander X16. If you ever played Rally Speedway for Commodore 64 or Atari, it will feel familiar. I consider it a late sequel, somewhat improved actually and hopefully still fun. 

Starting the game:

All game files should be in the same directory. Depending of how many game controllers you have, this is how you start the X16 emulator:

No controllers:
Just start the emulator and use the following keys: Ctrl - Button A, Alt - Button B, Enter - START, Cursor Keys - UP, DOWN, LEFT, RIGHT. Naturally, you can just play in one-player-mode.

One controller:
Start the emulator with -joy2. Player 1 will use the keyboard and player 2 the game controller.

Two controllers:
Start the emulator with -joy1 -joy2

For example if you have two controllers and want to load and run the game immediately: "x16emu -joy1 -joy2 -prg rallyspeedway.prg -run" 

Controls:

Up - Start the race when cars are in position

A Button - Brake (the cars will accelerate to maximum speed automatically) 

B Button - Return to menu when race is finished

Start Button - Pause game 

Rules:

This is an open world racing game. For every track there is a certain distance you have to drive. When you have driven the given distance, you are ready to cross any finish line you happen to find. Remaining distance is displayed in the bottom corner of the screen. To be honest, most of the time you will probably just follow the default route by following the road continue straight ahead in every crossing if there isn't an arrow to point you in a certain direction. But you can also find your own way. Just remember that every time you crash or get too far away from the other car, the race will pause and you will be brought back to the standard route. For every crash a penalty of one second is added to your time. This is also the case if you are outdistanced by the other player. You can only be outdistanced as long as the other player is on the road and driving the standard route.

