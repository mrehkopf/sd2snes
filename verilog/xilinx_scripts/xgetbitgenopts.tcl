set scriptdir [file dirname [file normalize [info script]]]
source [file join $scriptdir xcommon.tcl]

proc existsBitgenProp { name } {
    if { ![info exists ::xstProps] } {
        set ::xstProps [project properties -process "Generate Programming File"]
    }
    return [existsProp $::xstProps $name]
}

proc getbitgenopts {} {
    set opts [list]

    if { [existsBitgenProp "Other Bitgen Command Line Options"]
         && ![string equal [project get "Other Bitgen Command Line Options"] ""] } {
        lappend opts [project get "Other Bitgen Command Line Options"]
    }

    lappend opts "-w"

    if { [existsBitgenProp "Enable Debugging of Serial Mode BitStream"] } {
        if { [project get "Enable Debugging of Serial Mode BitStream"] } {
            lappend opts "-g DebugBitstream:Yes"
        } else {
            lappend opts "-g DebugBitstream:No"
        }
    }

    if { [existsBitgenProp "Run Design Rules Checker (DRC)"]
         && ![project get "Run Design Rules Checker (DRC)"] } {
        lappend opts "-d"
    }

    if { [existsBitgenProp "Create Bit File"]
         && ![project get "Create Bit File"] } {
        lappend opts "-j"
    }

    if { [existsBitgenProp "Create Binary Configuration File"]
         && [project get "Create Binary Configuration File"] } {
        lappend opts "-g Binary:yes"
    } else {
        lappend opts "-g Binary:no"
    }

    if { [existsBitgenProp "Create ASCII Configuration File"] } {
        if { [project get "Create ASCII Configuration File"] } {
            lappend opts "-b"
        }
    }

    if { [existsBitgenProp "Enable BitStream Compression"] } {
        if { [project get "Enable BitStream Compression"] } {
            lappend opts "-g Compress"
        }
    }

    if { [existsBitgenProp "Create IEEE 1532 Configuration File"] } {
        if { [project get "Create IEEE 1532 Configuration File"] } {
            lappend opts "-g IEEE1352:Yes"
        }
    }

    if { [existsBitgenProp "Global Clock Delay 0 (Binary String)"] } {
        if { [project get "Global Clock Delay 0 (Binary String)"] } {
            lappend opts "-g Gclkdel0:[project get "Global Clock Delay 0 (Binary String)"]"
        }
    }
    if { [existsBitgenProp "Global Clock Delay 1 (Binary String)"] } {
        if { [project get "Global Clock Delay 1 (Binary String)"] } {
            lappend opts "-g Gclkdel1:[project get "Global Clock Delay 1 (Binary String)"]"
        }
    }
    if { [existsBitgenProp "Global Clock Delay 2 (Binary String)"] } {
        if { [project get "Global Clock Delay 2 (Binary String)"] } {
            lappend opts "-g Gclkdel2:[project get "Global Clock Delay 2 (Binary String)"]"
        }
    }
    if { [existsBitgenProp "Global Clock Delay 3 (Binary String)"] } {
        if { [project get "Global Clock Delay 3 (Binary String)"] } {
            lappend opts "-g Gclkdel3:[project get "Global Clock Delay 3 (Binary String)"]"
        }
    }

    if { [existsBitgenProp "Enable Cyclic Redundancy Checking (CRC)"] } {
        if { [project get "Enable Cyclic Redundancy Checking (CRC)"] } {
            lappend opts "-g CRC:Enable"
        } else {
            lappend opts "-g CRC:Disable"
        }
    }

    if { [existsBitgenProp "Retry Configuration if CRC Error Occurs"] } {
        if { [project get "Retry Configuration if CRC Error Occurs"] } {
            lappend opts "-g Reset_on_err:Yes"
        } else {
            lappend opts "-g Reset_on_err:No"
        }
    }

    if { [existsBitgenProp "Configuration Rate"] } {
        switch -- [project get "Configuration Rate"] {
            "Default (1)" { lappend opts "-g ConfigRate:1" }
            "Default (6)" { lappend opts "-g ConfigRate:6" }
            default       { lappend opts "-g ConfigRate:[project get "Configuration Rate"]" }
        }
    }

    if { [existsBitgenProp "Configuration Clk (Configuration Pins)"] } {
        switch -- [project get "Configuration Clk (Configuration Pins)"] {
            "Pull Up" { lappend opts "-g CclkPin:PullUp" }
            Float     { lappend opts "-g CclkPin:PullNone" }
        }
    }
    if { [existsBitgenProp "Configuration Pin M0"] } {
        switch -- [project get "Configuration Pin M0"] {
            "Pull Up"   { lappend opts "-g M0Pin:PullUp" }
            Float       { lappend opts "-g M0Pin:PullNone" }
            "Pull Down" { lappend opts "-g M0Pin:PullDown" }
        }
    }
    if { [existsBitgenProp "Configuration Pin M1"] } {
        switch -- [project get "Configuration Pin M1"] {
            "Pull Up"   { lappend opts "-g M1Pin:PullUp" }
            Float       { lappend opts "-g M1Pin:PullNone" }
            "Pull Down" { lappend opts "-g M1Pin:PullDown" }
        }
    }
    if { [existsBitgenProp "Configuration Pin M2"] } {
        switch -- [project get "Configuration Pin M2"] {
            "Pull Up"   { lappend opts "-g M2Pin:PullUp" }
            Float       { lappend opts "-g M2Pin:PullNone" }
            "Pull Down" { lappend opts "-g M2Pin:PullDown" }
        }
    }
    if { [existsBitgenProp "Configuration Pin Program"] } {
        switch -- [project get "Configuration Pin Program"] {
            "Pull Up" { lappend opts "-g ProgPin:PullUp" }
            Float     { lappend opts "-g ProgPin:PullNone" }
        }
    }
    if { [existsBitgenProp "Configuration Pin Done"] } {
        switch -- [project get "Configuration Pin Done"] {
            "Pull Up"       { lappend opts "-g DonePin:PullUp" }
            Float           { lappend opts "-g DonePin:PullNone" }
            "Active Pullup" { lappend opts "-g DonePin:PullNone -g DriveDone:Yes" }
        }
    }
    if { [existsBitgenProp "Configuration Pin Init"] } {
        switch -- [project get "Configuration Pin Init"] {
            "Pull Up" { lappend opts "-g InitPin:PullUp" }
            Float     { lappend opts "-g InitPin:PullNone" }
        }
    }
    if { [existsBitgenProp "Configuration Pin CS"] } {
        switch -- [project get "Configuration Pin CS"] {
            "Pull Up"   { lappend opts "-g CsPin:PullUp" }
            Float       { lappend opts "-g CsPin:PullNone" }
            "Pull Down" { lappend opts "-g CsPin:PullDown" }
        }
    }
    if { [existsBitgenProp "Configuration Pin DIn"] } {
        switch -- [project get "Configuration Pin DIn"] {
            "Pull Up"   { lappend opts "-g DinPin:PullUp" }
            Float       { lappend opts "-g DinPin:PullNone" }
            "Pull Down" { lappend opts "-g DinPin:PullDown" }
        }
    }
    if { [existsBitgenProp "Configuration Pin Busy"] } {
        switch -- [project get "Configuration Pin Busy"] {
            "Pull Up"   { lappend opts "-g BusyPin:PullUp" }
            Float       { lappend opts "-g BusyPin:PullNone" }
            "Pull Down" { lappend opts "-g BusyPin:PullDown" }
        }
    }
    if { [existsBitgenProp "Configuration Pin RdWr"] } {
        switch -- [project get "Configuration Pin RdWr"] {
            "Pull Up"   { lappend opts "-g RdWrPin:PullUp" }
            Float       { lappend opts "-g RdWrPin:PullNone" }
            "Pull Down" { lappend opts "-g RdWrPin:PullDown" }
        }
    }
    if { [existsBitgenProp "Configuration Pin Powerdown"] } {
        switch -- [project get "Configuration Pin Powerdown"] {
            "Pull Up"   { lappend opts "-g PowerdownPin:PullUp" }
            Float       { lappend opts "-g PowerdownPin:PullNone" }
        }
    }
    if { [existsBitgenProp "Configuration Pin HSWAPEN"] } {
        switch -- [project get "Configuration Pin HSWAPEN"] {
            "Pull Up"   { lappend opts "-g HswapenPin:PullUp" }
            Float       { lappend opts "-g HswapenPin:PullNone" }
            "Pull Down" { lappend opts "-g HswapenPin:PullDown" }
        }
    }
    if { [existsBitgenProp "JTAG Pin TCK"] } {
        switch -- [project get "JTAG Pin TCK"] {
            "Pull Up"   { lappend opts "-g TckPin:PullUp" }
            Float       { lappend opts "-g TckPin:PullNone" }
            "Pull Down" { lappend opts "-g TckPin:PullDown" }
        }
    }
    if { [existsBitgenProp "JTAG Pin TDI"] } {
        switch -- [project get "JTAG Pin TDI"] {
            "Pull Up"   { lappend opts "-g TdiPin:PullUp" }
            Float       { lappend opts "-g TdiPin:PullNone" }
            "Pull Down" { lappend opts "-g TdiPin:PullDown" }
        }
    }
    if { [existsBitgenProp "JTAG Pin TDO"] } {
        switch -- [project get "JTAG Pin TDO"] {
            "Pull Up"   { lappend opts "-g TdoPin:PullUp" }
            Float       { lappend opts "-g TdoPin:PullNone" }
            "Pull Down" { lappend opts "-g TdoPin:PullDown" }
        }
    }
    if { [existsBitgenProp "JTAG Pin TMS"] } {
        switch -- [project get "JTAG Pin TMS"] {
            "Pull Up"   { lappend opts "-g TmsPin:PullUp" }
            Float       { lappend opts "-g TmsPin:PullNone" }
            "Pull Down" { lappend opts "-g TmsPin:PullDown" }
        }
    }
    if { [existsBitgenProp "Disable JTAG Connection"] } {
        if { [project get "Disable JTAG Connection"] } {
            lappend opts "-g Disable_JTAG:Yes"
        } else {
            lappend opts "-g Disable_JTAG:No"
        }
    }
    if { [existsBitgenProp "Unused IOB Pins"] } {
        switch -- [project get "Unused IOB Pins"] {
            "Pull Up"   { lappend opts "-g UnusedPin:PullUp" }
            Float       { lappend opts "-g UnusedPin:PullNone" }
            "Pull Down" { lappend opts "-g UnusedPin:PullDown" }
        }
    }
    if { [existsBitgenProp "UserID Code (8 Digit Hexadecimal)"] } {
        if { ![string equal [project get "UserID Code (8 Digit Hexadecimal)"] ""] } {
            lappend opts "-g UserID:[project get "UserID Code (8 Digit Hexadecimal)"]"
        }
    }
    if { [existsBitgenProp "Reset DCM if SHUTDOWN & AGHIGH performed"] } {
        if { [project get "Reset DCM if SHUTDOWN & AGHIGH performed"] } {
            lappend opts "-g DCMShutdown:Enable"
        } else {
            lappend opts "-g DCMShutdown:Disable"
        }
    }
    if { [existsBitgenProp "Disable Bandgap Generator for DCMs to save power"] } {
        if { [project get "Disable Bandgap Generator for DCMs to save power"] } {
            lappend opts "-g DisableBandgap:Yes"
        } else {
            lappend opts "-g DisableBandgap:No"
        }
    }

    set cfvalue ""
    if { [existsBitgenProp "Fallback Reconfiguration"] } {
        set devgroup [project get Family]
        switch -- $devgroup {
            "Virtex7" -
            "Kintex7" -
            "Artix7" {
                if { [existsBitgenProp "Encrypt Bitstream"] } {
                    if { [project get "Encrypt Bitstream"] } {
                        set cfvalue "Disable"
                    }
                }
                if { $cfvalue eq "" } {
                    if { [existsBitgenProp "Starting Address for Fallback Configuration"] } {
                        set startaddr [project get "Starting Address for Fallback Configuration"]
                        if { $startaddr ne "" && $startaddr ne "None" } {
                            set cfvalue "Enable"
                        }
                    }
                }
            }
        }
        if { $cfvalue eq "" } {
            switch -- [project get "Fallback Reconfiguration"] {
                "Enable"  { set cfvalue "Enable" }
                "Disable" { set cfvalue "Disable" }
            }
        }
    }
    if { $cfvalue ne "" } {
        lappend opts "-g ConfigFallback:$cfvalue"
    }

    if { [existsBitgenProp "SelectMAP Abort Sequence"] } {
        switch -- [project get "SelectMAP Abort Sequence"] {
            "Enable"  { lappend opts "-g SelectMAPAbort:Enable" }
            "Disable" { lappend opts "-g SelectMAPAbort:Disable" }
        }
    }
    if { [existsBitgenProp "BPI Reads Per Page"] } {
        switch -- [project get "BPI Reads Per Page"] {
            "1" { lappend opts "-g BPI_page_size:1" }
            "4" { lappend opts "-g BPI_page_size:4" }
            "8" { lappend opts "-g BPI_page_size:8" }
        }
    }
    if { [existsBitgenProp "Cycles for First BPI Page Read"] } {
        switch -- [project get "Cycles for First BPI Page Read"] {
            "1" { lappend opts "-g BPI_1st_read_cycle:1" }
            "2" { lappend opts "-g BPI_1st_read_cycle:2" }
            "3" { lappend opts "-g BPI_1st_read_cycle:3" }
            "4" { lappend opts "-g BPI_1st_read_cycle:4" }
        }
    }
    if { [existsBitgenProp "BPI Sync Mode"] } {
        lappend opts "-g BPI_sync_mode:[project get "BPI Sync Mode"]"
    }
    if { [existsBitgenProp "SPI 32-bit Addressing"] } {
        lappend opts "-g SPI_32bit_addr:[project get "SPI 32-bit Addressing"]"
    }
    if { [existsBitgenProp "Set SPI Configuration Bus Width"] } {
        lappend opts "-g SPI_buswidth:[project get "Set SPI Configuration Bus Width"]"
    }
    if { [existsBitgenProp "Use SPI Falling Edge"] } {
        lappend opts "-g SPI_Fall_Edge:[project get "Use SPI Falling Edge"]"
    }
    if { [existsBitgenProp "Power Down Device if Over Safe Temperature"]} {
        if { [project get "Power Down Device if Over Safe Temperature"] } {
            lappend opts "-g OverTempPowerDown:Enable"
        } else {
            lappend opts "-g OverTempPowerDown:Disable"
        }
    }
    if { [existsBitgenProp "User Access Register Value"] } {
        lappend opts "-g USR_ACCESS:[project get "User Access Register Value"]"
    }
    if { [existsBitgenProp "MultiBoot: Insert IPROG CMD in the Bitfile"] } {
        lappend opts "-g next_config_reboot:[project get "MultiBoot: Insert IPROG CMD in the Bitfile"]"
    }
    if { [existsBitgenProp "MultiBoot: Starting Address for Next Configuration"] } {
        if { ![string equal [project get "MultiBoot: Starting Address for Next Configuration"] ""] } {
            lappend opts "-g next_config_addr:[project get "MultiBoot: Starting Address for Next Configuration"]"
        }
    }
    if { [existsBitgenProp "MultiBoot: Use New Mode for Next Configuration"] } {
        if { [project get "MultiBoot: Use New Mode for Next Configuration"] } {
            lappend opts "-g next_config_new_mode:Yes"
        } else {
            lappend opts "-g next_config_new_mode:No"
        }
    }
    if { [existsBitgenProp "MultiBoot: Next Configuration Mode"] } {
        if { ![string equal [project get "MultiBoot: Next Configuration Mode"] ""] } {
            lappend opts "-g next_config_boot_mode:[project get "MultiBoot: Next Configuration Mode"]"
        }
    }

    if { [existsBitgenProp "Enable External Master Clock"] } {
        switch -- [project get "Enable External Master Clock"] {
            false         { lappend opts "-g ExtMasterCclk_en: No" }
            true          { lappend opts "-g ExtMasterCclk_en: Yes" }
            "Disable"     { lappend opts "-g ExtMasterCclk_en:Disable" }
            "Divide by 8" { lappend opts "-g ExtMasterCclk_en:div-8" }
            "Divide by 4" { lappend opts "-g ExtMasterCclk_en:div-4" }
            "Divide by 2" { lappend opts "-g ExtMasterCclk_en:div-2" }
            "Divide by 1" { lappend opts "-g ExtMasterCclk_en:div-1" }
        }
#        if { [project get "Enable External Master Clock"] } {
            #lappend opts "-g ExtMasterCclk_en:Yes"
        #} else {
            #lappend opts "-g ExtMasterCclk_en:No"
        #}
    }
    if { [existsBitgenProp "Setup External Master Clock Division"] } {
        if { [project get "Setup External Master Clock Division"] } {
            lappend opts "-g ExtMasterCclk_divide:[project get "Setup External Master Clock Division"]"
        }
    }
    if { [existsBitgenProp "ICAP Location Select"] } {
        lappend opts "-g ICAP_select:[project get "ICAP Location Select"]"
    }
    if { [existsBitgenProp "Starting Address for Fallback Configuration"] } {
        if { ![string equal [project get "Starting Address for Fallback Configuration"] ""] } {
            set startaddr [project get "Starting Address for Fallback Configuration"]
            if { $startaddr == "0x00000000" } {
                puts stderr "WARNING: old default value for next_config_addr found ($startaddr). Consider replacing with new default value 'None'."
            }
            lappend opts "-g next_config_addr:$startaddr"
        }
    }

    if { [existsBitgenProp "Watchdog Timer Value"] } {
        switch -- [project get "Watchdog Timer Mode"] {
            "Off"    { }
            "Config" { lappend opts "-g TIMER_CFG:[project get "Watchdog Timer Value"]"}
            "User"   { lappend opts "-g TIMER_USR:[project get "Watchdog Timer Value"]"}
        }
    }

    if { [existsBitgenProp "Watchdog Timer Value"] } {
        switch -- [string tolower [project get Family]] {
            spartan6   -
            spartan6l  -
            aspartan6  -
            qspartan6  -
            qspartan6l {
                lappend opts "-g TIMER_CFG:[project get "Watchdog Timer Value"]"
            }
            default    {
                switch -- [project get "Watchdog Timer Mode"] {
                    "Off"    { }
                    "Config" { lappend opts "-g TIMER_CFG:[project get "Watchdog Timer Value"]"}
                    "User"   { lappend opts "-g TIMER_USR:[project get "Watchdog Timer Value"]"}
                }
            }
        }
    }
    if { [existsBitgenProp "MultiBoot: Starting Address for Golden Configuration"] } {
        if { ![string equal [project get "MultiBoot: Starting Address for Golden Configuration"] ""] } {
            lappend opts "-g golden_config_addr:[project get "MultiBoot: Starting Address for Golden Configuration"]"
        }
    }
    if { [existsBitgenProp "MultiBoot: User-Defined Register for Failsafe Scheme"] } {
        if { ![string equal [project get "MultiBoot: User-Defined Register for Failsafe Scheme"] ""] } {
            lappend opts "-g failsafe_user:[project get "MultiBoot: User-Defined Register for Failsafe Scheme"]"
        }
    }

    if { [existsBitgenProp "Encrypt Key Select"] } {
        switch -- [project get "Encrypt Key Select"] {
            "BBRAM" { lappend opts "-g EncryptKeySelect:bbram" }
            "eFUSE" { lappend opts "-g EncryptKeySelect:efuse" }
        }
    }
    if { [existsBitgenProp "AES Initial Vector"] } {
        if { ![string equal [project get "AES Initial Vector"] ""] } {
            lappend opts "-g StartCBC:[project get "AES Initial Vector"]"
        }
    }
    if { [existsBitgenProp "JTAG to XADC Connection"] } {
        switch -- [project get "JTAG to XADC Connection"] {
            "Enable"     { lappend opts "-g JTAG_XADC:Enable" }
            "Disable"    { lappend opts "-g JTAG_XADC:Disable" }
            "StatusOnly" { lappend opts "-g JTAG_XADC:StatusOnly" }
        }
    }
    if { [existsBitgenProp "JTAG to System Monitor Connection"] } {
        switch -- [project get "JTAG to System Monitor Connection"] {
            "Enable"  { lappend opts "-g JTAG_SysMon:Enable" }
            "Disable" { lappend opts "-g JTAG_SysMon:Disable" }
        }
    }
    if { [existsBitgenProp "Enable Multi-Pin Wake-Up Suspend Mode"] } {
        if { [project get "Enable Multi-Pin Wake-Up Suspend Mode"] } {
            lappend opts "-g multipin_wakeup:Yes"
        } else {
            lappend opts "-g multipin_wakeup:No"
        }
    }
    if { [existsBitgenProp "Mask Pins for Multi-Pin Wake-Up Suspend Mode"] } {
        if { ![string equal [project get "Mask Pins for Multi-Pin Wake-Up Suspend Mode"] ""] } {
            lappend opts "-g wakeup_mask:[project get "Mask Pins for Multi-Pin Wake-Up Suspend Mode"]"
        }
    }
    if { [existsBitgenProp "DCI Update Mode"] } {
        switch -regexp -- [string tolower [project get Family]] {
            artix7 -
            kintex7 -
            zynq -
            spartan3 -
            virtex4 -
            virtex5 -
            virtex6 -
            virtex7 {
                switch -- [project get "DCI Update Mode"] {
                    Continuous     { lappend opts "-g DCIUpdateMode:Continuous" }
                    "As Required"  { lappend opts "-g DCIUpdateMode:AsRequired" }
                    Quiet(Off)     { lappend opts "-g DCIUpdateMode:Quiet" }
                }
            }
        }
    }
    if { [existsBitgenProp "FPGA Start-Up Clock"] } {
        switch -- [project get "FPGA Start-Up Clock"] {
            CCLK         { lappend opts "-g StartUpClk:CClk" }
            "User Clock" { lappend opts "-g StartUpClk:UserClk" }
            "JTAG Clock" { lappend opts "-g StartUpClk:JtagClk" }
        }
    }
    if { [existsBitgenProp "Done (Output Events)"] } {
        switch -- [project get "Done (Output Events)"] {
            "Default (4)" { lappend opts "-g DONE_cycle:4" }
            1             { lappend opts "-g DONE_cycle:1" }
            2             { lappend opts "-g DONE_cycle:2" }
            3             { lappend opts "-g DONE_cycle:3" }
            4             { lappend opts "-g DONE_cycle:4" }
            5             { lappend opts "-g DONE_cycle:5" }
            6             { lappend opts "-g DONE_cycle:6" }
            Keep          { lappend opts "-g DONE_cycle:Keep" }
        }
    }
    if { [existsBitgenProp "Enable Outputs (Output Events)"] } {
        switch -- [project get "Enable Outputs (Output Events)"] {
            "Default (5)" { lappend opts "-g GTS_cycle:5" }
            1             { lappend opts "-g GTS_cycle:1" }
            2             { lappend opts "-g GTS_cycle:2" }
            3             { lappend opts "-g GTS_cycle:3" }
            4             { lappend opts "-g GTS_cycle:4" }
            5             { lappend opts "-g GTS_cycle:5" }
            6             { lappend opts "-g GTS_cycle:6" }
            Done          { lappend opts "-g GTS_cycle:Done" }
            Keep          { lappend opts "-g GTS_cycle:Keep" }
        }
    }
    if { [existsBitgenProp "Release Set/Reset (Output Events)"] } {
        switch -- [project get "Release Set/Reset (Output Events)"] {
            "Default (6)" { lappend opts "-g GSR_cycle:6" }
            1             { lappend opts "-g GSR_cycle:1" }
            2             { lappend opts "-g GSR_cycle:2" }
            3             { lappend opts "-g GSR_cycle:3" }
            4             { lappend opts "-g GSR_cycle:4" }
            5             { lappend opts "-g GSR_cycle:5" }
            6             { lappend opts "-g GSR_cycle:6" }
            Done          { lappend opts "-g GSR_cycle:Done" }
            Keep          { lappend opts "-g GSR_cycle:Keep" }
        }
    }
    if { [existsBitgenProp "Release Write Enable (Output Events)"] } {
        switch -- [project get "Release Write Enable (Output Events)"] {
            "Default (6)" { lappend opts "-g GWE_cycle:6" }
            1             { lappend opts "-g GWE_cycle:1" }
            2             { lappend opts "-g GWE_cycle:2" }
            3             { lappend opts "-g GWE_cycle:3" }
            4             { lappend opts "-g GWE_cycle:4" }
            5             { lappend opts "-g GWE_cycle:5" }
            6             { lappend opts "-g GWE_cycle:6" }
            Done          { lappend opts "-g GWE_cycle:Done" }
            Keep          { lappend opts "-g GWE_cycle:Keep" }
        }
    }
    if { [existsBitgenProp "Wait for DLL Lock (Output Events)"] } {
        switch -- [project get "Wait for DLL Lock (Output Events)"] {
            "Default (NoWait)" { lappend opts "-g LCK_cycle:NoWait" }
            0                  { lappend opts "-g LCK_cycle:0" }
            1                  { lappend opts "-g LCK_cycle:1" }
            2                  { lappend opts "-g LCK_cycle:2" }
            3                  { lappend opts "-g LCK_cycle:3" }
            4                  { lappend opts "-g LCK_cycle:4" }
            5                  { lappend opts "-g LCK_cycle:5" }
            6                  { lappend opts "-g LCK_cycle:6" }
            NoWait             { lappend opts "-g LCK_cycle:NoWait" }
        }
    }
    if { [existsBitgenProp "Wait for DCI Match (Output Events)"] } {
        switch -- [project get "Wait for DCI Match (Output Events)"] {
            "Default (NoWait)" { lappend opts "-g Match_cycle:NoWait" }
            "Auto"             { lappend opts "-g Match_cycle:Auto" }
            0                  { lappend opts "-g Match_cycle:0" }
            1                  { lappend opts "-g Match_cycle:1" }
            2                  { lappend opts "-g Match_cycle:2" }
            3                  { lappend opts "-g Match_cycle:3" }
            4                  { lappend opts "-g Match_cycle:4" }
            5                  { lappend opts "-g Match_cycle:5" }
            6                  { lappend opts "-g Match_cycle:6" }
            NoWait             { lappend opts "-g Match_cycle:NoWait" }
        }
    }
    if { [existsBitgenProp Security] } {
        switch -- [project get Security] {
            "Enable Readback and Reconfiguration"  { lappend opts "-g Security:None" }
            "Disable Readback"  { lappend opts "-g Security:Level1" }
            "Disable Readback and Reconfiguration"  { 
                switch -- [string tolower [project get Family]] {
                    spartan3a -
                    spartan3adsp {
                        lappend opts "-g Security:Level3"
                    }
                    default {
                        lappend opts "-g Security:Level2"
                    }
                }
            }
        }
    }
    if { [existsBitgenProp "Allow SelectMAP Pins to Persist"] } {
        if { [project get "Allow SelectMAP Pins to Persist"] } {
            lappend opts "-g Persist:Yes"
        } else {
            lappend opts "-g Persist:No"
        }
    }
    if { [existsBitgenProp "Create Logic Allocation File"] } {
        if { [project get "Create Logic Allocation File"] } {
            lappend opts "-l"
        }
    }
    if { [existsBitgenProp "Create Mask File"] } {
        if { [project get "Create Mask File"] } {
            lappend opts "-m"
        }
    }
    if { [existsBitgenProp "Essential Bits"] } {
        if { [project get "Essential Bits"] } {
            lappend opts "-g EssentialBits:Yes"
        }
    }
    if { [existsBitgenProp "Revision Select"] } {
        switch -- [project get "Revision Select"] {
            "00" { lappend opts "-g RevisionSelect:00" }
            "01" { lappend opts "-g RevisionSelect:01" }
            "10" { lappend opts "-g RevisionSelect:10" }
            "11" { lappend opts "-g RevisionSelect:11" }
        }
    }
    if { [existsBitgenProp "Revision Select Tristate"] } {
        switch -- [project get "Revision Select Tristate"] {
            "Enable"  { lappend opts "-g RevisionSelect_tristate:Enable" }
            "Disable" { lappend opts "-g RevisionSelect_tristate:Disable" }
        }
    }
    if { [existsBitgenProp "Create ReadBack Data Files"] } {
        if { [project get "Create ReadBack Data Files"] } {
            lappend opts "-g ReadBack"
        }
    }
    if { [existsBitgenProp "Enable Internal Done Pipe"] } {
        if { [project get "Enable Internal Done Pipe"] } {
            lappend opts "-g DonePipe:Yes"
        } else {
            lappend opts "-g DonePipe:No"
        }
    }
    if { [existsBitgenProp "Drive Done Pin High"] } {
        if { [project get "Drive Done Pin High"] } {
            lappend opts "-g DriveDone:Yes"
        } else {
            lappend opts "-g DriveDone:No"
        }
    }
    if { [existsBitgenProp "Encrypt Bitstream"] } {
        if { [project get "Encrypt Bitstream"] } {
            lappend opts "-g Encrypt:Yes"
        } else {
            lappend opts "-g Encrypt:No"
        }
    }
    if { [existsBitgenProp "AES Key (Hex String)"]
         && ![string equal [project get "AES Key (Hex String)"] ""] } {
        lappend opts "-g Key0:[project get "AES Key (Hex String)"]"
    }
    if { [existsBitgenProp "HMAC Key (Hex String)"]
         && ![string equal [project get "HMAC Key (Hex String)"] ""] } {
        lappend opts "-g HKey:[project get "HMAC Key (Hex String)"]"
    }
    if { [existsBitgenProp "Key 1 (Hex String)"]
         && ![string equal [project get "Key 1 (Hex String)"] ""] } {
        lappend opts "-g Key1:[project get "Key 1 (Hex String)"]"
    }
    if { [existsBitgenProp "Key 2 (Hex String)"]
         && ![string equal [project get "Key 2 (Hex String)"] ""] } {
        lappend opts "-g Key2:[project get "Key 2 (Hex String)"]"
    }
    if { [existsBitgenProp "Key 3 (Hex String)"]
         && ![string equal [project get "Key 3 (Hex String)"] ""] } {
        lappend opts "-g Key3:[project get "Key 3 (Hex String)"]"
    }
    if { [existsBitgenProp "Key 4 (Hex String)"]
         && ![string equal [project get "Key 4 (Hex String)"] ""] } {
        lappend opts "-g Key4:[project get "Key 4 (Hex String)"]"
    }
    if { [existsBitgenProp "Key 5 (Hex String)"]
         && ![string equal [project get "Key 5 (Hex String)"] ""] } {
        lappend opts "-g Key5:[project get "Key 5 (Hex String)"]"
    }
    if { [existsBitgenProp "Input Encryption Key File"]
         && ![string equal [project get "Input Encryption Key File"] ""] } {
        lappend opts "-g KeyFile:[project get "Input Encryption Key File"]"
    }
    if { [existsBitgenProp "Starting Key"] } {
        switch -- [project get "Starting Key"] {
            0    { lappend opts "-g StartKey:0" }
            3    { lappend opts "-g StartKey:3" }
            None { }
        }
    }
    if { [existsBitgenProp "Starting CBC Value (Hex)"]
         && ![string equal [project get "Starting CBC Value (Hex)"] ""] } {
        lappend opts "-g StartCBC:[project get "Starting CBC Value (Hex)"]"
    }
    if { [existsBitgenProp "Location of Key 0 in Sequence"] } {
        switch -- [project get "Location of Key 0 in Sequence"] {
            "Single Key (S)" { lappend opts "-g Keyseq0:S" }
            "First (F)"      { lappend opts "-g Keyseq0:F" }
            "Middle (M)"     { lappend opts "-g Keyseq0:M" }
            "Last (L)"       { lappend opts "-g Keyseq0:L" }
            None             { lappend opts "" }
        }
    }
    if { [existsBitgenProp "Location of Key 1 in Sequence"] } {
        switch -- [project get "Location of Key 1 in Sequence"] {
            "Single Key (S)" { lappend opts "-g Keyseq1:S" }
            "First (F)"      { lappend opts "-g Keyseq1:F" }
            "Middle (M)"     { lappend opts "-g Keyseq1:M" }
            "Last (L)"       { lappend opts "-g Keyseq1:L" }
            None             { lappend opts "" }
        }
    }
    if { [existsBitgenProp "Location of Key 2 in Sequence"] } {
        switch -- [project get "Location of Key 2 in Sequence"] {
            "Single Key (S)" { lappend opts "-g Keyseq2:S" }
            "First (F)"      { lappend opts "-g Keyseq2:F" }
            "Middle (M)"     { lappend opts "-g Keyseq2:M" }
            "Last (L)"       { lappend opts "-g Keyseq2:L" }
            None             { lappend opts "" }
        }
    }
    if { [existsBitgenProp "Location of Key 3 in Sequence"] } {
        switch -- [project get "Location of Key 3 in Sequence"] {
            "Single Key (S)" { lappend opts "-g Keyseq3:S" }
            "First (F)"      { lappend opts "-g Keyseq3:F" }
            "Middle (M)"     { lappend opts "-g Keyseq3:M" }
            "Last (L)"       { lappend opts "-g Keyseq3:L" }
            None             { lappend opts "" }
        }
    }
    if { [existsBitgenProp "Location of Key 4 in Sequence"] } {
        switch -- [project get "Location of Key 4 in Sequence"] {
            "Single Key (S)" { lappend opts "-g Keyseq4:S" }
            "First (F)"      { lappend opts "-g Keyseq4:F" }
            "Middle (M)"     { lappend opts "-g Keyseq4:M" }
            "Last (L)"       { lappend opts "-g Keyseq4:L" }
            None             { lappend opts "" }
        }
    }
    if { [existsBitgenProp "Location of Key 5 in Sequence"] } {
        switch -- [project get "Location of Key 5 in Sequence"] {
            "Single Key (S)" { lappend opts "-g Keyseq5:S" }
            "First (F)"      { lappend opts "-g Keyseq5:F" }
            "Middle (M)"     { lappend opts "-g Keyseq5:M" }
            "Last (L)"       { lappend opts "-g Keyseq5:L" }
            None             { lappend opts "" }
        }
    }
    if { [existsBitgenProp "Enable Suspend/Wake Global Set/Reset"] } {
        if { [project get "Enable Suspend/Wake Global Set/Reset"] } {
            lappend opts "-g en_sw_gsr:Yes"
        } else {
            lappend opts "-g en_sw_gsr:No"
        }
    }
    if { [existsBitgenProp "Enable Power-On Reset Detection"] } {
        if { [project get "Enable Power-On Reset Detection"] } {
            lappend opts "-g en_porb:Yes"
        } else {
            lappend opts "-g en_porb:No"
        }
    }
    if { [existsBitgenProp "Drive Awake Pin During Suspend/Wake Sequence"] } {
        if { [project get "Drive Awake Pin During Suspend/Wake Sequence"] } {
            lappend opts "-g drive_awake:Yes"
        } else {
            lappend opts "-g drive_awake:No"
        }
    }
    if { [existsBitgenProp "Wakeup Clock"] } {
        switch -- [project get "Wakeup Clock"] {
            "Startup Clock"  { lappend opts "-g sw_clk:Startupclk" }
            "Internal Clock" { lappend opts "-g sw_clk:Internalclk" }
        }
    }
    if { [existsBitgenProp "GWE Cycle During Suspend/Wakeup Sequence"]
         && ![string equal [project get "GWE Cycle During Suspend/Wakeup Sequence"] ""] } {
        lappend opts "-g sw_gwe_cycle:[project get "GWE Cycle During Suspend/Wakeup Sequence"]"
    }
    if { [existsBitgenProp "GTS Cycle During Suspend/Wakeup Sequence"]
         && ![string equal [project get "GTS Cycle During Suspend/Wakeup Sequence"] ""] } {
        lappend opts "-g sw_gts_cycle:[project get "GTS Cycle During Suspend/Wakeup Sequence"]"
    }

    return $opts
}

