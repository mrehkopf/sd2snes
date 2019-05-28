@ECHO OFF
del /q savestate.bin
xkas main.asm savestate.bin
cp savestate.bin D:/GDrive/Speedruns/Tools/USB2SNESv8/sd2snes/savestate.bin
cp savestate.bin F:/sd2snes/savestate.bin

REM e220 a902 8f19 007e 6b