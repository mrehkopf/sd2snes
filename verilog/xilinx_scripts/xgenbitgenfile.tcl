set scriptdir [file dirname [file normalize [info script]]]

if { [llength $argv] < 1 } {
    puts stderr "Usage: $argv0 <xise project> <output file>"
    exit
}

set projfile [lindex $argv 0]
set utfn [lindex $argv 1]

project open $projfile

source [file join $scriptdir xgetbitgenopts.tcl]

set optslist [getbitgenopts]

set utf [open $utfn "w"]

foreach opt $optslist {
    puts $utf $opt
}
close $utf
