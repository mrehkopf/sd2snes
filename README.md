sd2snes
=======

SD card based multi-purpose cartridge for the SNES

Built-in Savestates
---
First of all, thanks to RedGuy for making the usb2snes 1.8 firmware and helping me out with some issues I had while messing around for the first time with sd2snes. He also made the savestate code used as base for this firmware.

Secondly, I also wanna thank my friend Vitor Vilela that helped me alot with assembly stuff, he's an asm god!

You'll need to download the sd2snes 1.8 firmware and then replace the files inside the "sd2snes" folder

Features
---
1. Built-in Savestates without PC connection/patch
2. New Menu Settings:
	- Enable/disable savestates (choose a controller)
	- Enable/disable savestate slots
	- Loadstate delay (frames)
3. Default Inputs for Save/Load in *config.yml*
4. Custom Inputs for Save/Load for specific games in *savestate_inputs.yml*
5. Savestates are stored in the SD (*sd2snes/states*)

Savestates Slots
---
Enabling this option you'll have 4 slots to choose, pressing `Select+Dpad` (each direction is a slot)

**Up:** Slot 01 / **Right:** Slot 02 / **Down:** Slot 03 / **Left:** Slot 04

Disabling this will always use the first slot. You can change the `Select` to another button in config.yml file

Loadstate Delay
--
Loadstates are too quick, if you need to regrab other buttons that was pressed in the moment you made the savestate, this option gives you a small time to help you with that or whatever other reason.

Customizing Save/Load Inputs
--
You'll need to convert your input into a valid 16bit hexadecimal value, each bit is a button you can use a calculator:

**byetUDLR axlr0000**

**b/y/e/t/U/D/L/R** = *B/Y/Select/Start/Up/Down/Left/Right* button status.

**a/x/l/r** = *A/X/L/R* control pad status. *0/0/0/0* buttons that aren't present in the controller.

### config.yml 
*"IngameSavestateButtons"* and *"IngameLoadstateButtons"* variables holds the default inputs for Save/Load, which are:

**1020** = 00100000 00100000 = `Start+L`

**1010** = 00100000 00100000 = `Start+R`

### savestate_inputs.yml
You can define custom inputs for each game you want, you'll need the rom checksum value (different versions has different checksums). Examples:

```
# CHKSUM: SAVE,LOAD
2BCC: 0050,0060 # dkc1 v1.1 (US) / X+R, X+L
0C17: 0050,0060 # dkc1 v1.0 (JP) / X+R, X+L
9860: 0050,0060 # dkc2 (US) / X+R, X+L
35CE: 0050,0060 # dkc2 (JP) / X+R, X+L
B28C: 0050,0060 # dkc3 (US) / X+R, X+L
E545: 0050,0060 # dkc3 (JP) / X+R, X+L
F8DF: 6010,6020 # super metroid (*) / Y+Select+R, Y+Select+L
A0DA: 0050,0060 # smw (US) / X+R, X+L
8C80: 0050,0060 # smw (JP) / X+R, X+L
33C2: 1010,1020 # soe (US) / Start+R, Start+L
```

### savestate_fixes.yml
This file contains a few fixes for some games that has problems with APU. Examples:

```
# CKSUM: ADDR,APU;PCADDR,PATCH
64E9: 7E174B,2142;05C10D,A1 # This updates $7E174B with the latest $2142 state, it also patches 1 byte at the rom 0x05C10D (pc address)
```

Known Savestates Issues
---
Savestates will only work with games that don't have special chips like SuperFX/SA-1/CX4, this is because the firmware loads another FPGA file for those games and it doesn't have necessary configuration to run custom code.

Flashcart savestates aren't perfect, the code runs on NMI to save a bunch of addresses to another place. You'll notice the song in some games will keep playing after you load state, others will just crash.

RedGuy did a great job finding fixes for some games, but for now he will focus on other projects. But you can try to find/contact someone who knows assembly and try to find a solution for that.

Final Words
---
Thanks for the support, I'll keep you updated at my Twitter: [@furious_](http://twitter.com/furious)

If you really want donate or something, you can find links on my Twitch channel: [twitch.tv/furious](http://twitch.tv/furious)
