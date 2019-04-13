use_16f676  set 0 ; 0 = 16F630, 1 = 16F676

if use_16f676
  #include <p16f676.inc>
  processor p16f676
else
  #include <p16f630.inc>
  processor p16f630
endif
; ---------------------------------------------------------------------
;   feature enhanced auto region switching SNES CIC clone 
;   for PIC Microcontrollers (lock mode)
;
;   Copyright (C) 2010 by Maximilian Rehkopf (ikari_01) <otakon@gmx.net>
;   This software is part of the sd2snes project.
;
;   Last Modified: Oct. 2015 by Peter Bartmann <borti4938@gmx.de>
;
;   Based on reverse engineering work and disassembly by segher.
;   http://hackmii.com/2010/01/the-weird-and-wonderful-cic/
;
;   This program is free software; you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation; version 2 of the License only.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program; if not, write to the Free Software
;   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;
; ---------------------------------------------------------------------
;
;   pin configuration: (cartridge slot pin) [original 18-pin SMD lock CIC pin]
;   {alternative pin function in pair mode}
;
;                       ,-----_-----.
;      +5V (27,58) [18] |1        14| GND (5,36) [9]
;   CIC clk in (56) [7] |2  A5 A0 13| CIC lock reset in [8]
;                D4 out |3  A4 A1 12| 50/60Hz out
;        REG_TIMEOUT in |4  A3 A2 11| host reset out [10]
;         LED out (grn) |5  C5 C0 10| CIC data i/o 0 (55) [1] / {50/60Hz in}
;         LED out (red) |6  C4 C1  9| CIC data i/o 1 (24) [2] / {D4 in}
;           LED_TYPE in |7  C3 C2  8| CIC slave reset out (25) [11]
;                       `-----------'
;
;   pin 8 connected to key CIC pin 7 (or clone CIC pin 5)
;   pin 9 connected to key CIC pin 1 (or clone CIC pin 6)
;   pin 10 connected to key CIC pin 2 (or clone CIC pin 7)
;   pin 11 connected to key CIC pin 9 (SNES /reset line)
;   pin 12 connected to PPU1 pin 24 & PPU2 pin 30 (both isolated from mainboard)
;   pin 13 connected to reset button
;
;   LED_TYPE sets the output mode for the LED pins (must be tied to either level):
;      low  = common cathode
;      high = common anode   (output inverted)
;
;   D4 out is always switched to the autodetected region and is not user
;   overridable except in SuperCIC pair mode or when no key CIC is detected.
;   It can be used, by adding an address decoder and a latch, to override
;   bit 4 of the $213f register (used by games to detect the console region).
;
;   REG_TIMEOUT in (Pin 4) enables a ~9 sec timeout before switching
;   to the forced region. If D4 is not used, the REG_TIMEOUT pin should be
;   connected to Vcc.
;
;   Host reset out behaves as follows:
;   After powerup it is held low for a couple of ms to allow the components
;   to power-up properly.
;   It is then asserted a high level even if the CIC "auth" should fail at
;   any point, thus enabling homebrew or other cartridges without a CIC or
;   CIC clone to be run properly while maintaining compatibility with
;   cartridges requiring a CIC, like S-DD1 or SA-1 games.
;   The type of key CIC (411/413) is detected automatically.
;
;   This implementation supports automatic 50/60Hz switching based on the
;   detected key CIC in the game cartridge. Also the 50/60Hz setting can be
;   overridden by the user via the reset button.
;
;   Reset / Mode switch behaves as follows:
;   Reset is pressed for < 586ms -> reset console upon release
;   Reset is pressed for >= 586ms -> enter mode switch cycle, no reset
;   Modes are cycled every 586ms as shown in Fig.1 as long as the reset button
;   is held down.
;   The currently selected mode is indicated by the color of the power LED
;   (see Table 3).
;   The mode is finally selected by releasing the reset button while the
;   desired LED color is shown. The selected mode will then become effective
;   and will be saved to EEPROM. Mode switching does not reset the console.
;
;   Note that in case a valid CIC is detected in the game cartridge, video mode
;   will be forced to its corresponding region for the first ~9 seconds after
;   reset or powerup if the REG_TIMEOUT enable pin is high.
;   This is an attempt to trick the region detection on most games. See Table 1.
;   In case no CIC is present in the game cartridge, or REG_TIMEOUT is low, the
;   user setting is applied immediately.
;
;   SuperCIC pair mode: when a SuperCIC lock and SuperCIC key detect each other
;   they both switch both of the data pins to inputs. The lock then passes
;   through data i/o 0 to SNES 50/60Hz and data i/o 1 to an optional D4 output
;   (for overriding the 213f register using additional hardware). This makes it
;   possible to switch 50/60Hz and D4 from the cartridge slot, e.g. by
;   connecting an additional MCU to the CIC data lines. Of course, they have to
;   be tristated for normal (non-passthrough) operation.
;
;   Table 1. 50/60Hz output behavior according to user setting and key CIC type.
;   SuperCIC	key CIC		"region"
;   ------------------------------------------------------
;   60Hz	D/F413		50Hz for ~9 sec, then 60Hz
;   60Hz	D/F411		60Hz permanent
;   60Hz	none		60Hz permanent
;
;   50Hz	D/F413		50Hz permanent
;   50Hz	D/F411		60Hz for ~9 sec, then 50Hz
;   50Hz	none		50Hz permanent
;
;   Auto	D/F413		50Hz permanent
;   Auto	D/F411		60Hz permanent
;   Auto	none		60Hz permanent
;
;   Table 2. D4 output behavior according to key CIC type
;   key CIC	output
;   -----------------------------------------------
;   D/F413	1 (PAL)
;   D/F411	0 (NTSC)
;   none	same as user setting (NTSC if Auto)
;
;   Fig.1. SuperCIC mode cycle.
;   ,->60Hz--->50Hz--->Auto->.
;   `-------<--------<-------'
;
;   Table 3. LED color according to user setting.
;   mode	LED color
;   ---------------------
;   60Hz	red
;   50Hz	green
;   Auto	orange
;
;   Table 4. memory usage.
;   -------------------basic CIC functions--------------------
;   0x20		buffer for seed calc and transfer
;   0x21 - 0x2f		seed area (lock seed)
;   0x30		buffer for seed calc
;   0x31 - 0x3f		seed area (key seed; 0x31 filled in by lock)
;   0x40 - 0x41		buffer for seed calc
;   0x42		input buffer
;   0x43		variable for key detect
;   0x44		"direction" buffer
;   0x4d		buffer for eeprom access
;   0x4e		loop variable for longwait
;   0x4f		loop variable for wait
;   -------------------SuperCIC extensions--------------------
;   0x50		power LED state (no bits except 4 and 5 must be set!!)
;   0x51		last reset button state
;   0x52		mode dirty flag
;   0x53		tmr overflow counter
;   0x54		region output (0: 60Hz, 2: 50Hz)
;   0x55		final mode setting
;   0x56		temp LED state
;   0x57		detected region (0: 60Hz, 2: 50Hz)
;   0x58		forced region (0: 60Hz, 2: 50Hz)
;   0x59		detected D4 (0: 60Hz, 16: 50Hz)
;   0x5e		SuperCIC pair mode detect (phase 1)
;   0x5f		SuperCIC pair mode detect (phase 2)
;
; ---------------------------------------------------------------------


; -----------------------------------------------------------------------
    __CONFIG _EC_OSC & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF

; -----------------------------------------------------------------------
; code memory
	org	0x0000
	nop
	nop
	nop
	goto	init
trap
	movlw	0x3
	xorwf	PORTC, f
	goto	trap
rst				; we jump here after powerup or RC0=1
	bcf	PORTC, 0	; clear stream i/o
	bcf	PORTC, 1	; clear stream i/o
	bcf	PORTC, 2	; disable slave reset
	bcf	PORTA, 2	; hold the SNES in reset
	movlw	0x30		; prescaler 1:8
	movwf	T1CON		;
	clrf	PIR1
rst_loop
	btfsc	PORTA, 0	; stay in "reset" as long as RA0=1
	goto	rst_loop
	clrf	0x44		; clear dir buffer
	clrf	0x51		; clear reset button state
	clrf	0x52		; clear modechange flag
	clrf	0x53
	clrf	0x54		; clear user mode
	clrf	0x57		; clear key mode
	clrf	0x59		; clear D4
	clrf	0x5e		;
	clrf	0x5f		;
	bsf	STATUS, RP0     ; fetch current mode from EEPROM
	nop                     ; (RP 1 reserved and maintained as 0)
	clrf	EEADR		; address 0
	bsf	EECON1, RD	; 
	movf	EEDAT, w        ; 
	bcf	STATUS, RP0
	nop
	movwf	0x55		; store saved mode in mode var
	movwf	0x56		; and temp LED
	movwf	0x58		; and forced region
	andlw	0x03		; mask
	btfsc	PORTC, 3	; invert LEDs?
	xorlw	0x03		; then make it so	
	movwf	0x50		; and store
	swapf	0x50, f		; and nibbleswap for actual output

	btfss	PORTA, 3	; if D4 mode is disabled:
	bsf	0x53, 4 	; simulate region timeout->immediate region chg

	movlw	0x2
	andwf	0x58, f

	clrf	PIR1		; reset overflow bit
	clrf	TMR1L		; reset counter
	clrf	TMR1H
	bsf	T1CON, 0	; start the timer	
	goto	main		; go go go
init
;	PORTA:  in out  in out out  in
;	PORTC: out out  in out out  in
	bcf	STATUS, RP0
	nop
	clrf	PORTA
	movlw	0x07		; GPIO2..0 are digital I/O (not connected to comparator)
	movwf	CMCON
	movlw	0x00		; disable all interrupts
	movwf	INTCON
	bsf	STATUS, RP0
  if use_16f676
	clrf	ANSEL
  else
	nop
  endif
	movlw	0x29		; in out in out out in
	movwf	TRISA
	movlw	0x09		; out out in out out in
	movwf	TRISC
	movlw	0x00		; no pullups
	movwf	WPUA
	movlw	0x80		; global pullup disable
	movwf	OPTION_REG
	
	bcf	STATUS, RP0
	nop
	bcf 	PORTA, 2	; hold SNES in reset
	goto	rst
main
	movlw	0x40		; wait a bit before initializing the slave + console
	call	longwait

	nop
	
	bsf	PORTC, 2 	; trigger the slave
	nop
	nop
	bcf	PORTC, 2 	

	bsf	STATUS, RP0
	nop
	bcf	TRISC, 0
	bsf	TRISC, 1
	bcf	STATUS, RP0
	nop
; --------INIT LOCK SEED (what we must send)--------
	movlw	0xb
	movwf	0x21
	movlw	0x1
	movwf	0x22
	movlw	0x4
	movwf	0x23
	movlw	0xf
	movwf	0x24
	movlw	0x4
	movwf 	0x25
	movlw	0xb
	movwf 	0x26
	movlw	0x5
	movwf 	0x27
	movlw	0x7
	movwf 	0x28
	movlw	0xf
	movwf 	0x29
	movlw	0xd
	movwf 	0x2a
	movlw	0x6
	movwf 	0x2b
	movlw	0x1
	movwf 	0x2c
	movlw	0xe
	movwf 	0x2d
	movlw	0x9
	movwf 	0x2e
	movlw	0x8
	movwf 	0x2f
	
; --------INIT KEY SEED (what the key sends)--------
	movlw	0xf		; we always request the same stream for simplicity
	movwf	0x31
	movlw	0x0		; this is filled in by key autodetect
	movwf	0x32
	movlw	0xa
	movwf	0x33
	movlw	0x1
	movwf	0x34
	movlw	0x8
	movwf 	0x35
	movlw	0x5
	movwf 	0x36
	movlw	0xf
	movwf 	0x37
	movlw	0x1
	movwf 	0x38
	movwf 	0x39
	movlw	0xe
	movwf 	0x3a
	movlw	0x1
	movwf 	0x3b
	movlw	0x0
	movwf 	0x3c
	movlw	0xd
	movwf 	0x3d
	movlw	0xe
	movwf 	0x3e
	movlw	0xc
	movwf 	0x3f
	
; --------wait before sending stream ID--------
	movlw	0xba
	call	wait

; --------lock sends stream ID. 15 cycles per bit--------
	btfsc	0x31, 3		; read stream select bit
	bsf	PORTC, 0	; send bit
	nop
	nop
	bcf	PORTC, 0
	movlw	0x1		; wait=3*0+7
	call	wait		; burn 10 cycles in total
	nop
	nop

	btfsc	0x31, 0		; read stream select bit
	bsf	PORTC, 0	; send bit
	nop
	nop
	bcf	PORTC, 0
	movlw	0x1		; wait=3*0+7
	call	wait		; burn 10 cycles in total
	nop
	nop

	btfsc	0x31, 1		; read stream select bit
	bsf	PORTC, 0	; send bit
	nop
	nop
	bcf	PORTC, 0
	movlw	0x1		; wait=3*0+7
	call	wait		; burn 10 cycles in total
	nop
	nop

	btfsc	0x31, 2		; read stream select bit
	bsf	PORTC, 0	; send bit
	nop
	nop
	bcf	PORTC, 0
	movlw	0x1		; wait=3*0+7
	call	wait		; burn 10 cycles in total
	bsf     STATUS, RP0
	nop
	bsf	TRISC, 0
	bcf	TRISC, 1
	bcf     STATUS, RP0
	nop
	movlw	0x22		;
	call	wait		; wait 106
	nop
	nop
	movlw	0x1		; 'first time' bit
	movwf	0x43		; for key detection
; --------main loop--------
loop	
	movlw	0x1
loop0
	addlw	0x20		; lock stream
	movwf	FSR		; store in index reg
loop1
	nop
	movf	INDF, w 	; load seed value
	andlw	0x01		; mask LSB
	movwf	0x20
	btfsc	0x20, 0 	; copy from bit 0
	bsf	0x20, 1 	; (if set)
	movf	0x50, w 	; get LED state
	iorwf	0x20, f		; combine with data i/o
	movf	0x20, w
	movwf	PORTC
	nop
	nop
	movf	PORTC, w 	; read input
	movwf	0x42		; store input
	movf	0x50, w		; get LED state
	movwf	PORTC		; reset GPIO

	call	checkkey

	btfsc	0x44, 0		; check "direction"
	rrf	0x42, f		; shift received bit into place
	bsf	FSR, 4  	; goto other stream
	movf	INDF, w		; read
	xorwf	0x42, f 	; xor received + calculated
	bcf	FSR, 4		; back to our own stream
	btfsc	0x42, 0 	; equal? then continue
	bsf	0x43, 1		; else mark key invalid

	btfss	0x43, 1 	; if key invalid:
	goto	main_skipinval1 ; 
	bcf	0x57, 1 	; set det.region=60Hz
	bsf	0x53, 4 	; simulate region timeout->immediate region chg
	clrf	0x59		; clear D4 output
	btfsc	0x54, 1		; use effective region for D4 output
	bsf	0x59, 4

main_skipinval2
	call	checkrst

	incf	FSR, f		; next one
	movlw	0xf
	andwf	FSR, w
	btfss	STATUS, Z	
	goto	loop1
	call	mangle
	call	mangle
	call	mangle
	movf	0x37, w
	movwf	0x44
	nop
	nop
	nop
	nop
	btfsc	0x37, 0
	goto	swap
	bsf	STATUS, RP0
	nop
	bsf	TRISC, 0
	bcf	TRISC, 1
	goto	swapskip
swap
	bsf	STATUS, RP0
	nop
	bcf	TRISC, 0
	bsf	TRISC, 1
	nop
swapskip
	bcf	STATUS, RP0
	nop
	bsf	0x54, 2		; run the console
	movf	0x54, w		; read resolved mode
	iorwf	0x59, w		; get D4 value
	movwf	PORTA
	bcf	0x43, 0		; don't check key region anymore
	movf	0x37, w
	andlw	0xf
	btfss	STATUS, Z
	goto	loop0
	goto	loop


main_skipinval1
	nop
	nop
	goto	main_skipinval2


; --------calculate new seeds--------
; had to be unrolled because PIC has an inefficient way of handling
; indirect access, no post increment, no swap, etc.
mangle
	call	mangle_lock
	nop
	nop
mangle_key
	movf	0x2f, w
	movwf	0x20	
mangle_key_loop
	addlw	0x1
	addwf	0x21, f
	movf	0x22, w
	movwf	0x40
	movf	0x21, w
	addwf	0x22, f
	incf	0x22, f
	comf	0x22, f
	movf	0x23, w
	movwf	0x41		; store 23 to 41
	movlw	0xf
	andwf	0x23, f
	movf	0x40, w 	; add 40(22 old)+23+#1 and skip if carry
	andlw	0xf
	addwf	0x23, f
	incf	0x23, f
	btfsc	0x23, 4
	goto	mangle_key_withskip
mangle_key_withoutskip
	movf	0x41, w 	; restore 23
	addwf	0x24, f 	; add to 24
	movf	0x25, w
	movwf	0x40		; save 25 to 40
	movf	0x24, w
	addwf	0x25, f
	movf	0x26, w
	movwf	0x41		; save 26 to 41
	movf	0x40, w 	; restore 25
	andlw	0xf		; mask nibble
	addlw	0x8		; add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 	; skip if carry to 5th bit
	addwf	0x26, w
	movwf	0x26

	movf	0x41, w 	; restore 26
	addlw	0x1		; inc
	addwf	0x27, f		; add to 27

	movf	0x27, w 	;
	addlw	0x1		; inc
	addwf	0x28, f 	; add to 28

	movf	0x28, w 	;
	addlw	0x1		; inc
	addwf	0x29, f 	; add to 29

	movf	0x29, w 	;
	addlw	0x1		; inc
	addwf	0x2a, f 	; add to 2a

	movf	0x2a, w 	;
	addlw	0x1		; inc
	addwf	0x2b, f 	; add to 2b

	movf	0x2b, w 	;
	addlw	0x1		; inc
	addwf	0x2c, f 	; add to 2c

	movf	0x2c, w 	;
	addlw	0x1		; inc
	addwf	0x2d, f 	; add to 2d

	movf	0x2d, w 	;
	addlw	0x1		; inc
	addwf	0x2e, f 	; add to 2e

	movf	0x2e, w 	;
	addlw	0x1		; inc
	addwf	0x2f, f 	; add to 2f

	movf	0x20, w 	; restore original 0xf
	andlw	0xf
	addlw	0xf
	movwf	0x20
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	btfss	0x20, 4 	; skip if half-byte carry
	goto mangle_return 	; +2 cycles in return
	nop
	goto mangle_key_loop
; 69 when goto, 69 when return
; CIC has 78 -> 9 nops

mangle_key_withskip
	movf	0x41, w 	; restore 23
	addwf	0x23, f 	; add to 23
	movf	0x24, w
	movwf	0x40		; save 24 to 40
	movf	0x23, w
	addwf	0x24, f
	movf	0x25, w
	movwf	0x41		; save 25 to 41
	movf	0x40, w 	; restore 24
	andlw	0xf		; mask nibble
	addlw	0x8		; add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 	; skip if carry to 5th bit
	addwf	0x25, w
	movwf	0x25

	movf	0x41, w 	; restore 25
	addlw	0x1		; inc
	addwf	0x26, f		; add to 26

	movf	0x26, w 	;
	addlw	0x1		; inc
	addwf	0x27, f 	; add to 27

	movf	0x27, w 	;
	addlw	0x1		; inc
	addwf	0x28, f 	; add to 28

	movf	0x28, w 	;
	addlw	0x1		; inc
	addwf	0x29, f 	; add to 29

	movf	0x29, w 	;
	addlw	0x1		; inc
	addwf	0x2a, f 	; add to 2a

	movf	0x2a, w 	;
	addlw	0x1		; inc
	addwf	0x2b, f 	; add to 2b

	movf	0x2b, w 	;
	addlw	0x1		; inc
	addwf	0x2c, f 	; add to 2c

	movf	0x2c, w 	;
	addlw	0x1		; inc
	addwf	0x2d, f 	; add to 2d

	movf	0x2d, w 	;
	addlw	0x1		; inc
	addwf	0x2e, f 	; add to 2e

	movf	0x2e, w 	;
	addlw	0x1		; inc
	addwf	0x2f, f 	; add to 2f

	movf	0x20, w 	; restore original 0xf
	andlw	0xf
	addlw	0xf
	movwf	0x20
	bsf	PORTC, 1
	movf	PORTC, w
	movwf	0x5e
	nop
	bcf	PORTC, 1
	nop ; add nop here, 2010 SCIC key is a bit late.
	movf	PORTC, w
	movwf	0x5f
	nop
	nop
	nop
	btfss	0x20, 4 	; skip if half-byte carry
	goto mangle_return 	; +2 cycles in return
	movf	0x20, w		; restore w (previously destroyed)
	goto mangle_key_loop
mangle_return
	return
; 73 when goto, 73 when return
; CIC has 84 -> 11 nops

mangle_lock
	movf	0x3f, w
	movwf	0x30	
mangle_lock_loop
	addlw	0x1
	addwf	0x31, f
	movf	0x32, w
	movwf	0x40
	movf	0x31, w
	addwf	0x32, f
	incf	0x32, f
	comf	0x32, f
	movf	0x33, w
	movwf	0x41		; store 33 to 41
	movlw	0xf
	andwf	0x33, f
	movf	0x40, w 	; add 40(32 old)+33+#1 and skip if carry
	andlw	0xf
	addwf	0x33, f
	incf	0x33, f
	btfsc	0x33, 4
	goto	mangle_lock_withskip
mangle_lock_withoutskip
	movf	0x41, w 	; restore 33
	addwf	0x34, f 	; add to 34
	movf	0x35, w
	movwf	0x40		; save 35 to 40
	movf	0x34, w
	addwf	0x35, f
	movf	0x36, w
	movwf	0x41		; save 36 to 41
	movf	0x40, w 	; restore 35
	andlw	0xf		; mask nibble
	addlw	0x8		; add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 	; skip if carry to 5th bit
	addwf	0x36, w
	movwf	0x36

	movf	0x41, w 	; restore 36
	addlw	0x1		; inc
	addwf	0x37, f		; add to 37

	movf	0x37, w 	;
	addlw	0x1		; inc
	addwf	0x38, f 	; add to 38

	movf	0x38, w 	;
	addlw	0x1		; inc
	addwf	0x39, f 	; add to 39

	movf	0x39, w 	;
	addlw	0x1		; inc
	addwf	0x3a, f 	; add to 3a

	movf	0x3a, w 	;
	addlw	0x1		; inc
	addwf	0x3b, f 	; add to 3b

	movf	0x3b, w 	;
	addlw	0x1		; inc
	addwf	0x3c, f 	; add to 3c

	movf	0x3c, w 	;
	addlw	0x1		; inc
	addwf	0x3d, f 	; add to 3d

	movf	0x3d, w 	;
	addlw	0x1		; inc
	addwf	0x3e, f 	; add to 3e

	movf	0x3e, w 	;
	addlw	0x1		; inc
	addwf	0x3f, f 	; add to 3f

	movf	0x30, w 	; restore original 0xf
	andlw	0xf
	addlw	0xf
	movwf	0x30
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	btfss	0x30, 4 	; skip if half-byte carry
	goto mangle_return
	nop
	goto mangle_lock_loop
; 69 when goto, 69 when return
; CIC has 78 -> 9 nops

mangle_lock_withskip
	movf	0x41, w 	; restore 33
	addwf	0x33, f 	; add to 33
	movf	0x34, w
	movwf	0x40		; save 34 to 40
	movf	0x33, w
	addwf	0x34, f
	movf	0x35, w
	movwf	0x41		; save 35 to 41
	movf	0x40, w 	; restore 34
	andlw	0xf		; mask nibble
	addlw	0x8		; add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 	; skip if carry to 5th bit
	addwf	0x35, w
	movwf	0x35

	movf	0x41, w 	; restore 35
	addlw	0x1		; inc
	addwf	0x36, f		; add to 36

	movf	0x36, w 	;
	addlw	0x1		; inc
	addwf	0x37, f 	; add to 37

	movf	0x37, w 	;
	addlw	0x1		; inc
	addwf	0x38, f 	; add to 38

	movf	0x38, w 	;
	addlw	0x1		; inc
	addwf	0x39, f 	; add to 39

	movf	0x39, w 	;
	addlw	0x1		; inc
	addwf	0x3a, f 	; add to 3a

	movf	0x3a, w 	;
	addlw	0x1		; inc
	addwf	0x3b, f 	; add to 3b

	movf	0x3b, w 	;
	addlw	0x1		; inc
	addwf	0x3c, f 	; add to 3c

	movf	0x3c, w 	;
	addlw	0x1		; inc
	addwf	0x3d, f 	; add to 3d

	movf	0x3d, w 	;
	addlw	0x1		; inc
	addwf	0x3e, f 	; add to 3e

	movf	0x3e, w 	;
	addlw	0x1		; inc
	addwf	0x3f, f 	; add to 3f

	movf	0x30, w 	; restore original 0xf
	andlw	0xf
	addlw	0xf
	movwf	0x30
	
	btfsc	0x5e, 0
	goto	scic_pair_skip1
	btfss	0x5f, 0
	goto	scic_pair_skip2
	goto	supercic_pairmode
scic_pair_skip1
	nop
	nop
scic_pair_skip2	
	nop
	nop
	nop
	nop
	nop
	nop

	btfss	0x30, 4 	; skip if half-byte carry
	goto mangle_return
	nop
	goto mangle_lock_loop
; 73 when goto, 73 when return
; CIC has 84 -> 11 nops

; --------wait: 3*(W-1)+7 cycles (including call+return). W=0 -> 256!--------
wait	
	movwf	0x4f
wait0	decfsz	0x4f, f
	goto	wait0
	return	

; --------wait long: 8+(3*(w-1))+(772*w). W=0 -> 256!--------
longwait
	movwf	0x4e
	clrw
longwait0
	call	wait
	decfsz	0x4e, f
	goto	longwait0
	return

; --------die (do nothing, wait for reset)--------
die
	btfsc	PORTA, 0
	goto	rst
	goto	die

; --------check the key input and change "region" when appropriate--------
; --------requires 20 cycles (incl. call+return)
checkkey
	btfss	0x43, 0		; first time?
	goto 	checkkey_nocheck; if not, just burn some cycles
	movlw	0x22		; are we at the correct stream offset?
	xorwf	FSR, w
	btfss	STATUS, Z	; if not equal:
	goto	checkkey_nocheck2; burn some cycles less.
				; if equal do the check
	btfss	0x42, 0		; if value from slave is set it's a 411
	goto	checkkey_413
checkkey_411
	nop			; to compensate for untaken branch
	bcf	0x57, 1		; set detected mode (60Hz)
	bcf	0x59, 4		; set detected D4 mode (60Hz)
	bcf	0x54, 1		; set output mode (60Hz)
	movlw	0x9
	goto	checkkey_save
checkkey_413
	bsf	0x57, 1		; set detected mode (50Hz)
	bsf	0x59, 4		; set detected D4 mode (50Hz)
	bsf	0x54, 1		; set output mode (50Hz)
	movlw	0x6
	goto	checkkey_save

checkkey_nocheck
	nop
	nop
	nop
	nop
checkkey_nocheck2
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	goto checkkey_done
checkkey_save
	movwf	0x32
checkkey_done
	return

; -------- check reset button, update status LEDs, etc.
checkrst	; 4
	movf	PORTA, w
	btfss	0x51, 0
	goto	checkrst_0
	nop
checkrst_1	; 4
	movwf	0x51
	btfsc	0x51, 0
	goto	checkrst_1_1
	nop
checkrst_1_0	; 26
	; if modechange flag is set: clear modechange flag, set mode, save, restart timer
	; else reset
	btfss	0x52, 0
	goto	rst2		; modechange flag is not set, reset. timing is irrelevant
	clrf	0x52		; clear modechange flag
	movf	0x56, w		; get temp mode
	movwf	0x55		; set final mode
	movwf	0x58		; set forced mode
	bsf	STATUS, RP0     ; save to EEPROM
	nop
	movwf	EEDAT
	bsf	EECON1,WREN
	movlw	0x55
	movwf	EECON2
	movlw	0xaa
	movwf	EECON2
	bsf	EECON1, WR
	bcf	STATUS, RP0     ; two cycles again
	nop
	movlw	0x2
	andwf	0x58, f		; cleanup forced mode
	bcf	T1CON, 0	; stop the timer
	clrf	PIR1		; reset overflow bit
	clrf	TMR1L		; reset counter
	clrf	TMR1H
	bsf	T1CON, 0	; restart the timer	
	return			; shortcut (no goto checkrst_end)
checkrst_1_1	; 24
	; check TMR overflow
	; if overflow, change LED, reset TMR+overflow, set modechange flag
	; else do nothing
	nop
	nop
	nop
	nop
	btfss	PIR1, 0
	goto	checkrst_end_plus17
	bcf	T1CON, 0	; stop the timer
	clrf	PIR1		; reset overflow bit
	clrf	TMR1L		; reset counter
	clrf	TMR1H
	bsf	T1CON, 0	; restart the timer
	incf	0x56, f		; change tmp LED/mode
	movlw	0x5
	btfsc	0x56, 2		; if 4:
	xorwf	0x56, f		; change back to 1
	movf	0x56, w
	andlw	0x03		; mask
	btfsc	PORTC, 3	; invert LEDs?
	xorlw	0x03		; then make it so
	movwf	0x50
	swapf	0x50, f		; adjust for GPIO pins
	bsf	0x52, 0		; set modechange flag
	goto	checkrst_end

checkrst_0	; 4
	movwf	0x51
	btfsc	0x51, 0
	goto	checkrst_0_1
	nop
checkrst_0_0	; 24
	nop
	nop
	nop
	nop
	nop
	nop
	; count some overflows, change region from detected to forced unless auto
	btfsc	0x53, 4		; past delay?
	goto	checkrst_0_0_setregion_plus5
	btfss	PIR1, 0
	goto	checkrst_end_plus13
	clrf	PIR1
	incf	0x53, f		; increment overflow counter
	btfss	0x53, 4		; 0x10 reached?
	goto	checkrst_end_plus9
checkrst_0_0_setregion
	movlw	0x3
	xorwf	0x55, w 	; mode=auto?
	btfss	STATUS, Z
	goto	checkrst_0_0_setregion_forced
checkrst_0_0_setregion_auto
	movf	0x57, w 	; get detected region
	goto checkrst_0_0_setregion_save
checkrst_0_0_setregion_forced
	movf	0x58, w		; get forced region
	nop
checkrst_0_0_setregion_save
	movwf	0x54		; set to output
	goto	checkrst_end

checkrst_0_1	; 24
	; reset + start TMR, reset TMR overflow
	clrf	TMR1L		; reset timer register
	clrf	TMR1H
	clrf	PIR1		; clear overflow bit
	bsf	T1CON, 0
	goto	checkrst_end_plus18

checkrst_end	; 2
	return

checkrst_end_plus18
	nop
checkrst_end_plus17
	nop
	nop
	nop
	nop
checkrst_end_plus13
	nop
	nop
	nop
	nop
checkrst_end_plus9
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	goto	checkrst_end

checkrst_0_0_setregion_plus5
	nop
	nop
	nop
	goto	checkrst_0_0_setregion

supercic_pairmode
	bsf	STATUS, RP0
	nop
	bsf	TRISC, 0	; tristate both
	bsf	TRISC, 1	; data lines
	bcf	STATUS, RP0
	nop
supercic_pairmode_loop
	clrf	0x5d
	bsf	0x5d, 2
	btfsc	PORTC, 0
	bsf	0x5d, 1
	btfsc	PORTC, 1
	bsf	0x5d, 4
	btfsc	PORTA, 0
	bcf	0x5d, 2
	movf	0x5d, w
	movwf	PORTA
	btfss	PORTC, 0
	goto	supercic_pairmode_led_60
supercic_pairmode_led_50
	movlw	0x20
	btfsc	PORTC, 3
	xorlw	0x30
	movwf	PORTC
	goto	supercic_pairmode_loop
supercic_pairmode_led_60
	movlw	0x10
	btfsc	PORTC, 3
	xorlw	0x30
	movwf	PORTC
	goto	supercic_pairmode_loop

rst2
	bcf	PORTA, 2	; hold the SNES in reset
	bcf	T1CON, 0	; stop the timer
	clrf	TMR1L		; reset timer register
	clrf	TMR1H
	clrf	PIR1		; clear overflow bit
	bsf	T1CON, 0
	clrf	0x51		; clear reset button state
rst2_loop1
	btfsc	PORTA, 0	; if reset button is pressed
	bsf	0x51, 0		; set reset flag
	btfss	PIR1, 0		; break if timeout
	goto	rst2_loop1
	
	btfss	0x51, 0		; if no 2nd reset button press occured:
	goto	rst		; just reset normally

	clrf	0x53		; else keep resetting some more	
	bcf	T1CON, 0	; stop the timer
	clrf	TMR1L		; reset timer register
	clrf	TMR1H
	clrf	PIR1		; clear overflow bit
	bsf	T1CON, 0
rst2_loop2
	btfss	PIR1, 0
	goto	rst2_loop2
	clrf	PIR1
	incf	0x53, f
	movlw	0x0a
	xorwf	0x53, w
	btfss	STATUS, Z	; 10 overflows ~= 5.86s
	goto	rst2_loop2
	goto	rst		; finally reset
; -----------------------------------------------------------------------
; eeprom data
	org __EEPROM_START
	de	0x01		;current mode (default: 60Hz)
	end
; ------------------------------------------------------------------------
