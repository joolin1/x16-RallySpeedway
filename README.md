# x16-RallySpeedway
A topdown racing game for the retro computer Commander X16. If you ever played RallySpeedway for C64 or Atari, it will feel familiar. I consider it a late sequel, slightly approved actually and hopefully still fun. 

Here is how you start the emulator depending on how many game controllers you have:

No controllers:
Just start the emulator and use the following keys: Ctrl - Button A, Alt - Button B, Enter - START, Cursor Keys - UP, DOWN, LEFT, RIGHT. Naturally, you can just play in one-player-mode.

One controller:
Start the emulator with -joy2 SNES (or "NES", depending on you controller type). Now player 1 uses the keyboard and player 2 the game controller.

Two controllers:
Start the emulator with -joy1 SNES/NES -joy2 SNES/NES.

For example if you have two SNES controllers and want to load and run the game immediately: "x16emu -joy1 SNES -joy2 SNES -prg rallyspeedway.prg -run" 
