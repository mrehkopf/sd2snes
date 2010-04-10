    #include <p12f629.inc>
processor p12f629

; ---------------------------------------------------------------------
;   SNES CIC clone for PIC Microcontroller (lock mode, auto key detect,
;   error tolerant)
;
;   Copyright (C) 2010 by Maximilian Rehkopf (ikari_01) <otakon@gmx.net>
;   This software is part of the sd2snes project.
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
;
;                       ,---_---.
;      +5V (27,58) [18] |1     8| GND (5,36) [9]
;      CIC clk (56) [7] |2     7| CIC data i/o 0 (55) [1]
;   host reset out [10] |3     6| CIC data i/o 1 (24) [2]
; CIC lock reset in [8] |4     5| CIC slave reset out (25) [11]
;                       `-------'
;
;   pin 3 connected to PPU2 reset in
;   pin 4 connected to reset button
;
;
;   host reset out behaves as follows:
;   after powerup it is held low for a couple of us to properly allow the
;   components to power-up.
;   it is then asserted a high level even if the CIC "auth" should fail at
;   any point, thus enabling homebrew or other cartridges without a CIC or
;   CIC clone to be run properly, while maintaining compatibility with CIC
;   demanding cartridges like S-DD1 or SA-1 powered ones.
;   The region of the key CIC is detected automatically.
;
;   memory usage:
;
;   0x20		buffer for seed calc and transfer
;   0x21 - 0x2f		seed area (lock seed)
;   0x30		buffer for seed calc
;   0x31 - 0x3f		seed area (key seed; 0x31 filled in by lock)
;   0x40 - 0x41		buffer for seed calc
;   0x42		input buffer
;   0x43		variable for key detect
;   0x4d		buffer for eeprom access
;   0x4e		loop variable for longwait
;   0x4f		loop variable for wait
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
rst				; we jump here after powerup or GPIO3=1
	org	0x0004
	bcf	GPIO, 0		; clear stream i/o
	bcf	GPIO, 1		; clear stream i/o
	bcf	GPIO, 2		; disable slave reset
	bcf	GPIO, 4		; hold the SNES in reset
rst_loop
	btfsc	GPIO, 3		; stay in "reset" as long as GPIO3=1
	goto	rst_loop
	nop
	nop
	nop
	nop
	nop
	goto	main
init
	org 0x0010
	banksel GPIO
	clrf	GPIO
	movlw	0x07	; GPIO2..0 are digital I/O (not connected to comparator)
	movwf	CMCON
	movlw	0x00	; disable all interrupts
	movwf	INTCON
	banksel	TRISIO
	movlw	0x29	; in out in OUT out in. slave reset is an output on lock
	movwf	TRISIO
	movlw	0x08	; pullups for clk to avoid errors when no CIC in slave 
	movwf	WPU
	movlw	0x00	; 0x80 for global pullup disable.
	movwf	OPTION_REG
	
	banksel GPIO
	bcf 	GPIO, 4	; LED off
	goto	rst
main
	movlw	0x2	; wait a bit before initializing the slave + console
	call	longwait

	bsf	GPIO, 4 ; enable console
	
	bsf	GPIO, 2 ; trigger the slave
	nop
	nop
	bcf	GPIO, 2 	

	banksel	TRISIO
	bcf	TRISIO, 0
	bsf	TRISIO, 1
	banksel	GPIO
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
	movlw	0xf	; we always request the same stream for simplicity
	movwf	0x31
	movlw	0x0	; this is filled in by key autodetect
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
	nop
	nop

; --------lock sends stream ID. 15 cycles per bit--------
;	bsf	GPIO, 0		; (debug marker)
;	bcf	GPIO, 0		; 
	btfsc	0x31, 3		; read stream select bit
	bsf	GPIO, 0		; send bit
	nop
	nop
	bcf	GPIO, 0
	movlw	0x1		; wait=7
	call	wait		; burn 10 cycles
	nop
	nop

;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	0x31, 0		; read stream select bit
	bsf	GPIO, 0		; send bit
	nop
	nop
	bcf	GPIO, 0
	movlw	0x1		; wait=3*W+5
	call	wait		; burn 11 cycles
	nop
	nop

;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	0x31, 1		; read stream select bit
	bsf	GPIO, 0		; send bit
	nop
	nop
	bcf	GPIO, 0
	movlw	0x1		; wait=3*W+5
	call	wait		; burn 11 cycles
	nop
	nop

;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	0x31, 2		; read stream select bit
	bsf	GPIO, 0		; send bit
	nop
	nop
	bcf	GPIO, 0
	movlw	0x1		; wait=3*0+7
	call	wait		; burn 10 cycles
	banksel	TRISIO
	bsf	TRISIO, 0
	bcf	TRISIO, 1
	banksel	GPIO
	movlw	0x24		; "wait" 1
	call	wait		; wait 112
	nop
	movlw	0x1		; 'first time' bit
	movwf	0x43		; for key detection
; --------main loop--------
loop	
	movlw	0x1
loop0
	addlw	0x20	; lock stream
	movwf	FSR	; store in index reg
loop1
	movf	INDF, w ; load seed value
	movwf	0x20
	bcf	0x20, 1	; clear bit 1 
	btfsc	0x20, 0 ; copy from bit 0
	bsf	0x20, 1 ; (if set)
	bsf	0x20, 4 ; run console
	bcf	0x20, 2 ; run slave
	movf	0x20, w
	movwf	GPIO
	movf	GPIO, w ; read input
	movwf	0x42	; store input
	movlw	0x10
	movwf	GPIO	; reset GPIO
	call	checkkey	
	movlw	0x10	; wait 52 cycles
	call	wait
	btfsc	GPIO, 0 ; both pins must be low...
	goto	die
	btfsc	GPIO, 1 ; ...when no bit transfer takes place
	goto	die	; if not -> lock cic error state -> die
	incf	FSR, f	; next one
	movlw	0xf
	andwf	FSR, w
	btfss	STATUS, Z	
	goto	loop1
	movlw	0x1	; wait 7
	call	wait	;
	nop
	nop
	call	mangle
	call	mangle
	call	mangle
	btfsc	0x37, 0
	goto	swap
	banksel	TRISIO
	bsf	TRISIO, 0
	bcf	TRISIO, 1
	goto	swapskip
swap
	banksel	TRISIO
	bcf	TRISIO, 0
	bsf	TRISIO, 1
	nop
swapskip
	banksel GPIO
	btfsc	GPIO, 3 ; poll master reset
	goto	rst
	clrf	0x43	; don't check key region anymore
	movf	0x37, w
	andlw	0xf
	btfss	STATUS, Z
	goto	loop0
	goto	loop

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
	nop
	nop
	nop
	nop
	nop
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
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	btfss	0x20, 4 ; skip if half-byte carry
	goto mangle_return ; +2 cycles in return
	nop
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
	nop
	nop
	nop
	nop
	nop
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
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
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

; --------die (do nothing, wait for reset)--------
die
	btfsc	GPIO, 3
	goto	rst
	goto	die

; --------check the key input and change "region" when appropriate--------
; --------requires 17 cycles (incl. call+return)
checkkey
	btfss	0x43, 0			; first time?
	goto 	checkkey_nocheck	; if not, just burn some cycles
	movlw	0x22			; are we at the correct stream offset?
	xorwf	FSR, w
	btfss	STATUS, Z		; if not equal:
	goto	checkkey_nocheck2	; burn some cycles less.
					; if equal do the check
	btfss	0x42, 0			; if value from slave is set it's a 411
	goto	check_413
check_411
	nop				; to compensate for untaken branch
	movlw	0x9
	goto	check_save
check_413
	movlw	0x6
	goto	check_save

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
	goto check_done
check_save
	movwf	0x32
check_done
	return
end
; ------------------------------------------------------------------------
