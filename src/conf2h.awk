#!/usr/bin/gawk -f

# Trivial little script to convert from a makefile-style configuration
# file to a C header. No copyright claimed.

BEGIN {
  print "// autoconf.h generated from " ARGV[1] " at " strftime() "\n" \
    "#ifndef AUTOCONF_H\n" \
    "#define AUTOCONF_H"
}

/^#/ { sub(/^#/,"//") }

/^\w.*=/ {
  if (/=\s*n$/) {
    sub(/^/,"// ");
  } else {
    sub(/^/,"#define ")
    if (/=\s*y$/) {
      sub(/=.*$/,"")
    } else {
      sub(/=/," ")
    }
  }
}

{ print }

END { print "#endif" }
