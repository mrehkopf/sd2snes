set scriptdir [file dirname [file normalize [info script]]]
source [file join $scriptdir xcommon.tcl]

proc existsMapProp { name } {
    if { ![info exists ::mapProps] } {
        set ::mapProps [project properties -process "Map"]
    }
    return [existsProp $::mapProps $name]
}

proc getmapopts {{ct ""}} {
    set opts [list]
    switch -- [string tolower [project get Family]] {
        artix7 -
        kintex7 -
        zynq -
        spartan6 -
        virtex5 -
        virtex6 -
        virtex7 {
            if { [existsMapProp "Combinatorial Logic Optimization"] } {
                if { [project get "Combinatorial Logic Optimization"] } {
                    lappend opts "-logic_opt on"
                } else {
                    lappend opts "-logic_opt off"
                }
            }

        }
    }

    set timingdriven "n/a"
    if { [existsMapProp "Perform Timing-Driven Packing and Placement"] } {
        set timingdriven [project get "Perform Timing-Driven Packing and Placement"]
        if { $timingdriven } {
            lappend opts "-timing"
            if { [existsMapProp "Combinatorial Logic Optimization"] } {
                if { [project get "Combinatorial Logic Optimization" ] } {
                    lappend opts "-logic_opt on"
                } else {
                    lappend opts "-logic_opt off"
                }
            }
        }
    }

    if { $timingdriven ne false } {
        set placerEffort ""
        if { [existsMapProp "Map Effort Level"] } {
            set placerEffort [project get "Map Effort Level"]
        }
        if { [existsMapProp "Placer Effort Level"] } {
            set placerEffort [project get "Placer Effort Level"]
        }
        if { $placerEffort ne "" } {
            switch -- $placerEffort {
                Standard { lappend opts "-ol std" }
                High     { lappend opts "-ol high" }
            }
        }

        set extraEffort ""
        if { [existsMapProp "Extra Effort"] } {
            set extraEffort [project get "Extra Effort"]
        }
        if { [existsMapProp "Placer Extra Effort"] } {
            set extraEffort [project get "Placer Extra Effort"]
        }
        if { $extraEffort ne "" } {
            switch -- $extraEffort {
                None                     { }
                Normal                   { lappend opts "-xe n" }
                "Continue on Impossible" { lappend opts "-xe c" }
            }
        }

        if { [existsMapProp "Starting Placer Cost Table (1-100)"] } {
            if [string equal $ct ""] {
                lappend opts "-t [project get "Starting Placer Cost Table (1-100)" -process Map]"
            } else {
                lappend opts "-t $ct"
            }
        }

        if { [existsMapProp "Extra Cost Tables"] } {
            lappend opts "-xt [project get "Extra Cost Tables"]"
        }
    }

    set globalopt ""
    if { [existsMapProp "Global Optimization"] } {
        set globalopt [project get "Global Optimization"]
    }

    set globopt_flag true
    if { $globalopt eq "" || $globalopt eq "Off" } {
        set globopt_flag false
    }
    if { $timingdriven ne false && [existsMapProp "Register Duplication"] 
         && !$globopt_flag } {
        lappend opts "-register_duplication [string tolower [project get "Register Duplication" -process Map]]"
    }

    if { [existsMapProp "Register Ordering"] } {
        switch -exact -- [project get "Register Ordering"] {
            "Off" { lappend opts "-r off" }
            "4"   { lappend opts "-r 4" }
            "8"   { lappend opts "-r 8" }
        }
    }
    if { $globalopt ne "" } {
        switch -exact -- $globalopt {
            "Off"   { lappend opts  "-global_opt off" }
            "Speed" { lappend opts  "-global_opt speed" }
            "Area"  { lappend opts  "-global_opt area" }
            "Power" { lappend opts  "-global_opt power" }
        }
    }

    if { [existsMapProp "Retiming"] } {
        if { [project get "Retiming"] } {
            lappend opts "-retiming on"
        }
    }

    if { [existsMapProp "Equivalent Register Removal"]
        && $globopt_flag } {
        if { [project get "Equivalent Register Removal" -process Map] } {
            lappend opts "-equivalent_register_removal on"
        } else {
            lappend opts "-equivalent_register_removal off"
        }
    }

    if { [existsMapProp "Enable Multi-Threading"] } {
        switch -exact -- [project get "Enable Multi-Threading" -process Map] {
            "Off" { lappend opts "-mt off" }
            "2"   { lappend opts "-mt 2" }
        }
    }

    if { [existsMapProp "Optimization Strategy (Cover Mode)"]} {
        switch -- [project get "Optimization Strategy (Cover Mode)"] {
            Area     { lappend opts "-cm area" }
            Speed    { lappend opts "-cm speed" }
            Balanced { lappend opts "-cm balanced" }
            Off      { }
        }
    }

    if { [project get "Generate Detailed Map Report"] } {
        lappend opts "-detail"
    }

    if { [existsMapProp "Use RLOC Constraints"] } {
        switch -- [project get "Use RLOC Constraints"] {
            "Yes"              { lappend opts "-ir off" }
            "No"               { lappend opts "-ir all" }
            "For Packing Only" { lappend opts "-ir place" }
        }
    }

    if { [project get "Allow Logic Optimization Across Hierarchy"] } {
        lappend opts "-ignore_keep_hierarchy"
    }

    switch -- [project get "Pack I/O Registers/Latches into IOBs"] {
        "For Inputs and Outputs" { lappend opts "-pr b" }
        "For Inputs Only"        { lappend opts "-pr i" }
        "For Outputs Only"       { lappend opts "-pr o" }
        Off                      { lappend opts "-pr off" }
    }

    if { ![project get "Trim Unconnected Signals"] } {
        if { [existsMapProp "Global Optimization"] } {
            if { ![string equal [project get "Global Optimization"] "Off"] } {
                puts stderr "ERROR: \"Global Optimization\" is set to \"[project get "Global Optimization"]\". This is not compatible with -u, please set \"Trim Unconnected Signals\" to ON."
                return false
            }
        }
        lappend opts "-u"
    }

    if { ![string equal [project get "Other Map Command Line Options"] ""] } {
        lappend opts [project get "Other Map Command Line Options"]
    }

    if { $timingdriven eq false && [existsMapProp "CLB Pack Factor Percentage"] } {
        lappend opts "-c [project get "CLB Pack Factor Percentage"]"
    }

    if { [existsMapProp "Timing Mode"] } {
        if { [existsMapProp "Ignore User Timing Constraints"]
             && [project get "Ignore User Timing Constraints" -process Map] } {
            switch -- [project get "Timing Mode" -process Map] {
                "Performance Evaluation" { lappend opts "-x" }
                "Non Timing Driven"      { lappend opts "-ntd" }
            }
        }
    }

    if { [existsMapProp "Maximum Compression"] } {
        if { [project get "Maximum Compression"] } {
            lappend opts "-c 1"
        }
    }

    if { [existsMapProp "LUT Combining"] } {
        switch -- [project get "LUT Combining" -process Map] {
            Off  { lappend opts "-lc off" }
            Auto { lappend opts "-lc auto" }
            Area { lappend opts "-lc area" }
        }
    }

    if { [existsMapProp "Tri-state Buffer Transformation Mode"] } {
        switch -- [project get "Tri-state Buffer Transformation Mode" -process Map] {
            Off        { lappend opts "-tx off" }
            On         { lappend opts "-tx on" }
            Aggressive { lappend opts "-tx aggressive" }
            Limit      { lappend opts "-tx limit" }
        }
    }
    if { [project get "Map Slice Logic into Unused Block RAMs"] } {
        lappend opts "-bp"
    }

    set projProps [project properties]
    if { [existsProp $projProps "Use SmartGuide"] } {
        if { [project get "Use SmartGuide"] } {
            if { [existsProp $projProps "SmartGuide Filename"] } {
                if { [file exist [project get "SmartGuide Filename"]] } {
                    lappend opts "-smartguide \"[project get "SmartGuide Filename"]\""
                } else {
                    puts "INFO: You have enabled SmartGuide but there is not yet a previous implementation to"
                    puts "\tguide from. Project Navigator will run the implementation flow in timing driven"
                    puts "\tmode for this iteration to ensure higher quality guide results on subsequent"
                    puts "\truns. The design will be guided using SmartGuide in the next iteration."
                    if {! $timingdriven } {
                        lappend options "-timing"
                    }
                }
            }
        }
    }

    set poweractivityfile false
    if { $timingdriven ne false && [existsMapProp "Power Reduction"] } {
        switch -exact -- [project get "Power Reduction" -process Map] {
            "false" -
            "Off"           { lappend opts "-power off" }
            "true" -
            "On"            {
                                lappend opts "-power on"
                                set poweractivityfile true
                            }
            "High"          { lappend opts "-power high" }
            "Extra Effort"  { lappend opts "-power xe" }
        }
    }

    if { $poweractivityfile && [existsMapProp "Power Activity File"] } {
        if { ![string equal [project get "Power Activity File" -process Map] ""] } {
            lappend opts "-activityfile " [project get "Power Activity File Map"]
        }
    }

    return $opts
}
