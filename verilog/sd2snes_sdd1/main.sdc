## Generated SDC file "main.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.0.0 Build 614 04/24/2018 SJ Lite Edition"

## DATE    "Fri Jul 27 00:34:51 2018"

##
## DEVICE  "EP4CE15F17C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLKIN} -period 41.666 -waveform { 0.000 20.833 } [get_ports {CLKIN}]
create_clock -name {SPI_SCK} -period 20.833 -waveform { 0.000 10.417 } [get_ports { SPI_SCK }]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {snes_pll|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {snes_pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 4 -master_clock {CLKIN} [get_pins {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLKIN}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLKIN}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLKIN}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLKIN}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLKIN}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLKIN}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLKIN}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLKIN}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {SPI_SCK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {SPI_SCK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {SPI_SCK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {SPI_SCK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLKIN}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {CLKIN}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {CLKIN}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {CLKIN}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {CLKIN}] -rise_to [get_clocks {CLKIN}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLKIN}] -fall_to [get_clocks {CLKIN}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLKIN}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {CLKIN}] -rise_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {CLKIN}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {CLKIN}] -fall_to [get_clocks {snes_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {CLKIN}] -rise_to [get_clocks {CLKIN}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLKIN}] -fall_to [get_clocks {CLKIN}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

