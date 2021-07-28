## Built-in Savestates - Notes from FURiOUS
First of all, thanks to RedGuy for making the usb2snes firmware and helping me out with some issues I had while messing around for the first time with sd2snes. He also made the savestate code used as base for this firmware.

Secondly, I also wanna thank my friend Vitor Vilela that helped me alot with assembly stuff, he's an asm god!

### Features
1. Built-in Savestates without PC connection/patch
2. New Menu Settings:
	- Enable/disable savestates
	- Enable/disable savestate slots
	- Loadstate delay (frames)
3. Default Inputs for Save/Load and Slots in *config.yml*
4. Custom Inputs for Save/Load for specific games in *savestate_inputs.yml*
5. Savestates are stored in the SD (*sd2snes/states*)

### Savestates Slots
Enabling this option you'll have 4 slots to choose, pressing `Select+Dpad` (each direction is a slot)
|Select +|Slot|
---|---
|**Up**|Slot 1|
|**Right**|Slot 2|
|**Down**|Slot 3|
|**Left**|Slot 4|

Disabling this will always use the first slot. You can change the `Select` to another button in config.yml file.

*Just to make it clear, this only changes the slot you're saving/loading so you still need to save/load state after selecting a slot*

### Loadstate Delay
Loadstates are too quick, if you need to regrab other buttons that was pressed in the moment you made the savestate, this option gives you a small time to help you with that or whatever other reason.

### Customizing Save/Load Inputs
You'll just need to type the input buttons as string (without any spaces):

- `B Y A X` = Buttons
- `u d l r` = Dpad
- `s` = Select (lowercase)
- `S` = Start (uppercase)
- `L R` = Shoulder buttons

### config.yml 
*"IngameButtonsLoadState"* and *"IngameButtonsSaveState"* variables hold the default inputs for Load / Save, which are:

- **Load**: `SL` = Start+L
- **Save**: `SR` = Start+R

#### **savestate_inputs.yml**
You can define custom inputs for each game you want, you'll need the rom checksum value (different versions has different checksums). Examples:

```
# CHECKSUM: SAVE,LOAD
EF80: XR,XL     #dkc1 v1.1 (US)
2BCC: XR,XL     #dkc1 v1.1 (US)
0C17: XR,XL     #dkc1 v1.0 (JP)
1202: XR,XL     #dkc2 (US)
9860: XR,XL     #dkc2 (US)
35CE: XR,XL     #dkc2 (JP)
B28C: XR,XL     #dkc3 (US)
E545: XR,XL     #dkc3 (JP)
F8DF: sYR,sYL   #super metroid (*)
0C17: AR,AL     #super valis (US)
5B4C: AR,AL     #super valis (JP)
```

#### **savestate_fixes.yml**
This file contains a few fixes for some games that has problems with APU. Examples:

```
# CKSUM: ADDR,APU;PCADDR,PATCH
64E9: 7E174B,2142;05C10D,A1 # This updates $7E174B with the latest $2142 state, it also patches 1 byte at the rom 0x05C10D (pc address)
```

### Known Savestates Issues
Savestates will only work with games that don't have special chips like SuperFX/SA-1/CX4, this is because the firmware loads another FPGA file for those games and it doesn't have necessary configuration to run custom code.

Flashcart savestates aren't perfect, the code runs on NMI to save a bunch of addresses to another place. You'll notice the song in some games will keep playing after you load state, others will just crash.

RedGuy did a great job finding fixes for some games, but for now he will focus on other projects. But you can try to find/contact someone who knows assembly and try to find a solution for that.

Savestates currently doesn't work with In-game Hooks, you must disable it to use this feature.

Final Words
---
If you find this useful and would like to contribute, you can donate at [http://furious.pro/donate](http://furious.pro/donate)

Follow FURiOUS's Twitter for updates: [@furious_](http://twitter.com/furious_)