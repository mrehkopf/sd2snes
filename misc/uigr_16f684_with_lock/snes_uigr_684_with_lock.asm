    #include <p16f684.inc>

; -----------------------------------------------------------------------
;   SNES "In-game reset" (IGR) controller for use with the SuperCIC only
;
;   Copyright (C) 2010 by Maximilian Rehkopf <otakon@gmx.net>
;
;   Last Modified: October 2014 by Peter Bartmann <peter.bartmann@gmx.de>
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
;   This program is designed to run on a PIC 16F684 microcontroller connected
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
;   D-Pad left   Region from SCIC                                0xdd 0xcf
;   D-Pad right  Region from SCIC                                0xde 0xcf
;
;   D-Pad up     Toggle the region timeout                       0xd7 0xcf
;   D-Pad down   Toggle $213f-D4-Patch enable/disable            0xdb 0xcf
;
;   Temporary Lock:
;   To lock all other combinations one may press (D-Pad left + D-Pad up + L +
;   R + A + X -> strean data 0xf5 0x0f) together. The same combination unlocks
;   the IGR functionalities again.
;   Lock   -> LED confirms with fast flashing red
;   Unlock -> LED confirms with fast flashing green
;
;   Permanent Lock:
;   To lock all combinations one may press (D-Pad down + D-Pad left + L +
;   R + A + B -> strean data 0x79 0x4f) together. This can only be undone by
;   a reset (only reset button, not by sd2snes-IGRs) or power off and on again
;   Lock   -> LED confirms with fast flashing red
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
;   Toggle region patch  enables or disables the d4-patch over pin 7
;                          (0V = disable, +5V = enable)
;
; -----------------------------------------------------------------------
; Configuration bits: adapt to your setup and needs
    __CONFIG _INTOSCIO & _IESO_OFF & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOD_OFF

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

M_bepf  macro   compPORT, compReg, branch   ; branch if PORTx equals compReg (ignoring bit 6 and 7)
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

M_delay_x10ms   macro   literal ; delay about literal x 10ms
                movlw   literal
                movwf   reg_repetition_cnt
                call    delay_x10ms
                endm

M_T1reset   macro   ; reset and start timer1
            clrf    TMR1L
            clrf    TMR1H
            clrf    PIR1
            bsf     T1CON, TMR1ON
            endm

M_push_reset    macro   ; push reset button
                banksel TRISA
                bcf     TRISA, RESET_OUT
                banksel PORTA
                bsf     PORTA, RESET_OUT
                endm

M_release_reset macro   ; push release button
                bcf     PORTA, RESET_OUT
                banksel TRISA
                bsf     TRISA, RESET_OUT
                banksel PORTA
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

reg_ctrl_data_lsb       EQU 0x20
reg_ctrl_data_msb       EQU 0x21
; reg_ctrl_data_cnt       EQU 0x22
reg_t0_overflows        EQU 0x31
reg_repetition_cnt      EQU 0x32
reg_t1_overflows        EQU 0x33
reg_current_mode        EQU 0x40
reg_passthru_calc       EQU 0x41
reg_led_save            EQU 0x41

bit_mode_auto       EQU 0
bit_mode_60         EQU 1
bit_mode_50         EQU 2
bit_mode_scic       EQU 3
bit_regtimeout      EQU 4
bit_regpatch        EQU 5
bit_igrlock_tmp     EQU 6
bit_igrlock_ever    EQU 7

code_mode_auto      EQU (1<<bit_mode_auto)      ; 0x01
code_mode_60        EQU (1<<bit_mode_60)        ; 0x02
code_mode_50        EQU (1<<bit_mode_50)        ; 0x04
code_mode_scic      EQU (1<<bit_mode_scic)      ; 0x08
code_regtimeout     EQU (1<<bit_regtimeout)     ; 0x10
code_regpatch       EQU (1<<bit_regpatch)       ; 0x20
code_igrlock_tmp    EQU (1<<bit_igrlock_tmp)    ; 0x40

code_led_off    EQU 0x00    ; off
code_led_60     EQU 0x10    ; red
code_led_50     EQU 0x20    ; green
code_led_auto   EQU 0x30    ; yellow

code_mode_default   EQU (code_mode_60 ^ code_regpatch)


delay_10ms_t0_overflows     EQU 0x0a    ; prescaler T0 set to 1:8
repetitions_60ms            EQU 0x06
repetitions_200ms           EQU 0x14
repetitions_260ms           EQU 0x1a
repetitions_580ms           EQU 0x3a
repetitions_LED_delay       EQU 0x3c    ; around 600ms
repetitions_LED_delay_fast  EQU 0x1e    ; around 300ms

overflows_t1_regtimeout_start       EQU 0xa3
overflows_t1_regtimeout_reset       EQU 0xa3
overflows_t1_regtimeout_reset_2     EQU 0x9b
overflows_t1_regtimeout_dblrst      EQU 0xff
overflows_t1_regtimeout_dblrst_2    EQU 0xfb

; -----------------------------------------------------------------------
; buttons

BUTTON_B    EQU 7
BUTTON_Y    EQU 6
BUTTON_Sl   EQU 5
BUTTON_St   EQU 4
BUTTON_Up   EQU 3
BUTTON_Dw   EQU 2
BUTTON_Le   EQU 1
BUTTON_Ri   EQU 0

BUTTON_A    EQU 7
BUTTON_X    EQU 6
BUTTON_L    EQU 5
BUTTON_R    EQU 4

BUTTON_None3    EQU 3
BUTTON_None2    EQU 2
BUTTON_None1    EQU 1
BUTTON_None0    EQU 0

; -----------------------------------------------------------------------

; code memory
 org    0x0000
    clrf    STATUS      ; 00h Page 0, Bank 0
    nop                 ; 01h
    nop                 ; 02h
    goto    start       ; 03h Initialisierung / ProgrammBeginn

 org    0x0004  ; jump here on interrupt with GIE set (should not appear)
    return      ; return with GIE unset

 org    0x0005
check_scic_auto
    btfsc   PORTA, RESET_IN ; reset pressed?
    goto    check_reset     ; then the SCIC might get a new mode or the console is reseted
    btfsc   reg_current_mode, bit_mode_auto     ; Auto-Mode?
    goto    setregion_auto_withoutLED           ; if yes, check the current state
    btfsc   reg_current_mode, bit_mode_scic     ; SCIC-Mode?
    goto    setregion_passthru                  ; if yes, check the current state

idle
    btfsc   reg_current_mode, bit_igrlock_ever
    goto    check_scic_auto
    M_movlf 0xff, reg_ctrl_data_lsb
    M_movlf 0xff, reg_ctrl_data_msb
    M_T1reset
    btfsc   PORTA, DATA_LATCH
    goto    read_Button_B       ; go go go
    bcf     INTCON, RAIF

idle_loop
    btfsc   INTCON, RAIF    ; reset or data latch changed?
    goto    read_Button_B   ; if yes - wait for latch become low
    btfsc   PORTA, RESET_IN ; reset pressed?
    goto    check_reset     ; then the SCIC might get a new mode or the console is reseted
    btfsc   INTCON, RAIF    ; reset or data latch changed?
    goto    read_Button_B   ; if yes - wait for latch become low
    btfss   PIR1, TMR1IF    ; timer 1 overflow?
    goto    check_scic_auto ; SNES hasn't read controller past ~65ms
    btfsc   INTCON, RAIF    ; reset or data latch changed?
    goto    read_Button_B   ; if yes - wait for latch become low
    goto    idle_loop


read_Button_B   ; button B can be read imediately
    nop
    bcf     INTCON, INTF
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_msb, BUTTON_B


wait_read_Button_Y
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_Y
;    sleep
read_Button_Y
    bcf     INTCON, INTF
    bcf     INTCON, RAIF                ; from now on, no IOC at the data latch shall appear
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_msb, BUTTON_Y

wait_read_Button_Sl
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_Sl
;    sleep
read_Button_Sl
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_msb, BUTTON_Sl

wait_read_Button_St
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_St
;    sleep
read_Button_St
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_msb, BUTTON_St

wait_read_Button_Up
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_Up
;    sleep
read_Button_Up
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_msb, BUTTON_Up

wait_read_Button_Dw
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_Dw
;    sleep
read_Button_Dw
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_msb, BUTTON_Dw

wait_read_Button_Le
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_Le
;    sleep
read_Button_Le
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_msb, BUTTON_Le

wait_read_Button_Ri
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_Ri
;    sleep
read_Button_Ri
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_msb, BUTTON_Ri


wait_read_Button_A
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_A
;    sleep
read_Button_A
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_lsb, BUTTON_A

wait_read_Button_X
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_X
;    sleep
read_Button_X
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_lsb, BUTTON_X

wait_read_Button_L
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_L
;    sleep
read_Button_L
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_lsb, BUTTON_L

wait_read_Button_R
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_R
;    sleep
read_Button_R
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_lsb, BUTTON_R


wait_read_Button_None3
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_None3
;    sleep
read_Button_None3
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_lsb, BUTTON_None3

wait_read_Button_None2
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_None2
;    sleep
read_Button_None2
    bcf     INTCON, INTF
    nop
	btfss   PORTA, SERIAL_DATA
	bcf     reg_ctrl_data_lsb, BUTTON_None2

wait_read_Button_None1
    btfss   INTCON, INTF    ; wait for rising edge on clk
    goto    wait_read_Button_None1
;    sleep
read_Button_None1
    bcf     INTCON, INTF
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_lsb, BUTTON_None1

wait_read_Button_None0
    btfsc   INTCON, INTF    ; wait for rising edge on clk
    goto    read_Button_None0
read_Button_None0
    nop
    nop
    btfss   PORTA, SERIAL_DATA
    bcf     reg_ctrl_data_lsb, BUTTON_None0

    btfsc   INTCON, RAIF
    goto    check_scic_auto         ; another IOC on data latch appeared -> invalid read


checkkeys
    M_belf  0xf5, reg_ctrl_data_msb, un_lock_igr_tmp    ; check for (un)lock igr before doin' anything else
    btfsc   reg_current_mode, bit_igrlock_tmp           ; igr locked?
    goto    check_scic_auto                             ; yes
    M_belf  0x4f, reg_ctrl_data_lsb, group4f
    M_belf  0x8f, reg_ctrl_data_lsb, group8f
    M_belf  0xcf, reg_ctrl_data_lsb, groupcf
    goto    check_scic_auto

group4f ; check L+R+sel+A
    M_belf  0xdf, reg_ctrl_data_msb, doregion_60
    M_belf  0x79, reg_ctrl_data_msb, lock_igr_ever
    goto    check_scic_auto

group8f ; check L+R+sel+X
    M_belf  0xdf, reg_ctrl_data_msb, doreset_dbl    ; do dbl reset
    goto    check_scic_auto

groupcf ; check L+R+sel+...
    M_belf  0x5f, reg_ctrl_data_msb, doregion_auto      ; B
    M_belf  0x9f, reg_ctrl_data_msb, doregion_50        ; Y
    M_belf  0xcf, reg_ctrl_data_msb, doreset_normal     ; start
    M_belf  0xd7, reg_ctrl_data_msb, toggle_startup     ; Up
    M_belf  0xdb, reg_ctrl_data_msb, toggle_d4_patch    ; Down
    M_belf  0xdd, reg_ctrl_data_msb, doscic_passthru    ; Left
    M_belf  0xde, reg_ctrl_data_msb, doscic_passthru    ; Right
    goto    check_scic_auto


doreset_normal
    M_push_reset
    call    delay_10ms
    btfsc   reg_current_mode, bit_regtimeout                ; region timeout enabled?
    call    call_M_setAuto                                  ; if yes, define the output to the S-CPUN/PPUs
    call    delay_10ms
    M_release_reset
    btfss   reg_current_mode, bit_regtimeout                ; region timout disabled?
    goto    check_scic_auto                                 ; if yes, go on with 'normal procedure'

    M_movlf overflows_t1_regtimeout_reset, reg_t1_overflows
    M_T1reset                                               ; start timer 1
    goto    regtimeout                                      ; if no, we had to perform a region timeout

doreset_dbl
    M_push_reset
    call            delay_10ms
    call            delay_10ms
    M_release_reset
    M_delay_x10ms   repetitions_200ms
    M_push_reset
    call            delay_10ms
    btfsc           reg_current_mode, bit_regtimeout            ; region timeout enabled?
    call            call_M_setAuto                              ; if yes, define the output to the S-CPUN/PPUs
    call            delay_10ms
    M_release_reset
    btfss           reg_current_mode, bit_regtimeout            ; region timeout enabled?
    goto            check_scic_auto                             ; if yes, go on with 'normal procedure'

    M_movlf overflows_t1_regtimeout_dblrst, reg_t1_overflows
    M_T1reset                                                   ; start timer 1
    goto    regtimeout                                          ; if no, we had to perform a region timeout

doregion_auto
    movfw   reg_current_mode
    andlw   0x70                ; save the igrlock_tmp, reg_timeout and d4
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
    andlw   0x70                ; save the igrlock_tmp, reg_timeout and d4
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
    andlw   0x70                ; save the igrlock_tmp, reg_timeout and d4
    xorlw   code_mode_50        ; set mode 50
    movwf   reg_current_mode
    call    save_mode

setregion_50
    call    setled_50

setregion_50_withoutLED
    set50Hz
    goto    idle

check_reset
    call    delay_10ms  ; software debounce needed in case of region timeout is enabled
    call    delay_10ms
    btfss   PORTA, RESET_IN                     ; reset still pressed?
    goto    check_scic_auto

    M_movpf PORTC, reg_passthru_calc

check_reset_loop
    btfsc   PORTA, RESET_IN                     ; reset still pressed?
    goto    wait_for_rstloop_scic_passthru      ; if yes, the user might want to change the mode of the SCIC

check_reset_prepare_timeout
    bcf     reg_current_mode, bit_igrlock_ever
    btfss   reg_current_mode, bit_regtimeout                ; region timeout disabled?
    goto    check_scic_auto                                 ; if yes, go on with 'normal procedure'
    M_setAuto                                               ; if no, predefine the auto-mode ...

    call    delay_10ms          ; software debounce
    M_setAuto
    call    delay_10ms          ; software debounce
    M_setAuto
    M_movlf 0xc2, OPTION_REG    ; make sure prescale assigned to T0 and set to 1:8
    M_movlf repetitions_580ms, reg_repetition_cnt
    M_movlf delay_10ms_t0_overflows, reg_t0_overflows
    clrf    TMR0    ; start timer
    bcf     INTCON, T0IF

check_dblrst
    btfsc   PORTA, RESET_IN                     ; reset still pressed again?
    goto    check_dblrst_prepare_timeout
    M_setAuto
    btfss   INTCON, T0IF
    goto    check_dblrst
    bcf     INTCON, T0IF
    decfsz  reg_t0_overflows, 1
    goto    check_dblrst
    M_movlf delay_10ms_t0_overflows, reg_t0_overflows
    decfsz  reg_repetition_cnt, 1
    goto    check_dblrst

    M_movlf overflows_t1_regtimeout_reset_2, reg_t1_overflows
    M_T1reset                                               ; start timer 1
    goto    regtimeout                                      ; ...and perform a region timeout

check_dblrst_prepare_timeout
    M_movlf overflows_t1_regtimeout_dblrst_2, reg_t1_overflows
    M_T1reset                                               ; start timer 1
    goto    regtimeout                                      ; ...and perform a region timeout

wait_for_rstloop_scic_passthru
    M_bepf  PORTC, reg_passthru_calc, check_reset_loop ; go back to check_reset_loop if LED not changed by S-CIC

rstloop_scic_passthru
    call    setled_passthru
    btfsc   PORTA, RESET_IN         ; reset still pressed?
    goto    rstloop_scic_passthru

doscic_passthru
    movfw   reg_current_mode
    andlw   0x70                ; save the igrlock_tmp, reg_timeout and d4
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
    M_movpf         PORTC, reg_led_save ; save last LED color and d4
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    call            setled_50
    M_delay_x10ms   repetitions_LED_delay
    call            setled_auto
    M_delay_x10ms   repetitions_LED_delay
    call            setled_60
    M_delay_x10ms   repetitions_LED_delay
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    M_movff         reg_led_save, PORTC ; return to last LED color
    goto            check_scic_auto

LED_confirm_rt_1 ; LED fading pattern: off->red->yellow->green->off->last LED color
    M_movpf         PORTC, reg_led_save ; save last LED color and d4
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    call            setled_60
    M_delay_x10ms   repetitions_LED_delay
    call            setled_auto
    M_delay_x10ms   repetitions_LED_delay
    call            setled_50
    M_delay_x10ms   repetitions_LED_delay
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    M_movff         reg_led_save, PORTC ; return to last LED color
    goto            check_scic_auto

toggle_d4_patch
    movfw   reg_current_mode
    xorlw   code_regpatch                   ; toggle
    movwf   reg_current_mode
    call    save_mode
    btfsc   reg_current_mode, bit_regpatch  ; region patch now disabled?
    goto    enable_d4_patch                 ; if no, enable it

disable_d4_patch ; otherwise disable d4-patch
    setD4off

LED_confirm_d4off   ; LED fading pattern: off->red->off->red->off->last LED color
    M_movpf         PORTC, reg_led_save ; save last LED color and d4
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    call            setled_60
    M_delay_x10ms   repetitions_LED_delay
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    call            setled_60
    M_delay_x10ms   repetitions_LED_delay
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    M_movff         reg_led_save, PORTC ; return to last LED color
    goto            check_scic_auto

enable_d4_patch ; enable d4-patch
    setD4on

LED_confirm_d4on    ; LED fading pattern: off->green->off->green->off->last LED color
    M_movpf         PORTC, reg_led_save ; save last LED color and d4
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    call            setled_50
    M_delay_x10ms   repetitions_LED_delay
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    call            setled_50
    M_delay_x10ms   repetitions_LED_delay
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay
    M_movff         reg_led_save, PORTC ; return to last LED color
    goto            check_scic_auto


un_lock_igr_tmp ; check for (un)lock the irg
    M_belf  0x0f, reg_ctrl_data_lsb, toggle_igrlock_tmp ; check the LSBs
    goto    check_scic_auto                             ; if stream data is not matched, go back to check_scic_auto

toggle_igrlock_tmp
    movfw   reg_current_mode
    xorlw   code_igrlock_tmp                    ; toggle
    movwf   reg_current_mode
    call    save_mode
    btfsc   reg_current_mode, bit_igrlock_tmp   ; irg now unlocked?
    goto    LED_confirm_lock_igr                ; if no, conform locking

LED_confirm_unlock_igr ; LED fast flashing green
    M_movpf         PORTC, reg_led_save ; save last LED color and d4
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_50
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_50
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_50
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_50
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_50
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    M_movff         reg_led_save, PORTC ; return to last LED color
    goto            check_scic_auto

LED_confirm_lock_igr ; LED fast flashing red
    M_movpf         PORTC, reg_led_save ; save last LED color and d4
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_60
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_60
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_60
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_60
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_60
    M_delay_x10ms   repetitions_LED_delay_fast
    call            setled_off
    M_delay_x10ms   repetitions_LED_delay_fast
    M_movff         reg_led_save, PORTC ; return to last LED color
    goto            check_scic_auto

lock_igr_ever
    bsf     reg_current_mode, bit_igrlock_ever
    goto    LED_confirm_lock_igr


call_M_setAuto
    M_setAuto
    return

setled_60
    movfw   PORTC
    andlw   0x0f                ; save d4
    xorlw   code_led_60        ; set LED
    btfsc   PORTC, LED_TYPE_IN  ; if common anode:
    xorlw   0x30                ; invert output
    movwf   PORTC
    return

setled_50
    movfw   PORTC
    andlw   0x0f                ; save d4
    xorlw   code_led_50        ; set LED
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
    movfw   reg_current_mode
    banksel EEADR       ; save to EEPROM. note: banksels take two cycles each!
    movwf   EEDAT
    bsf     EECON1,WREN
    movlw   0x55
    movwf   EECON2
    movlw   0xaa
    movwf   EECON2
    bsf     EECON1, WR
    banksel PORTA       ; two cycles again
    return


delay_10ms
    M_movlf 0xc2, OPTION_REG    ; make sure prescale assigned to T0 and set to 1:8
    M_movlf delay_10ms_t0_overflows, reg_t0_overflows
    clrf    TMR0    ; start timer

delay_10ms_loop_pre
    bcf     INTCON, T0IF

delay_10ms_loop
    btfss   INTCON, T0IF
    goto    delay_10ms_loop
    decfsz  reg_t0_overflows, 1
    goto    delay_10ms_loop_pre
    return

delay_x10ms
    call    delay_10ms
    decfsz  reg_repetition_cnt, 1
    goto    delay_x10ms
    return


start
    clrf    PORTA
    clrf    PORTC
    M_movlf 0x07, CMCON0        ; PORTA2..0 are digital I/O (not connected to comparator)
    M_movlf 0x38, INTCON        ; enable T0IE, RAIE and INTE to react on data latch and clock
    banksel TRISA
    M_movlf 0x70, OSCCON        ; use 8MHz internal clock (internal clock set on config)
    clrf    ANSEL
    M_movlf 0x2f, TRISA         ; in out in in in in
    M_movlf 0x07, TRISC         ; out out out in in in
    M_movlf 0x00, WPUA          ; no pullups
    M_movlf 0x02, IOCA          ; IOC on DATA_LATCH
    M_movlf 0xc2, OPTION_REG    ; global pullup disable, use rising data clock edge for interrupt, prescaler T0 1:8
    banksel PORTA
    M_movlf 0x10, T1CON         ; set prescaler T1 1:2

    set60Hz ; assume NTSC-Mode
    setD4on ; assume D4-Patch on

load_mode
    clrf    reg_current_mode
    bcf     STATUS, C   ; clear carry
    banksel EEADR       ; fetch current mode from EEPROM
    clrf    EEADR       ; address 0
    bsf     EECON1, RD;
    movfw   EEDAT       ;
    banksel PORTA
    andlw   0x7f        ; unset potential permanent lock
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

; -----------------------------------------------------------------------
; eeprom data
DEEPROM CODE
    de  code_mode_default

theveryend
    end
; ------------------------------------------------------------------------
