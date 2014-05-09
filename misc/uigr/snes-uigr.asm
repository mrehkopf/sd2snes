    #include <p16f630.inc>

; -----------------------------------------------------------------------
;   SNES "In-game reset" (IGR) controller for use with the SuperCIC only
;
;   Copyright (C) 2010 by Maximilian Rehkopf <otakon@gmx.net>
;
;   Last Modified: January 2014 by Peter Bartmann <peter.bartmann@gmx.de>
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
;   and region switched via a standard controller. This version of the code
;   shall be used only in combination with the SCIC!
;
;   pin configuration: (controller port pin) [other connection]
;
;                                                 ,-----_-----.
;        +5V (1) [mb front 1 and many others :-)] |1        14| GND (7) [mb front 11 and many others :-)]
;   Reset in/out [to CIC pin 8 / SuperCIC pin 13] |2  A5 A0 13| serial data in(4) [mb front 6]
;                           50/60Hz out [to PPUs] |3  A4 A1 12| latch in(3)       [mb front 10]
;               Cart-Region [from SuperCIC pin 3] |4  A3 A2 11| clk in(2)         [mb front 8]
;                        LED out - grn, 50Hz Mode |5  C5 C0 10| LED in - grn [from SuperCIC pin 5]
;                        LED out - red, 60Hz Mode |6  C4 C1  9| LED in - red [from SuperCIC pin 6]
;                       $213f-D4-Patch enable out |7  C3 C2  8| LED_TYPE in  [from SuperCIC pin 7]
;                                                 `-----------'
;
;   Pin 7 can be left open if no $213f-D4-Patch is build in the console.
;   Otherwise this pin has to be connected to one input of the 74*133 IC of the
;   patch.
;
;   Pin 8 (LED_TYPE) sets the output mode for the LED pins
;   (must be tied to either level):
;      low  = common cathode
;      high = common anode   (output inverted)
;
;
;   As the internal oscillator is used, you should connect a capacitor of about 100nF between
;   Pin 1 (Vdd/+5V) and Pin 14 (Vss/GND) as close as possible to the PIC. This esures best
;   operation
;
;   controller pin numbering
;   ========================
;        _______________________________
;       |                 |             \
;       | (1) (2) (3) (4) | (5) (6) (7)  )
;       |_________________|_____________/
;
;
;   key mapping: L + R + Select +                                (stream data)
;   =============================
;   Start        Reset (normal)                                  0xcf 0xcf
;   X            Reset (double)                                  0xdf 0x8f
;
;   Y            Region 50Hz/PAL                                 0x9f 0xcf
;   A            Region 60Hz/NTSC                                0xdf 0x4f
;   B            Region from Cartridge                           0x5f 0xcf
;   Left-Arrow   Region from SCIC                                0xdd 0xcf
;   Right-Arrow  Region from SCIC   	                         0xde 0xcf
;
;   Up-Arrow     Toggle the region timeout                       0xd7 0xcf
;   Down-Arrow   Toggle $213f-D4-Patch enable/disable            0xdb 0xcf
;
;
;   functional description:
;   =======================
;   Reset (normal):        simply resets the console.
;   Reset (double):        resets the console twice to enter main menu on
;                          PowerPak (due to initilize a long reset at SCIC)
;                          and sd2snes (double reset detection in firmware).
;
;   Region 50Hz/PAL        overrides the region to 50Hz/PAL.
;   Region 60Hz/NTSC       overrides the region to 60Hz/NTSC.
;   Region from cartridge  sets the region according to the input level of
;                          pin 4 (+5V = 50Hz, 0V = 60Hz).
;   Region from SuperCIC   sets the region according to the input level of
;                          the led (pin 8, 9 and 10) the current mode (50Hz,
;                          60Hz or Auto) is calculated by the uIGR. In this mode
;                          the region is updated periodically.
;
;   Toggle region timeout  for ~9s the console stays in the region mode of the
;                          cartridge and switches then into the last user mode
;   Toggle $213f-D4-Patch  enables or disables the d4-patch over pin 7
;                          (0V = disable, +5V = enable)
;
; -----------------------------------------------------------------------
; Configuration bits: adapt to your setup and needs
    __CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _BODEN & _CP_OFF & _CPD_OFF

; -----------------------------------------------------------------------
; code memory
;	org	0x0000

; relocatable code
PROG CODE

calibrate_osccal
        bsf STATUS, RP0 ;Bank 1
        call 3FFh ;Get the cal value
;        movlw 0xfc ; load '11111100' to set the OSCCAL to maximum
        movwf OSCCAL ;Calibrate
        bcf STATUS, RP0 ;Bank 0

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
        movlw   0x07            ; out out out in in in
        movwf   TRISC
        movlw   0x00            ; no pullups
        movwf   WPUA
        movlw   0x80            ; global pullup disable
        movwf   OPTION_REG
	banksel	PORTA
    bcf     PORTA, 4 ; assume NTSC-Mode
;    bsf     PORTA, 4 ; assume PAL-Mode
	bsf	PORTC, 3      ; assume D4-Patch on

init_mem
;	clrf	0x20
;	clrf	0x21
;	clrf	0x22
    clrf	0x50
	bcf	STATUS, C	; clear carry
        banksel EEADR		; fetch current mode from EEPROM
        clrf    EEADR		; address 0
        bsf     EECON1, RD	; 
        movf    EEDAT, w        ; 
        banksel PORTA
	movwf	0x50		; last mode saved in 0x50

check_d4_mode
    btfsc   0x50, 5 ; d4 enable?
    bsf     PORTC, 3
    btfss   0x50, 5 ; d4 disabled?
    bcf     PORTC, 3

check_last_led
    btfsc   0x50, 0 ; last mode "Auto"?
    call    setleds_yellow
    btfsc   0x50, 1 ; last mode "60Hz"?
    call    setleds_red
    btfsc   0x50, 2 ; last mode "50Hz"?
    call    setleds_green
    btfsc   0x50, 3 ; last mode from SCIC?
    call    setleds_passthru

check_reg_timeout
    btfss   0x50, 4         ; secure startup disabled?
    goto    last_mode_check ; if yes, jump directly to the last mode chosen
    movlw   0x3c 	        ; repeat the next loop 60 times
    movwf   0x52

reg_timeout ; (60 loops x ~0.15 sec/loop = ~9 sec)
    call    checkregion_auto_reg_timeout
    movlw   0x01
    call    superlongwait ; wait for roughly 0.15 Seconds
    btfsc   0x50, 3
    call    setleds_passthru ; the uIGR may be faster than the SCIC, therefore this call repeats every loop to bypass this probable possible problem
    decfsz    0x52           ; Are 60 loops done?
    goto    reg_timeout      ; If no, repeat this loop

last_mode_check
    btfsc   0x50, 0 ; last mode "Auto"?
    goto    setregion_auto_withoutLED
    btfsc   0x50, 1 ; last mode "60Hz"?
    goto    setregion_60_withoutLED
    btfsc   0x50, 2 ; last mode "50Hz"?
    goto    setregion_50_withoutLED
    goto    setregion_passthru_withoutLED

idle
	btfsc   PORTA, 5         ; reset pressed?
	goto    check_reset      ; then the SCIC might get a new mode or the console is reseted
    btfsc   0x50, 0                       ; Auto-Mode?
    goto    setregion_auto_withoutLED     ; if yes, check the current state
    btfsc   0x50, 3                       ; SCIC-Mode?
    goto    setregion_passthru            ; if yes, check the current state
	
waitforlatch_h	; wait for "latch" to become high
	btfss	PORTA, 1
	goto	idle

waitforlatch_l	; wait for "latch" to become low
	btfsc	PORTA, 1
	goto	waitforlatch_l

	clrf	0x20
	clrf	0x21
	clrf	0x22
	bcf     STATUS, C	; clear carry
	
dl1_init ; first data is read on the first falling edge
	btfsc   PORTA, 2 ; wait for "clk" to become low
	goto    dl1_init
dl1
	movf	PORTA, w	;read data bit
	rlf     0x20, f		;shift
	andlw	0x1	
	iorwf	0x20, f		;put in data reg
	incf	0x22, f		;inc bit count
dl1_wait
	btfss	PORTA, 2	;wait for clk=h
	goto	dl1_wait
	btfss	0x22, 3		;first byte done?
	goto	dl1
	clrf	0x22	
dl2
	movf	PORTA, w	;read data bit
	rlf     0x21, f		;shift
	andlw	0x1	
	iorwf	0x21, f		;put in data reg
	incf	0x22, f		;inc bit count
dl2_wait
	btfss	PORTA, 2	;wait for clk=h
	goto	dl2_wait
	btfss	0x22, 2		; read only 4 bits
	goto	dl2
	

checkkeys
; we now have the first 8 bits in 0x20 and the second 4 bits in 0x21
	; 00011111 00011111 = ABXY, Select, L
	movlw	0x04
	xorwf	0x21, w
	btfsc	STATUS, Z
	goto	group04
	movlw	0x08
	xorwf	0x21, w
	btfsc	STATUS, Z
	goto	group08
	movlw	0x0c
	xorwf	0x21, w
	btfsc	STATUS, Z
	goto	group0c
	goto	waitforlatch_h

group04 ; check L+R+sel+A
	movlw	0xdf
	xorwf	0x20, w
	btfss	STATUS, Z
	goto	waitforlatch_h
	goto	doregion_60

group08 ; check L+R+sel+X
	movlw	0xdf
	xorwf	0x20, w
	btfss	STATUS, Z
	goto	waitforlatch_h
	goto	doreset_dbl	; do dbl reset

group0c ; check L+R+sel+...
	movlw	0x5f    ; B
	xorwf	0x20, w
	btfsc	STATUS, Z 
	goto	doregion_auto
	movlw	0x9f    ; Y
	xorwf	0x20, w
	btfsc	STATUS, Z
	goto	doregion_50
	movlw	0xcf    ; start
	xorwf	0x20, w
	btfsc	STATUS, Z
	goto	doreset_normal
	movlw	0xd7    ; Up
	xorwf	0x20, w
	btfsc	STATUS, Z
	goto	toggle_startup
	movlw	0xdb    ; Down
	xorwf	0x20, w
	btfsc	STATUS, Z
	goto	toggle_d4_patch
	movlw	0xdd    ; Left
	xorwf	0x20, w
	btfsc	STATUS, Z
	goto	doscic_passthru
	movlw	0xde    ; Right
	xorwf	0x20, w
	btfsc	STATUS, Z
	goto	doscic_passthru
	goto	waitforlatch_h

doreset_normal
	banksel TRISA
	bcf     TRISA, 5
	banksel	PORTA
	bsf     PORTA, 5
    btfsc   0x50, 4                 ; secure startup enabled?
    call 	checkregion_auto_reg_timeout   ; if yes, predefine the output to the S-CPUN/PPUs before doing a reset
	movlw	0x15
	call	longwait
	banksel TRISA
	bsf     TRISA, 5
	banksel	PORTA
    btfss   0x50, 4 ; secure startup disabled?
    goto    waitforlatch_h      ; if yes, go on with 'normal procedure'
    movlw   0x3c
    movwf   0x52
    goto    reg_timeout  ; if no, we had to do a secure startup

doreset_dbl
	banksel	TRISA
	bcf     TRISA, 5
	banksel	PORTA
	bsf     PORTA, 5
    movlw	0x15
	call	longwait
	banksel	TRISA            ; new line
	bsf     TRISA, 5
	clrw
	call	longwait
	bcf     TRISA, 5
	banksel	PORTA           ; new line
    bsf     PORTA, 5        ; new line - let the reset-line stay high (just to be sure)
	movlw	0x15            
	call	longwait        
    bcf     PORTA, 5        ; new line - let the reset-line become low
	banksel	TRISA
	bsf     TRISA, 5
	banksel	PORTA
    btfss   0x50, 4   ; secure startup disabled?
    goto    waitforlatch_h      ; if yes, go on with 'normal procedure'
    movlw   0x65	  ; secure startup for roughly 15 seconds
    movwf   0x52
    goto    reg_timeout  ; if no, we had to do a secure startup

doregion_auto
    movf    0x50, w
    andlw   0xf0    ; save the reg_timeout and d4
    xorlw   0x01    ; set bit 0
    movwf   0x50
    call    save_mode

setregion_auto
	call	setleds_yellow

setregion_auto_withoutLED
	btfsc   PORTA, 3
	bsf     PORTA, 4
	btfss   PORTA, 3
	bcf     PORTA, 4
    goto    waitforlatch_h

doregion_60
    movf    0x50, w
    andlw   0xf0    ; save the reg_timeout and d4
    xorlw   0x02    ; set bit 1
    movwf   0x50
    call    save_mode

setregion_60
	call	setleds_red

setregion_60_withoutLED
	bcf     PORTA, 4
    goto    waitforlatch_h

doregion_50
    movf    0x50, w
    andlw   0xf0    ; save the reg_timeout and d4
    xorlw   0x04    ; set bit 2
    movwf   0x50
    call    save_mode

setregion_50
	call	setleds_green

setregion_50_withoutLED
	bsf     PORTA, 4
    goto    waitforlatch_h

check_reset
    movlw   0x04 	        ; repeat the next loop 4 times
    movwf   0x53

check_reset_loop
    movlw   0x01
    call    superlongwait
	btfsc   PORTA, 5         ; reset still pressed?
    goto    wait_for_rstloop_scic_passthru ; if yes, the user wants to change the mode of the SCIC
    btfss   0x50, 4 ; secure startup disabled?
    goto    waitforlatch_h      ; if yes, go on with 'normal procedure'
    call    checkregion_auto_reg_timeout ; if no, predefine the auto-mode
    movlw   0x3c
    movwf   0x52
    goto    reg_timeout  ; if no, we had to do a secure startup

wait_for_rstloop_scic_passthru
    decfsz  0x53 ; Are 4 loops done?
    goto    check_reset_loop

rstloop_scic_passthru
	call	setleds_passthru
	btfsc   PORTA, 5         ; reset still pressed?
	goto    rstloop_scic_passthru
    ;bsf     0x50, 3

doscic_passthru
    movf    0x50, w
    andlw   0xf0    ; save the reg_timeout and d4
    xorlw   0x08    ; set bit 3
    movwf   0x50
    call    save_mode

setregion_passthru
	call	setleds_passthru

setregion_passthru_withoutLED
	clrf	0x23
	btfss	PORTC, 2
	goto    setregion_passthru_withoutLED_Ca

setregion_passthru_withoutLED_An
    movf    PORTC, w
    andlw   0x03
    movwf   0x23
    movlw   0x00 ; auto-mode
	xorwf	0x23, w
	btfsc	STATUS, Z
    goto    setregion_auto_withoutLED
    movlw   0x01 ; 60Hz-mode
	xorwf	0x23, w
	btfsc	STATUS, Z
    goto    setregion_60_withoutLED
;    movlw  0x02 ; 50Hz-mode
;    xorwf	0x23, w
;    btfsc	STATUS, Z
    goto    setregion_50_withoutLED


setregion_passthru_withoutLED_Ca
    movf    PORTC, w
    andlw   0x03
    movwf   0x23
    movlw   0x01 ; 50Hz-mode
	xorwf	0x23, w
	btfsc	STATUS, Z 
    goto    setregion_50_withoutLED
    movlw   0x02 ; 60Hz-mode
	xorwf	0x23, w
	btfsc	STATUS, Z 
    goto    setregion_60_withoutLED
;    movlw  0x03 ; auto-mode
;	 xorwf	0x23, w
;	 btfsc	STATUS, Z 
    goto    setregion_auto_withoutLED
    
toggle_startup
    movf    0x50, w
    xorlw   0x10 ; toggle bit 4
    movwf   0x50
    call    save_mode    
    btfsc   0x50, 4           ; reg_timeout now disabled?
    goto    LED_confirm_rt_1  ; if enabled, confirm with r-y-gr
    
LED_confirm_rt_0 ; LED fading pattern: off->green->yellow->red->off->last LED color
    movf    PORTC, w
    andlw   0x38
    movwf   0x51 ; save last LED color and d4
    call    setleds_off
    movlw   0x03
    call    superlongwait
    call    setleds_green
    movlw   0x03
    call    superlongwait
    call    setleds_yellow
    movlw   0x03
    call    superlongwait
    call    setleds_red
    movlw   0x03
    call    superlongwait
    call    setleds_off
    movlw   0x03
    call    superlongwait
    movf    0x51, w
    movwf   PORTC ; return to last LED color
    goto    waitforlatch_h
    
LED_confirm_rt_1 ; LED fading pattern: off->red->yellow->green->off->last LED color
    movf    PORTC, w
    andlw   0x38
    movwf   0x51 ; save last LED color and d4
    call    setleds_off
    movlw   0x03
    call    superlongwait
    call    setleds_red
    movlw   0x03
    call    superlongwait
    call    setleds_yellow
    movlw   0x03
    call    superlongwait
    call    setleds_green
    movlw   0x03
    call    superlongwait
    call    setleds_off
    movlw   0x03
    call    superlongwait
    movf    0x51, w
    movwf   PORTC ; return to last LED color
    goto    waitforlatch_h

toggle_d4_patch
    movf    0x50, w
    xorlw   0x20 ; toggle bit 5
    movwf   0x50
    call    save_mode    
    btfsc   0x50, 5         ; d4-patch now disabled?
    goto    enable_d4_patch  ; if no, enable it

disable_d4_patch ; otherwise disable d4-patch
    bcf     PORTC, 3

LED_confirm_d4_0 ; LED fading pattern: off->red->off->red->off->last LED color
    movf    PORTC, w
    andlw   0x38
    movwf   0x51 ; save last LED color and d4
    call    setleds_off
    movlw   0x03
    call    superlongwait
    call    setleds_red
    movlw   0x03
    call    superlongwait
    call    setleds_off
    movlw   0x03
    call    superlongwait
    call    setleds_red
    movlw   0x03
    call    superlongwait
    call    setleds_off
    movlw   0x03
    call    superlongwait
    movf    0x51, w
    movwf   PORTC ; return to last LED color
    goto    waitforlatch_h

enable_d4_patch ; enable d4-patch
    bsf     PORTC, 3

LED_confirm_d4_1 ; LED fading pattern: off->green->off->green->off->last LED color
    movf    PORTC, w
    andlw   0x38
    movwf   0x51 ; save last LED color and d4
    call    setleds_off
    movlw   0x03
    call    superlongwait
    call    setleds_green
    movlw   0x03
    call    superlongwait
    call    setleds_off
    movlw   0x03
    call    superlongwait
    call    setleds_green
    movlw   0x03
    call    superlongwait
    call    setleds_off
    movlw   0x03
    call    superlongwait
    movf    0x51, w
    movwf   PORTC ; return to last LED color
    goto    waitforlatch_h

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

checkregion_auto_reg_timeout
	btfsc   PORTA, 3
	bsf     PORTA, 4
	btfss   PORTA, 3
	bcf     PORTA, 4
    return

setleds_red
	movf	PORTC, w
	andlw	0x08        ; save d4
	xorlw	0x10        ; set LED
	btfsc	PORTC, 2	; if common anode:
	xorlw	0x30		; invert output
	movwf	PORTC	
	return

setleds_green
	movf	PORTC, w
	andlw	0x08        ; save d4
	xorlw	0x20        ; set LED
	btfsc	PORTC, 2	; if common anode:
	xorlw	0x30		; invert output
	movwf	PORTC	
	return

setleds_yellow
	movf	PORTC, w
	andlw	0x08        ; save d4
	xorlw	0x30        ; set LED
	btfsc	PORTC, 2	; if common anode:
	xorlw	0x30		; invert output
	movwf	PORTC	
	return

setleds_passthru
	movf	PORTC, w
	andlw	0x08        ; save d4
	btfsc	PORTC, 0	; green LED
	iorlw	0x20
	btfsc	PORTC, 1	; red LED
	iorlw	0x10
	movwf	PORTC
	return

setleds_off
	movf	PORTC, w
	andlw	0x08        ; save d4
	xorlw	0x00        ; set LED
	btfsc	PORTC, 2	; if common anode:
	xorlw	0x30		; invert output
	movwf	PORTC	
	return

save_mode
	banksel	EEADR		; save to EEPROM. note: banksels take two cycles each!
	movwf	EEDAT
	bsf     EECON1,WREN
	movlw	0x55
	movwf	EECON2
	movlw	0xaa
	movwf	EECON2
	bsf     EECON1, WR
	banksel	PORTA		; two cycles again
    return
	
;END

; -----------------------------------------------------------------------
; eeprom data
DEEPROM	CODE
	de	0x22		;default mode (60Hz, reg_timeout off and
                    ;              $213f-D4-Patch enabled )
end
; ------------------------------------------------------------------------
