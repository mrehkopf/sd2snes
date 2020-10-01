set scriptdir [file dirname [file normalize [info script]]]

source $scriptdir/xgetmapopts.tcl
source $scriptdir/xgetparopts.tcl

if { [llength $argv] < 1 } {
    puts stderr "Usage: $argv0 <xise project>"
    exit
}
set projfile [lindex $argv 0]

project open $projfile

set family [string tolower [project get "Family"]]

# Force starting cost table to 1 for SmartXPlorer runs
set mapopts [getmapopts 1]
set paropts [getparopts 1]

set of [open "currentProps.stratfile" "w"]
puts $of "# custom generated SmartXplorer strategy file with current project settings."
puts $of "# Project: [lindex $argv 0]"
puts $of "{"
puts $of "\"$family\"\:"
puts $of "({\"name\"\: \"CurrentProjectNavigatorSettingsCT1\","
puts $of "\"map\"\: \"$mapopts\","
puts $of "\"par\"\: \"$paropts\"},"
puts $of "),"
puts $of "}"
close $of
