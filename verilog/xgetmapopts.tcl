proc getmapopts {{ct ""}} {
    if { [project get "Perform Timing-Driven Packing and Placement" ] } {
        append opts " -timing"
        switch -- [project get "Map Effort Level"] {
            Standard { append opts " -ol std" }
            High     { append opts " -ol high" }
        }

        switch -- [project get "Extra Effort"] {
            None                     { }
            Normal                   { append opts " -xe n" }
            "Continue on Impossible" { append opts " -xe c" }
        }
        if [string equal $ct ""] {
            append opts " -t " [project get "Starting Placer Cost Table (1-100) Map"]
        } else {
            append opts " -t $ct"
        }

        append opts " -register_duplication " [string tolower [project get "Register Duplication" -process Map]]

        if { [project get "Combinatorial Logic Optimization"] } {
            append opts " -logic_opt on"
        } else {
            append opts " -logic_opt off"
        }
    } else {
        append opts " -c " [project get "CLB Pack Factor Percentage"]
    }

    switch -- [project get "Optimization Strategy (Cover Mode)"] {
        Area     { append opts " -cm area" }
        Speed    { append opts " -cm speed" }
        Balanced { append opts " -cm balanced" }
        Off      { }
    }

    if { [project get "Generate Detailed Map Report"] } {
        append opts " -detail"
    }

    switch -- [project get "Use RLOC Constraints"] {
        "Yes"              { append opts " -ir off" }
        "No"               { append opts " -ir all" }
        "For Packing Only" { append opts " -ir place" }
    }

    if { [project get "Allow Logic Optimization Across Hierarchy"] } {
        append opts " -ignore_keep_hierarchy"
    }

    switch -- [project get "Pack I/O Registers/Latches into IOBs"] {
        "For Inputs and Outputs" { append opts " -pr b" }
        "For Inputs Only"        { append opts " -pr i" }
        "For Outputs Only"       { append opts " -pr o" }
        Off                      { append opts " -pr off" }
    }

    if { [project get "Trim Unconnected Signals"] } {
        append opts " -u"
    }

    if { ![string equal [project get "Other Map Command Line Options"] ""] } {
        append opts " " [project get "Other Map Command Line Options"]
    }

    if { [project get "Ignore User Timing Constraints Map"] } {
        switch -- [project get "Timing Mode Map"] {
            "Performance Evaluation" { append opts " -x" }
            "Non Timing Driven"      { append opts " -ntd" }
        }
    }
    if { [project get "Map Slice Logic"] } {
        append opts " -bp"
    }

    switch -exact -- [project get "Power Reduction Map"] {
        "false" -
        "Off"          { append opts " -power off" }
        "true" -
        "On"           { append opts " -power on" }
        "High"         { append opts " -power high" }
        "Extra Effort" { append opts " -power xe" }
    }

    if { ![string equal [project get "Power Activity File Map"] ""] } {
        append opts " -activityfile " [project get "Power Activity File Map"]
    }

    return $opts
}
