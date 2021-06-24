set scriptdir [file dirname [file normalize [info script]]]

set ifn main.prj
set ipcoredir ipcore_dir
set tmpdir xst/projnav.tmp

if { [llength $argv] < 1 } {
    puts stderr "Usage: $argv0 <xise project> <output file> \[<prj file> \[<ipcore dir> \[<XST tmp dir>\]\]\]"
    puts stderr "  Defaults: <prj file>:    $ifn"
    puts stderr "            <ipcore dir>:  $ipcoredir"
    puts stderr "            <XST tmp dir>: $tmpdir"
    exit
}

set projfile [lindex $argv 0]
set xfn [lindex $argv 1]

if { ![string equal [lindex $argv 2] ""] } {set ifn [lindex $argv 2]}
if { ![string equal [lindex $argv 3] ""] } {set ipcoredir [lindex $argv 3]}
if { ![string equal [lindex $argv 4] ""] } {set tmpdir [lindex $argv 4]}

project open $projfile

source [file join $scriptdir xgetxstopts.tcl]

set optslist [getxstopts $ifn $ipcoredir $tmpdir]

set xf [open $xfn "w"]

foreach opt $optslist {
    puts $xf $opt
}

close $xf