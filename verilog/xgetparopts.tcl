proc getparopts {{ct ""}} {
    switch -- [project get "Place & Route Effort Level (Overall)"] {
        Standard { append opts " -ol std" }
        High     { append opts " -ol high" }
    }

    switch -- [project get "Placer Effort Level" ] {
        Standard { append opts " -pl std" }
        High     { append opts " -pl high" }
    }

    switch -- [project get "Router Effort Level" ] {
        Standard { append opts " -rl std" }
        High     { append opts " -rl high" }
    }

    switch -- [project get "Extra Effort (Highest PAR level only)"] {
        None                     { }
        Normal                   { append opts " -xe n" }
        "Continue on Impossible" { append opts " -xe c" }
    }

    if [string equal $ct ""] {
        append opts " -t " [project get "Starting Placer Cost Table (1-100) PAR"]
    } else {
        append opts " -t $ct"
    }

    if { [project get "Ignore User Timing Constraints PAR"] } {
        switch -- [project get "Timing Mode PAR"] {
            "Performance Evaluation" { append opts " -x" }
            "Non Timing Driven"      { append opts " -ntd" }
        }
    }

    if { [project get "Power Reduction PAR"] } {
        append opts " -power on"
    }

    if { ![string equal [project get "Power Activity File PAR"] ""] } {
        append opts " -activityfile " [project get "Power Activity File PAR"]
    }

    return $opts
}