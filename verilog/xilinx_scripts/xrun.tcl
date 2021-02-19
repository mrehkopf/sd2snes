if { [llength $argv] < 2 } {
    puts stderr "Usage: $argv0 <xise project> <process name>"
    exit
}

set projname [lindex $argv 0]
set process [lindex $argv 1]

project open $projname
process run $process

