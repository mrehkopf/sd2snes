set scriptdir [file dirname [file normalize [info script]]]
source [file join $scriptdir xcommon.tcl]

proc existsXstProp { name } {
    if { ![info exists ::xstProps] } {
        set ::xstProps [project properties -process "Synthesize (XST)"]
    }
    return [existsProp $::xstProps $name]
}

proc getxstopts { ifn ipcoredir tmpdir } {
    set opts [list]

    lappend opts "set -tmpdir \"$tmpdir\""
    lappend opts "set -xsthdpdir \"xst\""

    lappend opts "run"
    lappend opts "-ifn $ifn"
    lappend opts "-ifmt mixed"
    lappend opts "-ofn [project get "Output File Name"]"
    lappend opts "-ofmt NGC"
    lappend opts "-p [project get Device][project get "Speed Grade"][project get Package]"

    if { ![string equal [project get "Implementation Top Instance Path"] ""] } {
        set toppath [project get "Implementation Top Instance Path"]
        set topmodule [regsub {^/(.*$)} $toppath {\1}]
        lappend opts "-top $topmodule"
    }

    switch -- [project get "Optimization Goal"] {
        Speed { lappend opts "-opt_mode Speed" }
        Area  { lappend opts "-opt_mode Area" }
    }

    switch -- [project get "Optimization Effort" ] {
        Normal { lappend opts "-opt_level 1" }
        High   { lappend opts "-opt_level 2" }
        Fast   { lappend opts "-opt_level 0" }
    }

    if { [existsXstProp "Power Reduction"] } {
        if { [project get "Power Reduction" -process "Synthesize (XST)"] } {
            lappend opts "-power YES"
        } else {
            lappend opts "-power NO"
        }
    }

    if { [existsXstProp "Synthesis Constraints File"]
         && ![string equal [project get "Synthesis Constraints File"] ""] } {
        lappend opts "-uc \"[project get "Synthesis Constraints File"]\""
    }

    if { [existsXstProp "Use Synthesis Constraints File"] } {
        if { [project get "Use Synthesis Constraints File"] } {
            lappend opts "-iuc NO"
        } else {
            lappend opts "-iuc YES"
        }
    }

    if { [existsXstProp "Library Search Order"]
        && ![string equal [project get "Library Search Order"] ""] } {
        lappend opts "-lso \"[project get "Library Search Order"]\""
    }

    if { [existsXstProp "Keep Hierarchy"] } {
        switch -- [project get "Keep Hierarchy"] {
            Yes  { lappend opts "-keep_hierarchy Yes" }
            No   { lappend opts "-keep_hierarchy No" }
            Soft { lappend opts "-keep_hierarchy Soft" }
        }
    }

    if { [existsXstProp "Netlist Hierarchy"] } {
        switch -- [project get "Netlist Hierarchy"] {
            "As Optimized" { lappend opts "-netlist_hierarchy As_Optimized" }
            Rebuilt        { lappend opts "-netlist_hierarchy Rebuilt" }
        }
    }
    if { [existsXstProp "Generate RTL Schematic"] } {
        lappend opts "-rtlview [project get "Generate RTL Schematic"]"
    }

    if { [existsXstProp "Global Optimization Goal"] } {
        switch -- [project get "Global Optimization Goal"] {
            "AllClockNets"     { lappend opts "-glob_opt AllClockNets" }
            "Inpad To Outpad"  { lappend opts "-glob_opt Inpad_To_Outpad" }
            "Offset In Before" { lappend opts "-glob_opt Offset_In_Before" }
            "Offset Out After" { lappend opts "-glob_opt Offset_Out_After" }
            "Maximum Delay"    { lappend opts "-glob_opt Max_Delay" }
        }
    }

    if { [existsXstProp "Read Cores"] } {
        if { [project get "Read Cores"] } {
            lappend opts "-read_cores YES"
        } else {
            lappend opts "-read_cores NO"
        }
    }

    if { [existsXstProp "Cores Search Directories"] } {
        if { ![string equal $ipcoredir ""] } {
            lappend opts "-sd \{\"$ipcoredir\"\}"
        }
    }

    if { [existsXstProp "Write Timing Constraints"] } {
        if { [project get "Write Timing Constraints"] } {
            lappend opts "-write_timing_constraints YES"
        } else {
            lappend opts "-write_timing_constraints NO"
        }
    }

    if { [existsXstProp "Cross Clock Analysis"] } {
        if { [project get "Cross Clock Analysis"] } {
            lappend opts "-cross_clock_analysis YES"
        } else {
            lappend opts "-cross_clock_analysis NO"
        }
    }

    if { [existsXstProp "Hierarchy Separator"] } {
        switch -- [project get "Hierarchy Separator"] {
            "_" { lappend opts "-hierarchy_separator _" }
            "/" { lappend opts "-hierarchy_separator /" }
        }
    }

    if { [existsXstProp "Bus Delimiter"] } {
        switch -- [project get "Bus Delimiter"] {
            "<>" { lappend opts "-bus_delimiter \<\>" }
            "[]" { lappend opts "-bus_delimiter \[\]" }
            "{}" { lappend opts "-bus_delimiter \{\}" }
            "()" { lappend opts "-bus_delimiter \(\)" }
        }
    }

    if { [existsXstProp "Case"] } {
        switch -- [project get "Case"] {
            Maintain { lappend opts "-case Maintain" }
            Lower    { lappend opts "-case Lower" }
            Upper    { lappend opts "-case Upper" }
        }
    }

    if { [existsXstProp "Slice Utilization Ratio"] } {
        lappend opts "-slice_utilization_ratio [project get "Slice Utilization Ratio"]"
    }

    if { [existsXstProp "BRAM Utilization Ratio"] } {
        lappend opts "-bram_utilization_ratio [project get "BRAM Utilization Ratio"]"
    }

    if { [existsXstProp "DSP Utilization Ratio"] } {
        lappend opts "-dsp_utilization_ratio [project get "DSP Utilization Ratio"]"
    }

    if { [existsXstProp "LUT Combining"] } {
        switch -- [project get "LUT Combining"] {
            No   { lappend opts "-lc Off"  }
            Auto { lappend opts "-lc Auto" }
            Area { lappend opts "-lc Area" }
        }
    }

    if { [existsXstProp "Reduce Control Sets"] } {
        switch -- [project get "Reduce Control Sets"] {
            No   { lappend opts "-reduce_control_sets Off"  }
            Auto { lappend opts "-reduce_control_sets Auto" }
        }
    }

    if { [existsXstProp "Verilog 2001"] } {
        if { [project get "Verilog 2001"] } {
            lappend opts "-verilog2001 YES"
        } else {
            lappend opts "-verilog2001 NO"
        }
    }

    if { [existsXstProp "Verilog Include Directories"] } {
        if { ![string equal [project get "Verilog Include Directories"] ""] } {
            set vIncludePaths [split [project get "Verilog Include Directories"] "|"]
            foreach vIncPath $vIncludePaths {
                set vIncPath [string trimleft [string trimright $vIncPath]]
                append vIncOpts " \"$vIncPath\""
            }
            lappend opts "-vlgincdir \{$vIncOpts \}"
        }
    }

    if { [existsXstProp "Generics, Parameters"] } {
        if { ![string equal [project get "Generics, Parameters"] ""] } {
        set xstGenericsParameters [split [project get "Generics, Parameters"] "|"]
        foreach xstGenericsParameter $xstGenericsParameters {
            set xstGenericsParameter [string trimleft [string trimright $xstGenericsParameter]]
            append xstGenericsOptions " $xstGenericsParameter"
        }
        lappend opts "-generics \{$xstGenericsOptions \}"
        }
    }

    if { [existsXstProp "Verilog Macros"] } {
        if { ![string equal [project get "Verilog Macros"] ""] } {
            set xstVerilogMacros [ split [project get "Verilog Macros"] "|"]
            foreach xstVerilogMacro $xstVerilogMacros {
                set xstVerilogMacro [string trimleft $xstVerilogMacro ]
                set xstVerilogMacro [string trimright $xstVerilogMacro ]
                append xstVerilogMacroOptions " $xstVerilogMacro"
            }
            lappend opts "-define \{$xstVerilogMacroOptions \}"
        }
    }

    if { [existsXstProp "FSM Encoding Algorithm" ]} {
        switch -- [project get "FSM Encoding Algorithm"]) {
            Auto       { lappend opts "-fsm_extract YES -fsm_encoding Auto" }
            "One-Hot"  { lappend opts "-fsm_extract YES -fsm_encoding One-Hot" }
            Compact    { lappend opts "-fsm_extract YES -fsm_encoding Compact" }
            Sequential { lappend opts "-fsm_extract YES -fsm_encoding Sequential" }
            Gray       { lappend opts "-fsm_extract YES -fsm_encoding Gray" }
            Johnson    { lappend opts "-fsm_extract YES -fsm_encoding Johnson" }
            User       { lappend opts "-fsm_extract YES -fsm_encoding User" }
            Speed1     { lappend opts "-fsm_extract YES -fsm_encoding Speed1" }
            None       { lappend opts "-fsm_extract NO" }
        }
    }

    if { [existsXstProp "Safe Implementation"]
         && ![string equal [project get "Safe Implementation"] ""] } {
        lappend opts "-safe_implementation [project get "Safe Implementation"]"
    }

    if { [existsXstProp "Case Implementation Style"] } {
        switch -- [project get "Case Implementation Style"] {
            None            { }
            Full            { lappend opts "-vlgcase Full" }
            Parallel        { lappend opts "-vlgcase Parallel" }
            "Full-Parallel" { lappend opts "-vlgcase Full-Parallel" }
        }
    }

    if { [existsXstProp "FSM Style"] } {
        switch -- [project get "FSM Style"] {
            LUT  { lappend opts "-fsm_style LUT" }
            Bram { lappend opts "-fsm_style Bram" }
        }
    }

    if { [existsXstProp "RAM Extraction" ]} {
        if { [project get "RAM Extraction"] } {
            lappend opts "-ram_extract Yes"
        } else {
            lappend opts "-ram_extract No"
        }
    }

    if { [existsXstProp "RAM Style"] } {
        lappend opts "-ram_style [project get "RAM Style"]"
    }

    if { [existsXstProp "ROM Extraction"] } {
        if { [project get "ROM Extraction"] } {
            lappend opts "-rom_extract Yes"
        } else {
            lappend opts "-rom_extract No"
        }
    }

    if { [existsXstProp "Mux Style"] } {
        lappend opts "-mux_style [project get "Mux Style"]"
    }

    if { [existsXstProp "Decoder Extraction"] } {
        if { [project get "Decoder Extraction"] } {
            lappend opts "-decoder_extract Yes"
        } else {
            lappend opts "-decoder_extract No"
        }
    }

    if { [existsXstProp "Priority Encoder Extraction"] } {
        switch -- [project get "Priority Encoder Extraction"] {
            Yes   { lappend opts "-priority_extract Yes" }
            No    { lappend opts "-priority_extract No" }
            Force { lappend opts "-priority_extract Force" }
        }
    }

    if { [existsXstProp "Shift Register Extraction"] } {
        if { [project get "Shift Register Extraction"] } {
            lappend opts "-shreg_extract Yes"
        } else {
            lappend opts "-shreg_extract No"
        }
    }

    if { [existsXstProp "Logical Shifter Extraction"] } {
        if { [project get "Logical Shifter Extraction"] } {
            lappend opts "-shift_extract Yes"
        } else {
            lappend opts "-shift_extract No"
        }
    }

    if { [existsXstProp "XOR Collapsing"] } {
        if { [project get "XOR Collapsing"] } {
            lappend opts "-xor_collapse Yes"
        } else {
            lappend opts "-xor_collapse No"
        }
    }

    if { [existsXstProp "ROM Style"] } {
        lappend opts "-rom_style [project get "ROM Style"]"
    }

    if { [existsXstProp "Automatic BRAM Packing"] } {
        if { [project get "Automatic BRAM Packing"] } {
            lappend opts "-auto_bram_packing Yes"
        } else {
            lappend opts "-auto_bram_packing No"
        }
    }

    if { [existsXstProp "Mux Extraction"] } {
        switch -- [project get "Mux Extraction"]) {
            Yes   { lappend opts "-mux_extract Yes" }
            No    { lappend opts "-mux_extract No" }
            Force { lappend opts "-mux_extract Force" }
        }
    }

    if { [existsXstProp "Resource Sharing"] } {
        if { [project get "Resource Sharing"] } {
            lappend opts "-resource_sharing Yes"
        } else {
            lappend opts "-resource_sharing No"
        }
    }

    if { [existsXstProp "Asynchronous To Synchronous"] } {
        if { [project get "Asynchronous To Synchronous"] } {
            lappend opts "-async_to_sync Yes"
        } else {
            lappend opts "-async_to_sync No"
        }
    }

    if { [existsXstProp "Multiplier Style"] } {
        switch -- [project get "Multiplier Style"] {
            Auto     { lappend opts "-mult_style Auto" }
            Block    { lappend opts "-mult_style Block" }
            LUT      { lappend opts "-mult_style LUT" }
            Pipe_LUT { lappend opts "-mult_style Pipe_LUT" }
        }
    }

    if { [existsXstProp "Use DSP48"] } {
        switch -- [project get "Use DSP48"] {
            Auto    { lappend opts "-use_dsp48 Auto" }
            Automax { lappend opts "-use_dsp48 Automax" }
            Yes     { lappend opts "-use_dsp48 Yes" }
            No      { lappend opts "-use_dsp48 No" }
        }
    }

    if { [existsXstProp "Add I/O Buffers"] } {
        if { [project get "Add I/O Buffers"] } {
            lappend opts "-iobuf YES"
        } else {
            lappend opts "-iobuf NO"
        }
    }

    if { [existsXstProp "Max Fanout"] } {
        lappend opts "-max_fanout [project get "Max Fanout"]"
    }

    if { [existsXstProp "Number of Clock Buffers"] } {
        lappend opts "-bufg [project get "Number of Clock Buffers"]"
    }

    if { [existsXstProp "Number of Regional Clock Buffers"] } {
        lappend opts "-bufr [project get "Number of Regional Clock Buffers"]"
    }

    if { [existsXstProp "Register Duplication"] } {
        if { [project get "Register Duplication" -process "Synthesize (XST)"] } {
            lappend opts "-register_duplication YES"
        } else {
            lappend opts "-register_duplication NO"
        }
    }

    if { [existsXstProp "Register Balancing"] } {
        lappend opts "-register_balancing [project get "Register Balancing"]"
    }

    if { [existsXstProp "Move First Flip-Flop Stage"] } {
        if { [project get "Move First Flip-Flop Stage"] } {
            lappend opts "-move_first_stage YES"
        } else {
            lappend opts "-move_first_stage NO"
        }
    }

    if { [existsXstProp "Move Last Flip-Flop Stage"] } {
        if { [project get "Move Last Flip-Flop Stage"] } {
            lappend opts "-move_last_stage YES"
        } else {
            lappend opts "-move_last_stage NO"
        }
    }

    if { [existsXstProp "Slice Packing"] } {
        if { [project get "Slice Packing"] } {
            lappend opts "-slice_packing YES"
        } else {
            lappend opts "-slice_packing NO"
        }
    }

    if { [existsXstProp "Optimize Instantiated Primitives"] } {
        if { [project get "Optimize Instantiated Primitives"] } {
            lappend opts "-optimize_primitives YES"
        } else {
            lappend opts "-optimize_primitives NO"
        }
    }

    if { [existsXstProp "Convert Tristates To Logic"] } {
        lappend opts "-tristate2logic [project get "Convert Tristates To Logic"]"
    }

    if { [existsXstProp "Use Clock Enable"] } {
        lappend opts "-use_clock_enable [project get "Use Clock Enable"]"
    }

    if { [existsXstProp "Use Synchronous Set"] } {
        lappend opts "-use_sync_set [project get "Use Synchronous Set"]"
    }

    if { [existsXstProp "Use Synchronous Reset"] } {
        lappend opts "-use_sync_reset [project get "Use Synchronous Reset"]"
    }

    if { [existsXstProp "Pack I/O Registers into IOBs"] } {
        switch -- [project get "Pack I/O Registers into IOBs"] {
            Auto { lappend opts "-iob Auto" }
            Yes  { lappend opts "-iob True" }
            No   { lappend opts "-iob False" }
        }
    }

    if { [existsXstProp "Equivalent Register Removal"] } {
        if { [project get "Equivalent Register Removal"] } {
            lappend opts "-equivalent_register_removal YES"
        } else {
            lappend opts "-equivalent_register_removal NO"
        }
    }

    lappend opts "-slice_utilization_ratio_maxmargin 5"
    return $opts
}

