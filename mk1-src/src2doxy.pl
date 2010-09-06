#!/usr/bin/perl -w -i~

# src2doxy.pl - create doxygen-compatible comments from readable C source
# Copyright (C) 2008  Ingo Korb <ingo@akana.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License only.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# This script parses a subset of kernel-doc style comments and rewrites
# them as something doxygen will understand.
use strict;

my $incomment = 0;
my $inspecialcomment = 0;
my @postcomment = ();
my @outputstack;

while (<>) {
    my $filename;
    ($filename = $ARGV) =~ s!.*/!!;

    chomp;
    s/\r$//;
    s/\s+$//;

    # doxygen is too stupid to understand after-the-variable comments
    # without external help. WARNING: Will substitute within strings!
    s!([^ \t]\s+)/// !$1///< !;
    
    $incomment = 1 if m!^/\*!;
    if (m!^/\*\*$!) {
        $inspecialcomment = 1;
        # Kill output
        $_ = "";
        next;
    }

    if ($incomment) {
        if (m!\*/$!) {
            # End of comment
            $incomment = 0;
            $inspecialcomment = 0;
            @outputstack = @postcomment;
            @postcomment = ();
        } elsif (/$filename:\s+(.*).?\s*$/) {
            # Add file description
            push @postcomment, "\n/*! \\file $ARGV\n * \\brief $1. */\n";
        }
        if ($inspecialcomment == 1) {
            # First line of special comment: Brief description
            $inspecialcomment = 2;
            m/^\s*\*\s*((struct |union )?[^: \t]+):?\s+-?\s*(.*)\s*$/;
            $_ = "/*! \\brief $3\n *";
        } elsif ($inspecialcomment == 2) {
            # Modify parameters
            s/\@([^: \t]+)\s*:\s+(.*)\s*$/\\param $1 $2/;
        }
    }
} continue {
    print "$_\n";
    while (scalar(@outputstack)) {
        print shift @outputstack,"\n";
    }
}

