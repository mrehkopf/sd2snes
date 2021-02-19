set scriptdir [file dirname [file normalize [info script]]]
source [file join $scriptdir xcommon.tcl]

proc existsParProp { name } {
    if { ![info exists ::parProps] } {
        set ::parProps [project properties -process "Place & Route"]
    }
    return [existsProp $::parProps $name]
}

proc getparopts {{ct ""}} {
    set opts [list]

    set placereffortoverride false
    if { [existsParProp "Placer Effort Level"] } {
        set placereffortoverride true
        switch -- [project get "Placer Effort Level" ] {
            None     { set placereffortoverride false }
            Standard { lappend opts "-pl std" }
            High     { lappend opts "-pl high" }
        }
    }
    set routereffortoverride false
    if { [existsParProp "Router Effort Level"] } {
        set routereffortoverride true
        switch -- [project get "Router Effort Level" ] {
            None     { set routereffortoverride false }
            Standard { lappend opts "-rl std" }
            High     { lappend opts "-rl high" }
        }
    }

    if { !($placereffortoverride && $routereffortoverride) } {
        if { [existsParProp "Place & Route Effort Level (Overall)"] } {
            switch -- [project get "Place & Route Effort Level (Overall)"] {
                Standard { lappend opts "-ol std" }
                High     { lappend opts "-ol high" }
            }
        }
    }

    if { [existsParProp "Extra Effort (Highest PAR level only)"] } {
        switch -- [project get "Extra Effort (Highest PAR level only)"] {
            None                     { }
            Normal                   { lappend opts "-xe n" }
            "Continue on Impossible" { lappend opts "-xe c" }
        }
    }

    if { [existsParProp "Starting Placer Cost Table (1-100)"] } {
        if [string equal $ct ""] {
            lappend opts "-t [project get "Starting Placer Cost Table (1-100)" -process "Place & Route"]"
        } else {
            lappend opts "-t $ct"
        }
    }

    set projProps [project properties]
    if { [existsProp $projProps "Use SmartGuide"] } {
        if { [project get "Use SmartGuide"] } {
            if { [existsProp $projProps "SmartGuide Filename"] } {
                if { [file exist [project get "SmartGuide Filename"]] } {
                    llappend opts "-smartguide \"[project get "SmartGuide Filename"]\""
                }
            }
        }
    }

    if { [existsParProp "Ignore User Timing Constraints"] } {
        if { [project get "Ignore User Timing Constraints" -process "Place & Route"] } {
            if { [existsParProp "Timing Mode"] } {
                switch -- [project get "Timing Mode" -process "Place & Route"] {
                    "Performance Evaluation" { lappend opts "-x" }
                    "Non Timing Driven"      { lappend opts "-ntd" }
                }
            }
        }
    }

    if { [existsParProp "Power Reduction"] } {
        if { [project get "Power Reduction" -process "Place & Route"] } {
            lappend opts "-power on"
            if { [existsParProp "Power Activity File"] } {
                if { ![string equal [project get "Power Activity File" -process "Place & Route"] ""] } {
                    lappend opts "-activityfile " [project get "Power Activity File PAR"]
                }
            }
        }
    }

    if { [existsParProp "Enable Multi-Threading]"] } {
        switch -exact -- [project get "Enable Multi-Threading"] {
            "Off" { lappend opts "-mt off" }
            "2"   { lappend opts "-mt 2"   }
            "3"   { lappend opts "-mt 3"   }
            "4"   { lappend opts "-mt 4"   }
        }
    }

    if { ![string equal [project get "Other Place & Route Command Line Options"] ""] } {
        lappend opts "[project get "Other Place & Route Command Line Options"]"
    }

    return $opts
}