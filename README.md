# x16-RallySpeedway
A topdown racing game for the retro computer Commander X16. If you ever played Rally Speedway for Commodore 64 or Atari, it will feel familiar. I consider it a late sequel, somewhat improved actually and hopefully still fun. 

Here is how you start the emulator depending on how many game controllers you have:

No controllers:
Just start the emulator and use the following keys: Ctrl - Button A, Alt - Button B, Enter - START, Cursor Keys - UP, DOWN, LEFT, RIGHT. Naturally, you can just play in one-player-mode.

One controller:
Start the emulator with -joy2 SNES (or "NES", depending on you controller type). Now player 1 uses the keyboard and player 2 the game controller.

Two controllers:
Start the emulator with -joy1 SNES/NES -joy2 SNES/NES.

For example if you have two SNES controllers and want to load and run the game immediately: "x16emu -joy1 SNES -joy2 SNES -prg rallyspeedway.prg -run" 

Rules of the game:

This is an open world racing game. It means that for every track there is a certain distance you have to drive. When you have reached the distance, you are ready to cross any finish line you happen find. To be honest, most of the time
you will probably follow the road and continue straight ahead in every crossing if there isn't an arrow to point you in a certain direction. Remaining distance is displayed in the bottom corner of the screen.
But you can also find your own way. Just remember that every time you crash or get too far away from the other car, the race will pause and you will be brought back to the standard route.
For every crash a penalty of one second is added to your time. This is also the case if you are outdistanced by the other player. You can only be outdistanced as long as the other player is on the road, driving the standard route.
