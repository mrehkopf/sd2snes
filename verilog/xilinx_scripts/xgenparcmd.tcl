set scriptdir [file dirname [file normalize [info script]]]

source $scriptdir/xgetparopts.tcl

if { [llength $argv] < 1 } {
    puts stderr "Usage: $argv0 <xise project>"
    exit
}
set projfile [lindex $argv 0]

project open $projfile

puts [join [getparopts]]