EESchema Schematic File Version 2  date Sun 06 Jun 2010 03:26:33 AM CEST
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:special
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:sd2snes-cache
EELAYER 24  0
EELAYER END
$Descr A4 11700 8267
Sheet 1 1
Title "SuperCIC lock - other connections"
Date "6 jun 2010"
Rev "A"
Comp "ikari_01"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Text Notes 1800 1700 0    60   ~ 0
©2010 ikari_01
Text Notes 1100 1900 0    100  ~ 0
"SNES" connections: see SNES connection diagram
Wire Wire Line
	3200 6150 3200 6550
Wire Wire Line
	2900 5750 2900 5550
Wire Wire Line
	3200 5750 3200 5650
Wire Wire Line
	3200 5650 2600 5650
Wire Wire Line
	2600 5650 2600 5750
Wire Wire Line
	3550 6450 2900 6450
Wire Wire Line
	4050 6450 4550 6450
Wire Wire Line
	5250 6550 5450 6550
Wire Wire Line
	5250 6350 5450 6350
Wire Wire Line
	5250 6150 5450 6150
Wire Wire Line
	4550 6150 4350 6150
Wire Wire Line
	4450 6050 4550 6050
Wire Wire Line
	5250 6050 5350 6050
Wire Wire Line
	4550 6250 4350 6250
Wire Wire Line
	4550 6650 4450 6650
Wire Wire Line
	5250 6250 5450 6250
Wire Wire Line
	5250 6450 5450 6450
Wire Wire Line
	5250 6650 5450 6650
Wire Wire Line
	4550 6350 4450 6350
Connection ~ 4450 6050
Wire Wire Line
	4050 6550 4550 6550
Wire Wire Line
	3200 6550 3550 6550
Wire Wire Line
	5350 6050 5350 7250
Wire Wire Line
	5350 3800 5350 2600
Connection ~ 3050 3700
Wire Wire Line
	3050 3800 3050 3700
Wire Wire Line
	3550 3100 3200 3100
Wire Wire Line
	3200 3100 3200 3200
Wire Wire Line
	4050 3100 4550 3100
Connection ~ 4450 2600
Wire Wire Line
	4450 2450 4450 2900
Wire Wire Line
	4450 2900 4550 2900
Wire Wire Line
	5250 3200 5450 3200
Wire Wire Line
	5250 3000 5450 3000
Wire Wire Line
	5250 2800 5450 2800
Wire Wire Line
	4550 3200 4450 3200
Wire Wire Line
	4550 2800 4350 2800
Wire Wire Line
	5350 2600 5250 2600
Wire Wire Line
	4550 2600 4450 2600
Wire Wire Line
	4550 2700 4350 2700
Wire Wire Line
	5250 2700 5450 2700
Wire Wire Line
	5250 2900 5450 2900
Wire Wire Line
	5250 3100 5450 3100
Wire Wire Line
	4050 3000 4550 3000
Wire Wire Line
	3550 3000 2900 3000
Wire Wire Line
	2900 3000 2900 3200
Wire Wire Line
	2900 3600 2900 3700
Wire Wire Line
	2900 3700 3200 3700
Wire Wire Line
	3200 3700 3200 3600
Wire Wire Line
	4450 3200 4450 3800
Wire Wire Line
	4450 6650 4450 5550
Connection ~ 4450 6350
Connection ~ 2900 5650
Wire Wire Line
	2900 6450 2900 6150
Text Notes 1100 1600 0    300  ~ 60
SuperCIC other connections
Text Notes 5450 3850 0    60   ~ 0
GND
$Comp
L +5V #PWR?
U 1 1 4C0AF540
P 2900 5550
F 0 "#PWR?" H 2900 5640 20  0001 C CNN
F 1 "+5V" H 2900 5640 30  0000 C CNN
	1    2900 5550
	1    0    0    -1  
$EndComp
Text Notes 3350 5400 0    100  ~ 0
"RGB LED" (common anode)
Text Notes 3150 2300 0    100  ~ 0
"Duo-LED" (common cathode)
$Comp
L DIL14 ~
U 1 1 4C0AF4AF
P 4900 6350
F 0 "~" H 4900 6750 60  0000 C CNN
F 1 "PIC16F630" H 4900 5900 50  0000 C CNN
	1    4900 6350
	1    0    0    -1  
$EndComp
$Comp
L R ~
U 1 1 4C0AF4AE
P 3800 6550
F 0 "~" V 3850 6350 50  0000 C CNN
F 1 "180" V 3800 6550 50  0000 C CNN
	1    3800 6550
	0    1    1    0   
$EndComp
$Comp
L R ~
U 1 1 4C0AF4AD
P 3800 6450
F 0 "~" V 3850 6250 50  0000 C CNN
F 1 "180" V 3800 6450 50  0000 C CNN
	1    3800 6450
	0    1    1    0   
$EndComp
$Comp
L +5V #PWR?
U 1 1 4C0AF4AA
P 4450 5550
F 0 "#PWR?" H 4450 5640 20  0001 C CNN
F 1 "+5V" H 4450 5640 30  0000 C CNN
	1    4450 5550
	1    0    0    -1  
$EndComp
NoConn ~ 4350 6250
Text Notes 4100 6200 0    60   ~ 0
SNES
Text Notes 5450 7300 0    60   ~ 0
GND
$Comp
L GND #PWR?
U 1 1 4C0AF4A7
P 5350 7250
F 0 "#PWR?" H 5350 7250 30  0001 C CNN
F 1 "GND" H 5350 7180 30  0001 C CNN
	1    5350 7250
	1    0    0    -1  
$EndComp
Text Notes 5500 6200 0    60   ~ 0
SNES
Text Notes 5500 6300 0    60   ~ 0
SNES
Text Notes 5500 6400 0    60   ~ 0
SNES
Text Notes 5500 6500 0    60   ~ 0
SNES
Text Notes 5500 6600 0    60   ~ 0
SNES
Text Notes 5500 6700 0    60   ~ 0
SNES
Text Notes 5500 3250 0    60   ~ 0
SNES
Text Notes 5500 3150 0    60   ~ 0
SNES
Text Notes 5500 3050 0    60   ~ 0
SNES
Text Notes 5500 2950 0    60   ~ 0
SNES
Text Notes 5500 2850 0    60   ~ 0
SNES
Text Notes 5500 2750 0    60   ~ 0
SNES
$Comp
L GND #PWR?
U 1 1 4C0AF458
P 5350 3800
F 0 "#PWR?" H 5350 3800 30  0001 C CNN
F 1 "GND" H 5350 3730 30  0001 C CNN
	1    5350 3800
	1    0    0    -1  
$EndComp
Text Notes 3600 3850 0    60   ~ 0
GND
$Comp
L GND #PWR?
U 1 1 4C0AF41F
P 4450 3800
F 0 "#PWR?" H 4450 3800 30  0001 C CNN
F 1 "GND" H 4450 3730 30  0001 C CNN
	1    4450 3800
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR?
U 1 1 4C0AF407
P 3050 3800
F 0 "#PWR?" H 3050 3800 30  0001 C CNN
F 1 "GND" H 3050 3730 30  0001 C CNN
	1    3050 3800
	1    0    0    -1  
$EndComp
Text Notes 4100 2750 0    60   ~ 0
SNES
NoConn ~ 4350 2800
$Comp
L +5V #PWR?
U 1 1 4C0AF329
P 4450 2450
F 0 "#PWR?" H 4450 2540 20  0001 C CNN
F 1 "+5V" H 4450 2540 30  0000 C CNN
	1    4450 2450
	1    0    0    -1  
$EndComp
$Comp
L LED ~
U 1 1 4C0AF2F1
P 3200 5950
F 0 "~" H 3200 6050 50  0000 C CNN
F 1 "LED red" H 3200 5850 50  0000 C CNN
	1    3200 5950
	0    1    1    0   
$EndComp
$Comp
L LED ~
U 1 1 4C0AF2F0
P 2900 5950
F 0 "~" H 2900 6050 50  0000 C CNN
F 1 "LED grn" H 2900 5850 50  0000 C CNN
	1    2900 5950
	0    1    1    0   
$EndComp
$Comp
L LED ~
U 1 1 4C0AF2EE
P 2600 5950
F 0 "~" H 2600 6050 50  0000 C CNN
F 1 "LED blu" H 2600 5850 50  0000 C CNN
	1    2600 5950
	0    1    1    0   
$EndComp
$Comp
L LED ~
U 1 1 4C0AF2EC
P 3200 3400
F 0 "~" H 3200 3500 50  0000 C CNN
F 1 "LED red" H 3200 3300 50  0000 C CNN
	1    3200 3400
	0    1    1    0   
$EndComp
$Comp
L LED ~
U 1 1 4C0AF2DF
P 2900 3400
F 0 "~" H 2900 3500 50  0000 C CNN
F 1 "LED grn" H 2900 3300 50  0000 C CNN
	1    2900 3400
	0    1    1    0   
$EndComp
$Comp
L R ~
U 1 1 4C0AF2A2
P 3800 3000
F 0 "~" V 3850 2800 50  0000 C CNN
F 1 "180" V 3800 3000 50  0000 C CNN
	1    3800 3000
	0    1    1    0   
$EndComp
$Comp
L R ~
U 1 1 4C0AF29F
P 3800 3100
F 0 "~" V 3850 2900 50  0000 C CNN
F 1 "180" V 3800 3100 50  0000 C CNN
	1    3800 3100
	0    1    1    0   
$EndComp
$Comp
L DIL14 ~
U 1 1 4C0AF0D9
P 4900 2900
F 0 "~" H 4900 3300 60  0000 C CNN
F 1 "PIC16F630" H 4900 2450 50  0000 C CNN
	1    4900 2900
	1    0    0    -1  
$EndComp
$EndSCHEMATC
