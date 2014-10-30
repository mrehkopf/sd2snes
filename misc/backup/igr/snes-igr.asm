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
;                        In SuperCIC mode this actually issues a reset
;                        "doubleclick" to trigger the SuperCIC's long reset
;                        function.
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

#define SERIAL_DATA     0
#define DATA_LATCH      1
#define DATA_CLK        2
#define SCIC_MODE_IN    3
#define MODE_OUT        4
#define RESET_OUT       5

#define LED_MODE_50_IN  0
#define LED_MODE_60_IN  1
#define SCIC_PRESENT_IN 2
#define LED_TYPE_IN     3

#define bit_scic_present    1
#define bit_scic_passthru   1

#define reg_ctrl_data_lsb   0x20
#define reg_ctrl_data_msb   0x21
#define reg_ctrl_data_cnt   0x22
#define reg_scic_passthru   0x23
#define reg_scic_present    0x24

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
    call 3FFh               ; Get the osccal value
;    movlw 0xfc             ; load '11111100' to set the OSCCAL to maximum
    movwf OSCCAL            ; Calibrate
    movlw   0x2f            ; in out in in in in
    movwf   TRISA
    movlw   0x0f            ; out out in in in in
    movwf   TRISC
    movlw   0x00            ; no pullups
    movwf   WPUA
    movlw   0x80            ; global pullup disable
    movwf   OPTION_REG
	banksel	PORTA
	bsf	PORTA, RESET_OUT

;	tits	GTFO

	clrf	reg_scic_present
	btfsc	PORTC, SCIC_PRESENT_IN
	bsf     reg_scic_present, bit_scic_present

	clrf	reg_scic_passthru
	btfss	reg_scic_present, bit_scic_present      ; SuperCIC absent?
	goto	doregion_60                             ; then set defaults
	
	bsf     reg_scic_passthru, bit_scic_passthru    ; else enable passthru

idle
; check region passthru
	btfss	reg_scic_passthru, bit_scic_passthru    ; passthru enabled?
	goto	waitforlatch_h	; 
	btfsc	PORTA, SCIC_MODE_IN
	bsf     PORTA, MODE_OUT
	btfss	PORTA, SCIC_MODE_IN
	bcf     PORTA, MODE_OUT
	call	setleds_passthru
waitforlatch_h	; wait for "latch" to become high
	btfss	PORTA, DATA_LATCH
	goto	idle


waitforlatch_l	; wait for "latch" to become low
	btfsc	PORTA, DATA_LATCH
	goto	waitforlatch_l


	clrf	reg_ctrl_data_lsb
	clrf	reg_ctrl_data_msb
	clrf	reg_ctrl_data_cnt
	bcf     STATUS, C	; clear carry

dl1_init ; first data is read on the first falling edge
	btfsc   PORTA, DATA_CLK ; wait for "clk" to become low
	goto    dl1_init
dl1
	movf	PORTA, w                ; read data bit
	rlf     reg_ctrl_data_msb, f	; shift
	andlw	0x1	
	iorwf	reg_ctrl_data_msb, f	; put in data reg
	incf	reg_ctrl_data_cnt, f	; inc bit count
dl1_wait
	btfss	PORTA, DATA_CLK         ; wait for clk=h
	goto	dl1_wait
	btfss	reg_ctrl_data_cnt, 3	; first byte done?
	goto	dl1
	clrf	reg_ctrl_data_cnt
dl2
	movf	PORTA, w                ; read data bit
	rlf     reg_ctrl_data_lsb, f	; shift
	andlw	0x1	
	iorwf	reg_ctrl_data_lsb, f	; put in data reg
	incf	reg_ctrl_data_cnt, f	; inc bit count
dl2_wait
	btfss	PORTA, DATA_CLK         ; wait for clk=h
	goto	dl2_wait
	btfss	reg_ctrl_data_cnt, 2	; read only 4 bits
	goto	dl2


	

checkkeys
; we now have the first 8 bits in 0x20 and the second 4 bits in 0x21
	; 00011111 00011111 = ABXY, Select, L
	movlw	0x04
	xorwf	reg_ctrl_data_lsb, w
	btfsc	STATUS, Z
	goto	group04
	movlw	0x08
	xorwf	reg_ctrl_data_lsb, w
	btfsc	STATUS, Z
	goto	group08
	movlw	0x0c
	xorwf	reg_ctrl_data_lsb, w
	btfsc	STATUS, Z
	goto	group0c
	goto	idle

group04
	movlw	0xdf
	xorwf	reg_ctrl_data_msb, w
	btfss	STATUS, Z
	goto	idle
	goto	doregion_60

group08
	movlw	0xdf
	xorwf	reg_ctrl_data_msb, w
	btfss	STATUS, Z
	goto	idle
	btfss	0x24, bit_scic_present  ; SuperCIC absent?
	goto	doreset_long            ; then do long reset
	goto	doreset_dbl             ; else do dbl reset

group0c
	movlw	0x5f
	xorwf	reg_ctrl_data_msb, w
	btfsc	STATUS, Z
	goto	doregion_passthru
	movlw	0x9f
	xorwf	reg_ctrl_data_msb, w
	btfsc	STATUS, Z
	goto	doregion_50
	movlw	0xcf
	xorwf	reg_ctrl_data_msb, w
	btfsc	STATUS, Z
	goto	doreset_normal
	goto	idle

doreset_normal
	banksel	TRISA
	bcf     TRISA, RESET_OUT
	banksel	PORTA
	bsf     PORTA, RESET_OUT
	movlw	0x15
	call	longwait
	banksel TRISA
	bsf     TRISA, RESET_OUT
	banksel	PORTA
	goto	idle

doreset_dbl
	banksel	TRISA
	bcf     TRISA, RESET_OUT
	banksel	PORTA
	bsf     PORTA, RESET_OUT
	movlw	0x15
	call	longwait
	banksel	TRISA
	bsf     TRISA, RESET_OUT
	clrw
	call	longwait
	bcf     TRISA, RESET_OUT
	movlw	0x15
	call	longwait
	banksel	TRISA
	bsf     TRISA, RESET_OUT
	banksel	PORTA
	goto	idle

doreset_long
	banksel	TRISA
	bcf     TRISA, RESET_OUT
	banksel	PORTA
	bsf     PORTA, RESET_OUT
	movlw	0x1a
	call	superlongwait
	banksel	TRISA
	bsf     TRISA, RESET_OUT
	banksel	PORTA
	goto	idle

doregion_50
	bsf     PORTA, MODE_OUT
	clrf	reg_scic_passthru
	call	setleds_own
	goto	idle

doregion_60
	bcf     PORTA, MODE_OUT
	clrf	reg_scic_passthru
	call	setleds_own
	goto	idle

doregion_passthru
	clrf	reg_scic_passthru
	btfsc	reg_scic_present, bit_scic_present      ; SuperCIC present?
	bsf     reg_scic_passthru, bit_scic_passthru    ; then enable passthru
	goto	idle

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
	btfss	reg_scic_passthru, bit_scic_passthru
	goto	setleds_own
setleds_passthru
	clrw
	btfsc	PORTC, LED_MODE_50_IN	; green LED
	iorlw	0x20
	btfsc	PORTC, LED_MODE_60_IN	; red LED
	iorlw	0x10
	movwf	PORTC
	return

setleds_own
	movlw	0x20                ; assume green LED
	btfss	PORTA, MODE_OUT
	movlw	0x10                ; if PORTA.4 is low -> red LED
	btfsc	PORTC, LED_TYPE_IN	; if common anode:
	xorlw	0x30                ; invert output
	movwf	PORTC	
	return
END
