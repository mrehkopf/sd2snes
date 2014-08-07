    #include <p16f630.inc>

; -----------------------------------------------------------------------
;   SNES "In-game reset" (IGR) controller for use with the SuperCIC only
;
;   Copyright (C) 2010 by Maximilian Rehkopf <otakon@gmx.net>
;
;   Last Modified: August 2014 by Peter Bartmann <peter.bartmann@gmx.de>
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
;   Right-Arrow  Region from SCIC                                0xde 0xcf
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
;   Toggle regionpatch     enables or disables the d4-patch over pin 7
;                          (0V = disable, +5V = enable)
;
; -----------------------------------------------------------------------
; Configuration bits: adapt to your setup and needs
    __CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _BODEN & _CP_OFF & _CPD_OFF

Debug   set 0 ; 0 = debug off, 1= debug on

; -----------------------------------------------------------------------
; macros and definitions

M_movff macro   fromReg, toReg  ; move filereg to filereg
        movfw   fromReg
        movwf   toReg
        endm

M_movpf macro   fromPORT, toReg ; move PORTx to filereg
        movfw   fromPORT
        andlw   0x3f
        movwf   toReg
        endm

M_movlf macro   literal, toReg  ; move literal to filereg
        movlw   literal
        movwf   toReg
        endm

M_beff  macro   compReg1, compReg2, branch  ; branch if two fileregs are equal
        movfw   compReg1
        xorwf   compReg2, w
        btfsc   STATUS, Z
        goto    branch
        endm

M_bepf  macro   compPORT, compReg, branch   ; brach if PORTx equals compReg (ignoring bit 6 and 7)
        movfw   compPORT
        xorwf   compReg, w
        andlw   0x3f
        btfsc   STATUS, Z
        goto    branch
        endm

M_belf  macro   literal, compReg, branch  ; branch if a literal is stored in filereg
        movlw   literal
        xorwf   compReg, w
        btfsc   STATUS, Z
        goto    branch
        endm

M_T1reset   macro   ; reset and start timer1
            clrf    TMR1L
            clrf    TMR1H
            clrf    PIR1
            bsf     T1CON, TMR1ON
            endm

M_setAuto   macro   ; set modeout to auto
            btfsc   PORTA, CART_MODE_IN
            set50Hz
            btfss   PORTA, CART_MODE_IN
            set60Hz
            endm

#define set60Hz     bcf PORTA, MODE_OUT
#define set50Hz     bsf PORTA, MODE_OUT
#define setD4on     bsf PORTC, REGPATCH_OUT
#define setD4off    bcf PORTC, REGPATCH_OUT

; -----------------------------------------------------------------------
; bits and registers and more

SERIAL_DATA     EQU 0
DATA_LATCH      EQU 1
DATA_CLK        EQU 2
CART_MODE_IN    EQU 3
MODE_OUT        EQU 4
RESET_IN        EQU 5
RESET_OUT       EQU 5

LED_MODE_50_IN  EQU 0
LED_MODE_60_IN  EQU 1
LED_TYPE_IN     EQU 2
REGPATCH_OUT    EQU 3

reg_ctrl_data_lsb   EQU 0x20
reg_ctrl_data_msb   EQU 0x21
reg_ctrl_data_cnt   EQU 0x22
reg_current_mode    EQU 0x50
reg_passthru_calc   EQU 0x51
reg_led_save        EQU 0x51
reg_t1_overflows    EQU 0x52

bit_mode_auto   EQU 0
bit_mode_60     EQU 1
bit_mode_50     EQU 2
bit_mode_scic   EQU 3
bit_regtimeout  EQU 4
bit_regpatch    EQU 5

code_mode_auto  EQU (1<<bit_mode_auto)  ; 0x01
code_mode_60    EQU (1<<bit_mode_60)    ; 0x02
code_mode_50    EQU (1<<bit_mode_50)    ; 0x04
code_mode_scic  EQU (1<<bit_mode_scic)  ; 0x08
code_regtimeout EQU (1<<bit_regtimeout) ; 0x10
code_regpatch   EQU (1<<bit_regpatch)   ; 0x20
code_led_off    EQU 0x00                ; off
code_led_60     EQU 0x10                ; red
code_led_50     EQU 0x20                ; green
code_led_auto   EQU 0x30                ; yellow

overflows_t1_regtimeout_start       EQU 0x11
overflows_t1_regtimeout_reset       EQU 0x11
overflows_t1_regtimeout_dblreset    EQU 0x1c


; -----------------------------------------------------------------------

; code memory
 org    0x0000
    clrf    STATUS      ; 00h Page 0, Bank 0
    nop                 ; 01h
    nop                 ; 02h
    goto    start       ; 03h Initialiizing / begin program

 org    0x0004  ; jump here on interrupt with GIE set (should not appear)
    return      ; return with GIE unset

 org    0x0005
start
    clrf    PORTA
    clrf    PORTC
    M_movlf 0x07, CMCON         ; PORTA2..0 are digital I/O (not connected to comparator)
    M_movlf 0x00, INTCON        ; disable all interrupts
    banksel TRISA
    call    3FFh                ; Get the osccal value
    movwf   OSCCAL              ; Calibrate
    M_movlf 0x2f, TRISA         ; in out in in in in
    M_movlf 0x07, TRISC         ; out out out in in in
    M_movlf 0x00, WPUA          ; no pullups
    M_movlf 0x80, OPTION_REG    ; global pullup disable
    banksel PORTA
    M_movlf 0x30, T1CON         ; prescaler 1:8 Timer1

    set60Hz ; assume NTSC-Mode
    setD4on ; assume D4-Patch on

init_gpr
    clrf    reg_current_mode
    bcf     STATUS, C   ; clear carry
    banksel EEADR       ; fetch current mode from EEPROM
    clrf    EEADR       ; address 0
    bsf     EECON1, RD  ; 
    movfw   EEDAT       ;
    banksel PORTA
    movwf   reg_current_mode

check_d4_mode
    btfss   reg_current_mode, bit_regpatch  ; region patching disabled?
    setD4off

check_last_led
    btfsc   reg_current_mode, bit_mode_auto ; last mode "Auto"?
    call    setled_auto
    btfsc   reg_current_mode, bit_mode_60   ; last mode "60Hz"?
    call    setled_60
    btfsc   reg_current_mode, bit_mode_50   ; last mode "50Hz"?
    call    setled_50
    btfsc   reg_current_mode, bit_mode_scic ; last mode from SCIC?
    call    setled_passthru

check_reg_timeout
    btfss   reg_current_mode, bit_regtimeout    ; regtimeout disabled?
    goto    last_mode_check                     ; if yes, jump directly to the last mode chosen
    movlw   overflows_t1_regtimeout_start
    movwf   reg_t1_overflows

    M_T1reset                                  ; start timer 1

regtimeout
    M_setAuto
    btfsc   reg_current_mode, bit_mode_scic
    call    setled_passthru
    btfss   PIR1, TMR1IF                    ; timer 1 overflow?
    goto    regtimeout
    clrf    PIR1                            ; clear overflow bit
    decfsz  reg_t1_overflows                ; Are all loops done?
    goto    regtimeout                      ; If no, repeat this loop

    bcf     T1CON, TMR1ON

last_mode_check
    btfsc   reg_current_mode, bit_mode_auto ; last mode "Auto"?
    goto    setregion_auto_withoutLED
    btfsc   reg_current_mode, bit_mode_60 ; last mode "60Hz"?
    goto    setregion_60_withoutLED
    btfsc   reg_current_mode, bit_mode_50 ; last mode "50Hz"?
    goto    setregion_50_withoutLED
    goto    setregion_passthru_withoutLED

idle
    btfsc   PORTA, DATA_LATCH
    goto    waitforlatch_l
    btfsc   PORTA, RESET_IN                 ; reset pressed?
    goto    check_reset                     ; then the SCIC might get a new mode or the console is reseted
    btfsc   reg_current_mode, bit_mode_auto ; Auto-Mode?
    goto    setregion_auto_withoutLED       ; if yes, check the current state
    btfsc   reg_current_mode, bit_mode_scic ; SCIC-Mode?
    goto    setregion_passthru              ; if yes, check the current state
    goto    idle

waitforlatch_l ; wait for "latch" to become low
    btfsc   PORTA, DATA_LATCH
    goto    waitforlatch_l

start_read_data
    clrf    reg_ctrl_data_msb
    clrf    reg_ctrl_data_cnt
    bcf     STATUS, C           ; clear carry

dl1_init ; first data is read on the first falling edge
    btfsc   PORTA, DATA_CLK ; wait for "clk" to become low
    goto    dl1_init
    movfw   PORTA           ; read data bit

dl1
    rlf     reg_ctrl_data_msb, f    ; shift
    andlw   0x1
    iorwf   reg_ctrl_data_msb, f    ; put in data reg
    incf    reg_ctrl_data_cnt, f    ; inc bit count
dl1_wait
    btfss   PORTA, DATA_CLK     ;wait for clk=h
    goto    dl1_wait
    movfw   PORTA                   ; read data bit
    btfss   reg_ctrl_data_cnt, 3    ; first byte done?
    goto    dl1

    clrf    reg_ctrl_data_lsb
    clrf    reg_ctrl_data_cnt

dl2
    rlf     reg_ctrl_data_lsb, f    ; shift
    andlw   0x1
    iorwf   reg_ctrl_data_lsb, f    ; put in data reg
    incf    reg_ctrl_data_cnt, f    ; inc bit count
dl2_wait
    btfss   PORTA, DATA_CLK         ;wait for clk=h
    goto    dl2_wait
    movfw   PORTA                   ; read data bit
    btfss   reg_ctrl_data_cnt, 2    ; read only 4 bits
    goto    dl2


checkkeys   ; we now have the first 8 bits in 0x21 and the second 4 bits in 0x20
            ; (00011111 00011111 = ABXY, Select, L)
    M_belf  0x04, reg_ctrl_data_lsb, group04
    M_belf  0x08, reg_ctrl_data_lsb, group08
    M_belf  0x0c, reg_ctrl_data_lsb, group0c
    goto    idle

group04 ; check L+R+sel+A
    M_belf  0xdf, reg_ctrl_data_msb, doregion_60
    goto    idle

group08 ; check L+R+sel+X
    M_belf  0xdf, reg_ctrl_data_msb, doreset_dbl    ; do dbl reset
    goto    idle

group0c ; check L+R+sel+...
    M_belf  0x5f, reg_ctrl_data_msb, doregion_auto      ; B
    M_belf  0x9f, reg_ctrl_data_msb, doregion_50        ; Y
    M_belf  0xcf, reg_ctrl_data_msb, doreset_normal     ; start
    M_belf  0xd7, reg_ctrl_data_msb, toggle_startup     ; Up
    M_belf  0xdb, reg_ctrl_data_msb, toggle_d4_patch    ; Down
    M_belf  0xdd, reg_ctrl_data_msb, doscic_passthru    ; Left
    M_belf  0xde, reg_ctrl_data_msb, doscic_passthru    ; Right
    goto    idle

doreset_normal
    banksel TRISA
    bcf     TRISA, RESET_OUT
    banksel PORTA
    bsf     PORTA, RESET_OUT
    btfsc   reg_current_mode, bit_regtimeout    ; region timeout enabled?
    call    call_M_setAuto                      ; if yes, define the output to the S-CPUN/PPUs
    movlw   0x15
    call    longwait
    banksel TRISA
    bsf     TRISA, RESET_OUT
    banksel PORTA
    btfss   reg_current_mode, bit_regtimeout    ; region timout disabled?
    goto    idle                                ; if yes, go on with 'normal procedure'
    movlw   overflows_t1_regtimeout_reset
    movwf   reg_t1_overflows

    M_T1reset                                   ; start timer 1
    goto    regtimeout                          ; if no, we had to perform a region timeout

doreset_dbl
    banksel TRISA
    bcf     TRISA, RESET_OUT
    banksel PORTA
    bsf     PORTA, RESET_OUT
    movlw   0x15
    call    longwait
    banksel TRISA
    bsf     TRISA, RESET_OUT
    clrw
    call    longwait
    bcf     TRISA, RESET_OUT
    banksel PORTA
    bsf     PORTA, RESET_OUT                    ; let the reset-line stay high (just to be sure)
    movlw   0x15
    call    longwait
    banksel TRISA
    bsf     TRISA, RESET_OUT
    banksel PORTA
    btfss   reg_current_mode, bit_regtimeout    ; region timeout enabled?
    goto    idle                                ; if yes, go on with 'normal procedure'
    movlw   overflows_t1_regtimeout_dblreset
    movwf   reg_t1_overflows

    M_T1reset                                   ; start timer 1
    goto    regtimeout                          ; if no, we had to perform a region timeout

doregion_auto
    movfw   reg_current_mode
    andlw   0xf0                ; save the regtimeout and regpatch
    xorlw   code_mode_auto      ; set mode auto
    movwf   reg_current_mode
    call    save_mode

setregion_auto
    call    setled_auto

setregion_auto_withoutLED
    M_setAuto
    goto    idle

doregion_60
    movfw   reg_current_mode
    andlw   0xf0                ; save the regtimeout and regpatch
    xorlw   code_mode_60        ; set mode 60
    movwf   reg_current_mode
    call    save_mode

setregion_60
    call    setled_60

setregion_60_withoutLED
    set60Hz
    goto    idle

doregion_50
    movfw   reg_current_mode
    andlw   0xf0                ; save the regtimeout and regpatch
    xorlw   code_mode_50        ; set mode 50
    movwf   reg_current_mode
    call    save_mode

setregion_50
    call    setled_50

setregion_50_withoutLED
    set50Hz
    goto    idle

check_reset
    clrw
    call    longwait        ; software debounce
    btfss   PORTA, RESET_IN
    goto    check_reset_prepare_timeout
    M_movpf PORTC, reg_passthru_calc

check_reset_loop
	btfsc   PORTA, RESET_IN                     ; reset still pressed?
    goto    wait_for_rstloop_scic_passthru      ; if yes, the user might want to change the mode of the SCIC

check_reset_prepare_timeout
    btfss   reg_current_mode, bit_regtimeout    ; region timeout disabled?
    goto    idle                                ; if yes, go on with 'normal procedure'
    M_setAuto                                   ; if no, predefine the auto-mode ...
    movlw   overflows_t1_regtimeout_reset
    movwf   reg_t1_overflows

    M_T1reset                                   ; start timer 1
    goto    regtimeout                          ; ... and perform a region timeout

wait_for_rstloop_scic_passthru
    M_bepf  PORTC, reg_passthru_calc, check_reset_loop ; go back to check_reset_loop if LED not changed by S-CIC

rstloop_scic_passthru
    call    setled_passthru
    btfsc   PORTA, RESET_IN         ; reset still pressed?
    goto    rstloop_scic_passthru

doscic_passthru
    movfw   reg_current_mode
    andlw   0xf0                ; save the reg_timeout and d4
    xorlw   code_mode_scic      ; set bit 3
    movwf   reg_current_mode
    call    save_mode

setregion_passthru
    call    setled_passthru

setregion_passthru_withoutLED
    movfw   PORTC
    andlw   0x07
    movwf   reg_passthru_calc
    btfss   reg_passthru_calc, LED_TYPE_IN
    goto    setregion_passthru_withoutLED_Ca

setregion_passthru_withoutLED_An
    M_belf  0x04, reg_passthru_calc, setregion_auto_withoutLED  ; auto-mode
    M_belf  0x05, reg_passthru_calc, setregion_60_withoutLED    ; 60Hz-mode
    goto    setregion_50_withoutLED                             ; 50Hz-mode


setregion_passthru_withoutLED_Ca
    M_belf  0x01, reg_passthru_calc, setregion_50_withoutLED    ; 50Hz-mode
    M_belf  0x02, reg_passthru_calc, setregion_60_withoutLED    ; 60Hz-mode
    goto    setregion_auto_withoutLED                           ; auto-mode
    
toggle_startup
    movfw   reg_current_mode
    xorlw   code_regtimeout                     ; toggle
    movwf   reg_current_mode
    call    save_mode    
    btfsc   reg_current_mode, bit_regtimeout    ; reg_timeout now disabled?
    goto    LED_confirm_rt_1                    ; if enabled, confirm with r-y-gr
    
LED_confirm_rt_0 ; LED fading pattern: off->green->yellow->red->off->last LED color
    M_movpf PORTC, reg_led_save ; save last LED color and d4
    call    setled_off
    movlw   0x03
    call    superlongwait
    call    setled_50
    movlw   0x03
    call    superlongwait
    call    setled_auto
    movlw   0x03
    call    superlongwait
    call    setled_60
    movlw   0x03
    call    superlongwait
    call    setled_off
    movlw   0x03
    call    superlongwait
    M_movff reg_led_save, PORTC ; return to last LED color
    goto    idle
    
LED_confirm_rt_1 ; LED fading pattern: off->red->yellow->green->off->last LED color
    M_movpf PORTC, reg_led_save ; save last LED color and d4
    call    setled_off
    movlw   0x03
    call    superlongwait
    call    setled_60
    movlw   0x03
    call    superlongwait
    call    setled_auto
    movlw   0x03
    call    superlongwait
    call    setled_50
    movlw   0x03
    call    superlongwait
    call    setled_off
    movlw   0x03
    call    superlongwait
    M_movff reg_led_save, PORTC ; return to last LED color
    goto    idle

toggle_d4_patch
    movf    reg_current_mode, w
    xorlw   code_regpatch                   ; toggle
    movwf   reg_current_mode
    call    save_mode    
    btfsc   reg_current_mode, bit_regpatch  ; region patch now disabled?
    goto    enable_d4_patch                 ; if no, enable it

disable_d4_patch ; otherwise disable d4-patch
    setD4off

LED_confirm_d4off   ; LED fading pattern: off->red->off->red->off->last LED color
    M_movpf PORTC, reg_led_save ; save last LED color and d4
    call    setled_off
    movlw   0x03
    call    superlongwait
    call    setled_60
    movlw   0x03
    call    superlongwait
    call    setled_off
    movlw   0x03
    call    superlongwait
    call    setled_60
    movlw   0x03
    call    superlongwait
    call    setled_off
    movlw   0x03
    call    superlongwait
    M_movff reg_led_save, PORTC ; return to last LED color
    goto    idle

enable_d4_patch ; enable d4-patch
    setD4on

LED_confirm_d4on    ; LED fading pattern: off->green->off->green->off->last LED color
    M_movpf PORTC, reg_led_save ; save last LED color and d4
    call    setled_off
    movlw   0x03
    call    superlongwait
    call    setled_50
    movlw   0x03
    call    superlongwait
    call    setled_off
    movlw   0x03
    call    superlongwait
    call    setled_50
    movlw   0x03
    call    superlongwait
    call    setled_off
    movlw   0x03
    call    superlongwait
    M_movff reg_led_save, PORTC ; return to last LED color
    goto    idle

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
    movwf   0x2d
    clrw
superlongwait0
    call    longwait
    decfsz  0x2d, f
    goto    superlongwait0
    return

call_M_setAuto
    M_setAuto
    return

setled_60
    movfw   PORTC
    andlw   0x0f                ; save d4
    xorlw   code_led_60         ; set LED
    btfsc   PORTC, LED_TYPE_IN  ; if common anode:
    xorlw   0x30                ; invert output
    movwf   PORTC
    return

setled_50
    movfw   PORTC
    andlw   0x0f                ; save d4
    xorlw   code_led_50         ; set LED
    btfsc   PORTC, LED_TYPE_IN  ; if common anode:
    xorlw   0x30                ; invert output
    movwf   PORTC   
    return

setled_auto
    movfw   PORTC
    andlw   0x0f                ; save d4
    xorlw   code_led_auto       ; set LED
    btfsc   PORTC, LED_TYPE_IN  ; if common anode:
    xorlw   0x30                ; invert output
    movwf   PORTC
    return

setled_passthru
    movfw   PORTC
    andlw   0x0f                    ; save d4 and LED in
    btfsc   PORTC, LED_MODE_50_IN   ; green LED
    xorlw   code_led_50
    btfsc   PORTC, LED_MODE_60_IN   ; red LED
    xorlw   code_led_60
    movwf   PORTC
    return

setled_off
    movfw   PORTC
    andlw   0x0f                ; save d4
    xorlw   code_led_off        ; set LED
    btfsc   PORTC, LED_TYPE_IN  ; if common anode:
    xorlw   0x30                ; invert output
    movwf   PORTC
    return

save_mode
    banksel EEADR       ; save to EEPROM. note: banksels take two cycles each!
    movwf   EEDAT
    bsf     EECON1,WREN
    movlw   0x55
    movwf   EECON2
    movlw   0xaa
    movwf   EECON2
    bsf     EECON1, WR
    banksel PORTA   ; two cycles again
    return

; -----------------------------------------------------------------------
; eeprom data
DEEPROM CODE
    de  (code_mode_60 ^ code_regpatch) ; default mode (60Hz, reg_timeout off and
                                       ; (=0x22)       $213f-D4-Patch enabled )
end
; ------------------------------------------------------------------------
