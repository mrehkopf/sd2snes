    #include <p12f629.inc>
processor p12f629

; ---------------------------------------------------------------------
;   feature enhanced SNES CIC clone for PIC Microcontroller (key mode only)
;
;   Copyright (C) 2010 by Maximilian Rehkopf (ikari_01) <otakon@gmx.net>
;   This software is part of the sd2snes project.
;
;   Last Modified: Oct. 2015 by Peter Bartmann <borti4938@gmx.de>
;
;   Based on reverse engineering work and disassembly by segher,
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
;   pin configuration: (cartridge pin) [key CIC pin]
;
;                       ,---_---.
;      +5V (27,58) [16] |1     8| GND (5,36) [8]
;      CIC clk (56) [6] |2     7| CIC data i/o 0 (55) [2]
;            status out |3     6| CIC data i/o 1 (24) [1]
;                 /PAIR |4     5| CIC slave reset (25) [7]
;                       `-------'
;
;
;   Status out can be connected to a LED. It indicates:
;
;   state                   | output
;  -------------------------+----------------------------
;   OK or no lock CIC       | high
;   error                   | low
;   SuperCIC pair mode      | 148.75kHz / 50% duty cycle
;   SuperCIC host detected  | scarce spikes (3.3us)
;    but pair mode disabled |
;
;   In case lockout fails, the region is switched automatically and
;   will be used after the next reset.
;
;   The /PAIR pin can be used to enable or disable SuperCIC pair mode.
;   It can be tied low or high to statically enable or disable pair mode
;   detection, or connected to a switch or MCU to dynamically enable pair
;   mode detection (it should then be connected to a pull-up resistor to
;   Vcc). Pair mode detection can be enabled during operation,
;   but pair mode cannot be left until the next power cycle.
;   See SuperCIC lock documentation for a more detailed description of
;   pair mode.
;
;   memory usage:
;
;   0x20		buffer for seed calc and transfer
;   0x21 - 0x2f		seed area (lock seed)
;   0x30		buffer for seed calc
;   0x31 - 0x3f		seed area (key seed; 0x31 filled in by lock)
;   0x40 - 0x41		buffer for seed calc
;   0x4d		buffer for eeprom access
;   0x4e		loop variable for longwait
;   0x4f		loop variable for wait
;   0x5c		GPIO buffer variable for pair mode allow
;   0x5d		0: SuperCIC pair mode available flag
;   0x5e                SuperCIC pair mode detect (phase 1)
;   0x5f                SuperCIC pair mode detect (phase 2)
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
isr
	org	0x0004
	bcf	INTCON, 1	; clear interrupt cause
	bcf	GPIO, 0
	bcf	GPIO, 1
	bsf	GPIO, 4		; LED on
	clrf	0x5e		; clear pair mode detect
	clrf	0x5f		; clear pair mode detect
	bsf	0x5f, 1		;
	clrf	0x5d		; clear pair mode available
	clrf	0x5c		; clear pair mode allow buffer
	bsf	0x5c, 3		; assume disallow
	bsf	INTCON, 7	; re-enable interrupts (ISR will continue as main)
	goto	main
init
	org 0x0010
	bcf	STATUS, RP0
	clrf	GPIO
	movlw	0x07	; GPIO2..0 are digital I/O (not connected to comparator)
	movwf	CMCON
	movlw	0x90	; global enable interrupts + enable external interrupt
	movwf	INTCON
	bsf	STATUS, RP0
	movlw	0x2d	; in out in in out in
	movwf	TRISIO
	movlw	0x24	; pullups for reset+clk to avoid errors when no CIC in host 
	movwf	WPU
	movlw	0x00	; 0x80 for global pullup disable
	movwf	OPTION_REG
	
	bcf	STATUS, RP0
	bsf 	GPIO, 4	; LED on
idle
	goto	idle	; wait for interrupt from lock

main
	bsf	STATUS, RP0
	bsf	TRISIO, 0
	bcf	TRISIO, 1
	bcf	STATUS, RP0
; --------INIT LOCK SEED (what the lock sends)--------
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
	
; --------INIT KEY SEED (what we must send)--------
	bsf	STATUS, RP0     ; D/F411 and D/F413
	clrf	EEADR		; differ in 2nd seed nibble
	bsf	EECON1, RD	; of key stream,
	movf	EEDAT, w	; restore saved nibble from EEPROM
	bcf	STATUS, RP0
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
	
; --------wait for stream ID--------
	movlw	0xb5
	call	wait
	clrf	0x31		; clear lock stream ID

; --------lock sends stream ID. 15 cycles per bit--------
;	bsf	GPIO, 0		; (debug marker)
;	bcf	GPIO, 0		; 
	btfsc	GPIO, 0		; check stream ID bit
	bsf	0x31, 3		; copy to lock seed
	movlw	0x2		; wait=3*W+5
	call	wait		; burn 11 cycles
	nop
	nop

;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	GPIO, 0		; check stream ID bit
	bsf	0x31, 0		; copy to lock seed
	movlw	0x2		;
	call	wait		; burn 11 cycles
	nop
	nop

;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	GPIO, 0		; check stream ID bit
	bsf	0x31, 1		; copy to lock seed
	movlw	0x2		;
	call	wait		; burn 11 cycles
	nop
	nop

;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	GPIO, 0		; check stream ID bit
	bsf	0x31, 2		; copy to lock seed
	bsf	STATUS, RP0
	bcf	TRISIO, 0
	bsf	TRISIO, 1
	bcf	STATUS, RP0
	movlw	0x27		; "wait" 1
	call	wait		; wait 121
; --------main loop--------
loop	
	movlw	0x1
loop0
	addlw	0x30	; key stream
	movwf	FSR	; store in index reg
loop1
	nop
	nop
	nop
	movf	INDF, w ; load seed value
	movwf	0x20
	bcf	0x20, 1	; clear bit 1 
	btfsc	0x20, 0 ; copy from bit 0
	bsf	0x20, 1 ; (if set)
	bsf	0x20, 4 ; LED on
	movf	0x20, w
	movwf	GPIO
	nop
	nop
	movlw	0x10
	movwf	GPIO	; reset GPIO
	movlw	0x13
	call	wait
	nop
	btfsc	0x5d, 0 ; pair mode available signal
	bcf	GPIO, 4 ;
	nop
	nop
	bsf	GPIO, 4 ;
	btfsc	GPIO, 0 ; both pins must be low...
	goto	die
	btfsc	GPIO, 1 ; ...when no bit transfer takes place
	goto	die		; if not -> lock cic error state -> die
	incf	FSR, f	; next one
	movlw	0xf
	andwf	FSR, w
	btfss	STATUS, Z	
	goto	loop1
	call	mangle
	call	mangle
	call	mangle
	movlw	0x2	; wait 10
	call	wait	;
	nop
	nop
	btfsc	0x37, 0
	goto	swap
	bsf	STATUS, RP0
	bcf	TRISIO, 0
	bsf	TRISIO, 1
	goto	swapskip
swap
	bsf	STATUS, RP0
	bsf	TRISIO, 0
	bcf	TRISIO, 1
	nop
swapskip
	bcf	STATUS, RP0
	movf	0x37, w
	andlw	0xf
	btfss	STATUS, Z
	goto	loop0
	goto	loop

; --------calculate new seeds--------
; had to be unrolled because PIC has an inefficient way of handling
; indirect access, no post increment, etc.
mangle
	call	mangle_lock
	movf	GPIO, w	; buffer GPIO state
	movwf	0x5c	; for pair mode "transaction"
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
	movwf	0x41	; store 23 to 41
	movlw	0xf
	andwf	0x23, f
	movf	0x40, w ; add 40(22 old)+23+#1 and skip if carry
	andlw	0xf
	addwf	0x23, f
	incf	0x23, f
	btfsc	0x23, 4
	goto	mangle_key_withskip
mangle_key_withoutskip
	movf	0x41, w ; restore 23
	addwf	0x24, f ; add to 24
	movf	0x25, w
	movwf	0x40	; save 25 to 40
	movf	0x24, w
	addwf	0x25, f
	movf	0x26, w
	movwf	0x41	; save 26 to 41
	movf	0x40, w ; restore 25
	andlw	0xf	; mask nibble
	addlw	0x8	; add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 ; skip if carry to 5th bit
	addwf	0x26, w
	movwf	0x26

	movf	0x41, w ; restore 26
	addlw	0x1	; inc
	addwf	0x27, f	; add to 27

	movf	0x27, w ;
	addlw	0x1	; inc
	addwf	0x28, f ; add to 28

	movf	0x28, w ;
	addlw	0x1	; inc
	addwf	0x29, f ; add to 29

	movf	0x29, w ;
	addlw	0x1	; inc
	addwf	0x2a, f ; add to 2a

	movf	0x2a, w ;
	addlw	0x1	; inc
	addwf	0x2b, f ; add to 2b

	movf	0x2b, w ;
	addlw	0x1	; inc
	addwf	0x2c, f ; add to 2c

	movf	0x2c, w ;
	addlw	0x1	; inc
	addwf	0x2d, f ; add to 2d

	movf	0x2d, w ;
	addlw	0x1	; inc
	addwf	0x2e, f ; add to 2e

	movf	0x2e, w ;
	addlw	0x1	; inc
	addwf	0x2f, f ; add to 2f

	movf	0x20, w ; restore original 0xf
	andlw	0xf
	addlw	0xf
	movwf	0x20

	btfsc	0x5d, 0 ; pair mode available signal
	bcf	GPIO, 4
	nop
	nop
	bsf	GPIO, 4

	nop
	nop
	nop
	nop
	btfss	0x20, 4 ; skip if half-byte carry
	goto mangle_return ; +2 cycles in return
	nop
	goto mangle_key_loop
; 69 when goto, 69 when return
; CIC has 78 -> 9 nops

mangle_key_withskip
	movf	0x41, w ; restore 23
	addwf	0x23, f ; add to 23
	movf	0x24, w
	movwf	0x40	; save 24 to 40
	movf	0x23, w
	addwf	0x24, f
	movf	0x25, w
	movwf	0x41	; save 25 to 41
	movf	0x40, w ; restore 24
	andlw	0xf	; mask nibble
	addlw	0x8	; add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 ; skip if carry to 5th bit
	addwf	0x25, w
	movwf	0x25

	movf	0x41, w ; restore 25
	addlw	0x1	; inc
	addwf	0x26, f	; add to 26

	movf	0x26, w ;
	addlw	0x1	; inc
	addwf	0x27, f ; add to 27

	movf	0x27, w ;
	addlw	0x1	; inc
	addwf	0x28, f ; add to 28

	movf	0x28, w ;
	addlw	0x1	; inc
	addwf	0x29, f ; add to 29

	movf	0x29, w ;
	addlw	0x1	; inc
	addwf	0x2a, f ; add to 2a

	movf	0x2a, w ;
	addlw	0x1	; inc
	addwf	0x2b, f ; add to 2b

	movf	0x2b, w ;
	addlw	0x1	; inc
	addwf	0x2c, f ; add to 2c

	movf	0x2c, w ;
	addlw	0x1	; inc
	addwf	0x2d, f ; add to 2d

	movf	0x2d, w ;
	addlw	0x1	; inc
	addwf	0x2e, f ; add to 2e

	movf	0x2e, w ;
	addlw	0x1	; inc
	addwf	0x2f, f ; add to 2f

	movf	0x20, w ; restore original 0xf
	andlw	0xf
	addlw	0xf
	movwf	0x20
;-------pair mode code-------
	bcf	GPIO, 0
	movf	GPIO, w
	btfss	0x5c, 3
	bsf	GPIO, 0
	movwf	0x5e
	movf	GPIO, w
	movwf	0x5f
	bcf	GPIO, 0

	btfsc	0x5d, 0 ; pair mode available signal
	bcf	GPIO, 4
	bsf	GPIO, 4
;-------end of pair mode code-------
	btfss	0x20, 4 ; skip if half-byte carry
	goto mangle_return ; +2 cycles in return
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
	movwf	0x41	; store 33 to 41
	movlw	0xf
	andwf	0x33, f
	movf	0x40, w ; add 40(32 old)+33+#1 and skip if carry
	andlw	0xf
	addwf	0x33, f
	incf	0x33, f
	btfsc	0x33, 4
	goto	mangle_lock_withskip
mangle_lock_withoutskip
	movf	0x41, w ; restore 33
	addwf	0x34, f ; add to 34
	movf	0x35, w
	movwf	0x40	; save 35 to 40
	movf	0x34, w
	addwf	0x35, f
	movf	0x36, w
	movwf	0x41	; save 36 to 41
	movf	0x40, w ; restore 35
	andlw	0xf	; mask nibble
	addlw	0x8	; add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 ; skip if carry to 5th bit
	addwf	0x36, w
	movwf	0x36

	movf	0x41, w ; restore 36
	addlw	0x1	; inc
	addwf	0x37, f	; add to 37

	movf	0x37, w ;
	addlw	0x1	; inc
	addwf	0x38, f ; add to 38

	movf	0x38, w ;
	addlw	0x1	; inc
	addwf	0x39, f ; add to 39

	movf	0x39, w ;
	addlw	0x1	; inc
	addwf	0x3a, f ; add to 3a

	movf	0x3a, w ;
	addlw	0x1	; inc
	addwf	0x3b, f ; add to 3b

	movf	0x3b, w ;
	addlw	0x1	; inc
	addwf	0x3c, f ; add to 3c

	movf	0x3c, w ;
	addlw	0x1	; inc
	addwf	0x3d, f ; add to 3d

	movf	0x3d, w ;
	addlw	0x1	; inc
	addwf	0x3e, f ; add to 3e

	movf	0x3e, w ;
	addlw	0x1	; inc
	addwf	0x3f, f ; add to 3f

	movf	0x30, w ; restore original 0xf
	andlw	0xf
	addlw	0xf
	movwf	0x30

	btfsc	0x5d, 0 ; pair mode available signal
	bcf	GPIO, 4
	nop
	nop
	bsf	GPIO, 4

	nop
	nop
	nop
	nop
	btfss	0x30, 4 ; skip if half-byte carry
	goto mangle_return
	nop
	goto mangle_lock_loop
; 69 when goto, 69 when return
; CIC has 78 -> 9 nops
	
mangle_lock_withskip
	movf	0x41, w ; restore 33
	addwf	0x33, f ; add to 33
	movf	0x34, w
	movwf	0x40	; save 34 to 40
	movf	0x33, w
	addwf	0x34, f
	movf	0x35, w
	movwf	0x41	; save 35 to 41
	movf	0x40, w ; restore 34
	andlw	0xf	; mask nibble
	addlw	0x8	; add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 ; skip if carry to 5th bit
	addwf	0x35, w
	movwf	0x35

	movf	0x41, w ; restore 35
	addlw	0x1	; inc
	addwf	0x36, f	; add to 36

	movf	0x36, w ;
	addlw	0x1	; inc
	addwf	0x37, f ; add to 37

	movf	0x37, w ;
	addlw	0x1	; inc
	addwf	0x38, f ; add to 38

	movf	0x38, w ;
	addlw	0x1	; inc
	addwf	0x39, f ; add to 39

	movf	0x39, w ;
	addlw	0x1	; inc
	addwf	0x3a, f ; add to 3a

	movf	0x3a, w ;
	addlw	0x1	; inc
	addwf	0x3b, f ; add to 3b

	movf	0x3b, w ;
	addlw	0x1	; inc
	addwf	0x3c, f ; add to 3c

	movf	0x3c, w ;
	addlw	0x1	; inc
	addwf	0x3d, f ; add to 3d

	movf	0x3d, w ;
	addlw	0x1	; inc
	addwf	0x3e, f ; add to 3e

	movf	0x3e, w ;
	addlw	0x1	; inc
	addwf	0x3f, f ; add to 3f

	movf	0x30, w ; restore original 0xf
	andlw	0xf
	addlw	0xf
	movwf	0x30
;-------pair mode code-------
	btfss	0x5e, 1
	goto	scic_pair_skip1
	btfsc	0x5f, 1
	goto	scic_pair_skip2
	btfsc	0x5c, 3
	goto	scic_pair_skip3
	goto	supercic_pairmode
scic_pair_skip1
	nop
	nop
scic_pair_skip2
	nop
	nop
	nop
	nop
	goto scic_pair_skip4
scic_pair_skip3	
	bcf	GPIO, 4
	bsf	0x5d, 0 ; set pair mode available
	nop
	bsf	GPIO, 4
 
scic_pair_skip4
;-------end of pair mode code-------
	btfss	0x30, 4 ; skip if half-byte carry
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

; --------change region in eeprom and die--------
die
	movlw	0x3a		;wait 50ms before writing
	call	longwait	;("error" might be due to power loss)
	bsf	STATUS, RP0
	clrw
	movwf	EEADR
	bsf	EECON1, RD
	movf	EEDAT, w
	bcf	STATUS, RP0
	movwf	0x4d
	btfsc	0x4d, 0
	goto	die_reg_6
die_reg_9
	movlw	0x9	; died with PAL, fall back to NTSC
	goto	die_reg_cont
die_reg_6
	movlw	0x6	; died with NTSC, fall back to PAL
die_reg_cont
	bsf	STATUS, RP0
	movwf	EEDAT
	bsf	EECON1, WREN

die_intloop
	bcf	INTCON, GIE
	btfsc	INTCON, GIE
	goto	die_intloop
	
	movlw	0x55
	movwf	EECON2
	movlw	0xaa
	movwf	EECON2
	bsf	EECON1, WR
	bsf	INTCON, GIE

	bcf	STATUS, RP0
	bcf	GPIO, 4
; --------get caught up--------
die_trap
	goto	die_trap
; -----------------------------------------------------------------------
supercic_pairmode
	bsf	STATUS, RP0
	bsf	TRISIO, 0
	bsf	TRISIO, 1
	bcf	STATUS, RP0
supercic_pairmode_loop
	bsf	GPIO, 4
	nop
	nop
	bcf	GPIO, 4
	goto	supercic_pairmode_loop

; eeprom memory
 org __EEPROM_START
	de      0x09	; D411 (NTSC)
 end
