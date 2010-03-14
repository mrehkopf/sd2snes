    #include <p12f683.inc>
processor p12f683

; -----------------------------------------------------------------------
    __CONFIG _EC_OSC & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOD_ON & _IESO_ON & _FCMEN_ON

; -----------------------------------------------------------------------
; code memory
	org	0x0000
	nop
	nop
	nop
	goto	init
;"isr"
	org	0x0004
	bcf	INTCON, 1	; clear interrupt cause
	bcf	GPIO, 0
	bcf	GPIO, 1
	bsf	GPIO, 4
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	INTCON, 7	; re-enable interrupts (for the ISR will replace the main)
	goto	main
init
	org 0x0010
	banksel GPIO
	clrf	GPIO
	movlw	0x17	; GPIO4, GPIO2, GPIO1, GPIO0 are digital I/O
	movwf	CMCON0
	movlw	0x90	; Enable interrupts + enable INT
	movwf	INTCON
	banksel	ANSEL
	clrf	ANSEL
	movlw	0x2e	; in out in in in out
	movwf	TRISIO
	movlw	0x80 ; 0x3f for pullups
	movwf	OPTION_REG
	banksel GPIO
	bsf 	GPIO, 0x0

idle	bcf	GPIO, 0
	bsf	GPIO, 0
	goto	idle
main
	banksel	TRISIO
	bsf	TRISIO, 1
	bcf	TRISIO, 0
	banksel	GPIO
;	sleep
;--------INIT KEY SEED--------
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
	
;--------INIT LOCK SEED--------
	banksel	EEADR
	clrf	EEADR
	bsf	EECON1, RD
	movf	EEDAT, w
	banksel GPIO
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
	
;--------Main loop--------
	movlw	0xb5
	call	wait
	clrf	0x31		; clear lock stream ID
;--------lock sends stream ID. 15 cycles per bit--------
;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	GPIO, 1		; check stream ID bit
	bsf	0x31, 3		; copy to lock seed
	movlw	0x2		; wait=3*W+5
	call	wait		; burn 11 cycles
	nop
	nop

;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	GPIO, 1		; check stream ID bit
	bsf	0x31, 0		; copy to lock seed
	movlw	0x2		;
	call	wait		; burn 11 cycles
	nop
	nop

;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	GPIO, 1		; check stream ID bit
	bsf	0x31, 1		; copy to lock seed
	movlw	0x2		;
	call	wait		; burn 11 cycles
	nop
	nop

;	bsf	GPIO, 0
;	bcf	GPIO, 0
	btfsc	GPIO, 1		; check stream ID bit
	bsf	0x31, 2		; copy to lock seed
	banksel	TRISIO
	bsf	TRISIO, 0
	bcf	TRISIO, 1
	banksel	GPIO
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
	nop
	nop
	nop
	nop
	nop
	movlw	0x22		; "wait" 1
	call	wait		; wait 107
	nop
	nop
loop	
	movlw	0x1
loop0
	addlw	0x30	; key stream (what we thought was the lock stream...)
	movwf	FSR	; store in index reg
loop1
	movf	INDF, w ; load seed value
	movwf	0x20
	bcf	0x20, 1	; clear bit 1 
	btfsc	0x20, 0 ; copy from bit 0
	bsf	0x20, 1 ; (if set)
	bsf	0x20, 4 ; status pin
	movf	0x20, w
	movwf	GPIO
	nop
	movlw	0x10
	movwf	GPIO	; reset GPIO
	movlw	0x16
	call	wait
	nop
	btfsc	GPIO, 0
	goto	die
	btfsc	GPIO, 1
	goto	die
	incf	FSR, f	; next one
	movlw	0xf
	andwf	FSR, w
	btfss	STATUS, Z	
	goto	loop1
	movlw	0x2	; wait 20
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
	movf	0x37, w
	andlw	0xf
	btfss	STATUS, Z
	goto	loop0
	goto	loop

;--------mangle--------
;this is damn tight because the PIC has no convenient instructions at all
;
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
	movwf	0x40	;save 25 to 40
	movf	0x24, w
	addwf	0x25, f
	movf	0x26, w
	movwf	0x41	;save 26 to 41
	movf	0x40, w ;restore 25
	andlw	0xf	;mask nibble
	addlw	0x8	;add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 ;skip if carry to 5th bit
	addwf	0x26, w
	movwf	0x26

	movf	0x41, w ;restore 26
	addlw	0x1	;inc
	addwf	0x27, f	;add to 27

	movf	0x27, w ;
	addlw	0x1	;inc
	addwf	0x28, f ;add to 28

	movf	0x28, w ;
	addlw	0x1	;inc
	addwf	0x29, f ;add to 28

	movf	0x29, w ;
	addlw	0x1	;inc
	addwf	0x2a, f ;add to 28

	movf	0x2a, w ;
	addlw	0x1	;inc
	addwf	0x2b, f ;add to 28

	movf	0x2b, w ;
	addlw	0x1	;inc
	addwf	0x2c, f ;add to 28

	movf	0x2c, w ;
	addlw	0x1	;inc
	addwf	0x2d, f ;add to 28

	movf	0x2d, w ;
	addlw	0x1	;inc
	addwf	0x2e, f ;add to 28

	movf	0x2e, w ;
	addlw	0x1	;inc
	addwf	0x2f, f ;add to 28
;60
	movf	0x20, w ;restore original 0xf
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
	btfss	0x20, 4 ;skip if half-byte carry
	goto mangle_return ; +2 cycles in return
	nop
	goto mangle_key_loop
; 69 when goto, 69 when return
; CIC has 78	
mangle_key_withskip
	movf	0x41, w ;restore 23
	addwf	0x23, f ;add to 23
	movf	0x24, w
	movwf	0x40	;save 25 to 40
	movf	0x23, w
	addwf	0x24, f
	movf	0x25, w
	movwf	0x41	;save 26 to 41
	movf	0x40, w ;restore 25
	andlw	0xf	;mask nibble
	addlw	0x8	;add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 ;skip if carry to 5th bit
	addwf	0x25, w
	movwf	0x25

	movf	0x41, w ;restore 26
	addlw	0x1	;inc
	addwf	0x26, f	;add to 27

	movf	0x26, w ;
	addlw	0x1	;inc
	addwf	0x27, f ;add to 28

	movf	0x27, w ;
	addlw	0x1	;inc
	addwf	0x28, f ;add to 28

	movf	0x28, w ;
	addlw	0x1	;inc
	addwf	0x29, f ;add to 28

	movf	0x29, w ;
	addlw	0x1	;inc
	addwf	0x2a, f ;add to 28

	movf	0x2a, w ;
	addlw	0x1	;inc
	addwf	0x2b, f ;add to 28

	movf	0x2b, w ;
	addlw	0x1	;inc
	addwf	0x2c, f ;add to 28

	movf	0x2c, w ;
	addlw	0x1	;inc
	addwf	0x2d, f ;add to 28

	movf	0x2d, w ;
	addlw	0x1	;inc
	addwf	0x2e, f ;add to 28

	movf	0x2e, w ;
	addlw	0x1	;inc
	addwf	0x2f, f ;add to 28
;64
	movf	0x20, w ;restore original 0xf
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
	btfss	0x20, 4 ;skip if half-byte carry
	goto mangle_return ; +2 cycles in return
	nop
	goto mangle_key_loop
mangle_return
	return
;73 when goto, 73 when return
;CIC has 84

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
	movwf	0x40	;save 35 to 40
	movf	0x34, w
	addwf	0x35, f
	movf	0x36, w
	movwf	0x41	;save 36 to 41
	movf	0x40, w ;restore 35
	andlw	0xf	;mask nibble
	addlw	0x8	;add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 ;skip if carry to 5th bit
	addwf	0x36, w
	movwf	0x36

	movf	0x41, w ;restore 36
	addlw	0x1	;inc
	addwf	0x37, f	;add to 37

	movf	0x37, w ;
	addlw	0x1	;inc
	addwf	0x38, f ;add to 38

	movf	0x38, w ;
	addlw	0x1	;inc
	addwf	0x39, f ;add to 39

	movf	0x39, w ;
	addlw	0x1	;inc
	addwf	0x3a, f ;add to 3a

	movf	0x3a, w ;
	addlw	0x1	;inc
	addwf	0x3b, f ;add to 3b

	movf	0x3b, w ;
	addlw	0x1	;inc
	addwf	0x3c, f ;add to 3c

	movf	0x3c, w ;
	addlw	0x1	;inc
	addwf	0x3d, f ;add to 3d

	movf	0x3d, w ;
	addlw	0x1	;inc
	addwf	0x3e, f ;add to 3e

	movf	0x3e, w ;
	addlw	0x1	;inc
	addwf	0x3f, f ;add to 3f

	movf	0x30, w ;restore original 0xf
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
	btfss	0x30, 4 ;skip if half-byte carry
	goto mangle_return
	nop
	goto mangle_lock_loop
; 69 when goto, 69 when return
; CIC has 78	
	
mangle_lock_withskip
	movf	0x41, w ;restore 33
	addwf	0x33, f ;add to 33
	movf	0x34, w
	movwf	0x40	;save 34 to 40
	movf	0x33, w
	addwf	0x34, f
	movf	0x35, w
	movwf	0x41	;save 35 to 41
	movf	0x40, w ;restore 34
	andlw	0xf	;mask nibble
	addlw	0x8	;add #8 to HIGH nibble
	movwf	0x40
	btfss	0x40, 4 ;skip if carry to 5th bit
	addwf	0x35, w
	movwf	0x35

	movf	0x41, w ;restore 35
	addlw	0x1	;inc
	addwf	0x36, f	;add to 36

	movf	0x36, w ;
	addlw	0x1	;inc
	addwf	0x37, f ;add to 37

	movf	0x37, w ;
	addlw	0x1	;inc
	addwf	0x38, f ;add to 38

	movf	0x38, w ;
	addlw	0x1	;inc
	addwf	0x39, f ;add to 39

	movf	0x39, w ;
	addlw	0x1	;inc
	addwf	0x3a, f ;add to 3a

	movf	0x3a, w ;
	addlw	0x1	;inc
	addwf	0x3b, f ;add to 3b

	movf	0x3b, w ;
	addlw	0x1	;inc
	addwf	0x3c, f ;add to 3c

	movf	0x3c, w ;
	addlw	0x1	;inc
	addwf	0x3d, f ;add to 3d

	movf	0x3d, w ;
	addlw	0x1	;inc
	addwf	0x3e, f ;add to 3e

	movf	0x3e, w ;
	addlw	0x1	;inc
	addwf	0x3f, f ;add to 3f

	movf	0x30, w ;restore original 0xf
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
	btfss	0x30, 4 ;skip if half-byte carry
	goto mangle_return
	nop
	goto mangle_lock_loop
;73 when goto, 73 when return
;CIC has 84

;--------wait: 3*(W-1)+7 cycles (including call+return). W=0 -> 256!--------
wait	
	movwf	0x4f
wait0	decfsz	0x4f, f
	goto	wait0
	return	

;--------wait long: 8+(3*(w-1))+(772*w). W=0 -> 256!--------
longwait
	movwf	0x4e
	clrw
longwait0
	call	wait
	decfsz	0x4e, f
	goto	longwait0
	return

;--------change region in eeprom and die--------
die
	banksel	EEADR
	clrw
	movwf	EEADR
	bsf	EECON1, RD
	movf	EEDAT, w
	banksel	GPIO
	movwf	0x4d
	btfsc	0x4d, 0
	goto	die_reg_6
die_reg_9
	movlw	0x9
	goto	die_reg_cont
die_reg_6
	movlw	0x6	
die_reg_cont
	banksel	EEADR
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

	banksel	GPIO
die_blink	
	clrw
	call	longwait
	bsf	GPIO, 4
	call	longwait
	bcf	GPIO, 4
	goto	die_blink
; -----------------------------------------------------------------------
; eeprom memory
DEEPROM	CODE
	de      0x09
end
