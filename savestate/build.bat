@ECHO OFF
del /q savestate.bin
asar main.asm savestate.bin
ECHO Done.