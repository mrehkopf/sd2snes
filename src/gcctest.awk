#! /usr/bin/gawk -f
#
# Parse the output of (avr-)gcc --version for the version number
# and output YES if it is at least 4.3.

{
  match($0, /\) ([0-9]+)\.([0-9]+)\./, ver);
  if (RLENGTH > 0) {
    major = 0+ver[1];
    minor = 0+ver[2];
    if (major > 4 || (major == 4 && minor > 2)) {
      print "YES";
    }
  }
}
