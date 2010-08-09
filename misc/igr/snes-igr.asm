    #include <p16f630.inc>

; -----------------------------------------------------------------------
;   SNES "In-game reset" (IGR) controller
;
;   Copyright (C) 2010 by Maximilian Rehkopf <otakon@gmx.net>
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
; -----------------------------------------------------------------------
;
;   This program is designed to run on a PIC 16F630 microcontroller connected
;   to the controller port and SNES main board. It allows an SNES to be reset
;   and region switched via a standard controller.
;
;   pin configuration: (controller port pin) [other connection]
;                                              ,-----_-----.
;                                      +5V (1) |1        14| GND (7)
;   Reset out [to CIC pin 8 / SuperCIC pin 13] |2  A5 A0 13| serial data in(4)
;                        50/60Hz out [to PPUs] |3  A4 A1 12| latch in(3)
;            50/60Hz in [from SuperCIC pin 12] |4  A3 A2 11| clk in(2)
;                                LED out - grn |5  C5 C0 10| LED in - grn [from SuperCIC pin 5]
;                                LED out - red |6  C4 C1  9| LED in - red [from SuperCIC pin 6]
;                                  LED_TYPE in |7  C3 C2  8| SuperCIC present
;                                              `-----------'
;
;   Pin 4 should be connected to SuperCIC pin 12 if a SuperCIC is used.
;
;   Pin 7 (LED_TYPE) sets the output mode for the LED pins
;   (must be tied to either level):
;      low  = common cathode
;      high = common anode   (output inverted)
;
;   Pin 8 should be connected as follows:
;      low = no SuperCIC present
;      high = SuperCIC present
;
;   controller pin numbering
;   ========================
;        _______________________________
;       |                 |             \
;       | (1) (2) (3) (4) | (5) (6) (7)  )
;       |_________________|_____________/
;
;
;   key mapping: L + R + Select +                               (stream data)
;   =============================
;   Start       Reset (normal)                                  0xcf 0xcf
;   X           Reset (6s)                                      0xdf 0x8f
;
;   Y           Region 50Hz/PAL                                 0x9f 0xcf
;   A           Region 60Hz/NTSC                                0xdf 0x4f
;   B           Region from SuperCIC (SuperCIC only)            0x5f 0xcf
;
;   functional description:
;   =======================
;   Reset (normal):      simply resets the console.
;   Reset (6s):          resets the console for >5s to enter main menu on
;                        PowerPak and sd2snes.
;
;   Region 50Hz/PAL      overrides the region to 50Hz/PAL.
;   Region 60Hz/NTSC     overrides the region to 60Hz/NTSC.
;   Region from SuperCIC sets the region according to the input level of
;                        pin 4 (+5V = 50Hz, 0V = 60Hz). In this mode the
;                        region is updated constantly.
;                        This function is only available in SuperCIC mode
;                        (pin 8 = 5V).
;
; -----------------------------------------------------------------------
; Configuration bits: adapt to your setup and needs
    __CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _BODEN & _CP_OFF & _CPD_OFF

; -----------------------------------------------------------------------
; relocatable code
PROG CODE
start
        banksel PORTA
        clrf    PORTA
        movlw   0x07            ; PORTA2..0 are digital I/O (not connected to comparator)
        movwf   CMCON
        movlw   0x00            ; disable all interrupts
        movwf   INTCON
        banksel TRISA
        movlw   0x2f            ; in out in in in in
        movwf   TRISA
        movlw   0x0f            ; out out in in in in
        movwf   TRISC
        movlw   0x00            ; no pullups
        movwf   WPUA
        movlw   0x80            ; global pullup disable
        movwf   OPTION_REG
	banksel	PORTA
	bsf	PORTA, 5

;	tits	GTFO

	clrf	0x24
	btfsc	PORTC, 2
	bsf	0x24, 1

	clrf	0x23
	btfss	0x24, 1		; SuperCIC present?
	bsf	0x23, 1		; then enable passthru

	goto	doregion_60	; set defaults

waitforlatch_h	; wait for "latch" to become high 
	btfss	PORTA, 1
	goto	waitforlatch_h


waitforlatch_l	; wait for "latch" to become low
	btfsc	PORTA, 1
	goto	waitforlatch_l


	clrf	0x20
	clrf	0x21
	clrf	0x22
	bcf	STATUS, C	; clear carry
dl1
	movf	PORTA, w		;read data bit
	rlf	0x20, f		;shift
	andlw	0x1	
	iorwf	0x20, f		;put in data reg
	incf	0x22, f		;inc bit count
dl1_wait
	btfss	PORTA, 2		;wait for clk=h
	goto	dl1_wait
	btfss	0x22, 3		;first byte done?
	goto	dl1
	bcf	STATUS, C	; clear carry
dl2
	movf	PORTA, w		;read data bit
	rlf	0x21, f		;shift
	andlw	0x1	
	iorwf	0x21, f		;put in data reg
	incf	0x22, f		;inc bit count
dl2_wait
	btfss	PORTA, 2		;wait for clk=h
	goto	dl2_wait
	btfss	0x22, 4
	goto	dl2

; check region passthru
	btfss	0x23, 1		; passthru enabled?
	goto	checkkeys	; 
	btfsc	PORTA, 3
	bsf	PORTA, 4
	btfss	PORTA, 3
	bcf	PORTA, 4
	call	setleds_passthru
	

checkkeys
; we now have the first 8 bits in 0x20 and the second 8 bits in 0x21
	; 00011111 00011111 = ABXY, Select, L
	movlw	0x4f
	xorwf	0x21, w
	btfsc	STATUS, Z
	goto	group4f
	movlw	0x8f
	xorwf	0x21, w
	btfsc	STATUS, Z
	goto	group8f
	movlw	0xcf
	xorwf	0x21, w
	btfsc	STATUS, Z
	goto	groupcf
	goto	waitforlatch_h

group4f
	movlw	0xdf
	xorwf	0x20, w
	btfss	STATUS, Z
	goto	waitforlatch_h
	goto	doregion_60

group8f
	movlw	0xdf
	xorwf	0x20, w
	btfss	STATUS, Z
	goto	waitforlatch_h
	btfss	0x24, 1		; SuperCIC absent?
	goto	doreset_long	; then do long reset
	goto	doreset_dbl	; else do dbl reset

groupcf
	movlw	0x5f
	xorwf	0x20, w
	btfsc	STATUS, Z
	goto	doregion_passthru
	movlw	0x9f
	xorwf	0x20, w
	btfsc	STATUS, Z
	goto	doregion_50
	movlw	0xcf
	xorwf	0x20, w
	btfsc	STATUS, Z
	goto	doreset_normal
	goto	waitforlatch_h

doreset_normal
	banksel	TRISA
	bcf	TRISA, 5
	banksel	PORTA
	bsf	PORTA, 5
	movlw	0x15
	call	longwait
	banksel TRISA
	bsf	TRISA, 5
	banksel	PORTA
	goto	waitforlatch_h

doreset_dbl
	banksel	TRISA
	bcf	TRISA, 5
	banksel	PORTA
	bsf	PORTA, 5
	movlw	0x15
	call	longwait
	banksel	TRISA
	bsf	TRISA, 5
	clrw
	call	longwait
	bcf	TRISA, 5
	movlw	0x15
	call	longwait
	banksel	TRISA
	bsf	TRISA, 5
	banksel	PORTA
	goto	waitforlatch_h

doreset_long
	banksel	TRISA
	bcf	TRISA, 5
	banksel	PORTA
	bsf	PORTA, 5
	movlw	0x1e
	call	superlongwait
	banksel	TRISA
	bsf	TRISA, 5
	banksel	PORTA
	goto	waitforlatch_h

doregion_50
	bsf	PORTA, 4
	clrf	0x23
	call	setleds_own
	goto	waitforlatch_h

doregion_60
	bcf	PORTA, 4
	clrf	0x23
	call	setleds_own
	goto	waitforlatch_h

doregion_passthru
	clrf	0x23
	btfsc	0x24, 1		; SuperCIC present?
	bsf	0x23, 1		; then enable passthru
	goto	waitforlatch_h

; --------wait: 3*(W-1)+7 cycles (including call+return). W=0 -> 256!--------
wait
        movwf   0x2f
wait0   decfsz  0x2f, f
        goto    wait0
        goto	longwait1

; --------wait long: 8+(3*(w-1))+(772*w). W=0 -> 256!--------
longwait
        movwf   0x2e
        clrw
longwait0
        goto	wait
longwait1
        decfsz  0x2e, f
        goto    longwait0
        return

; --------wait extra long: 8+(3*(w-1))+(198405*w).
superlongwait
	movwf	0x2d
	clrw
superlongwait0
	call	longwait
	decfsz	0x2d, f
	goto	superlongwait0
	return

setleds
	btfss	0x24, 1
	goto	setleds_own
setleds_passthru
	clrw
	btfsc	PORTC, 0	; green LED	
	iorlw	0x20
	btfsc	PORTC, 1	; red LED
	iorlw	0x10
	movwf	PORTC
	return

setleds_own
	movlw	0x20		; assume green LED
	btfss	PORTA, 4
	movlw	0x10		; if PORTA.4 is low -> red LED
	btfsc	PORTC, 3	; if common anode:
	xorlw	0x30		; invert output
	movwf	PORTC	
	return
END
