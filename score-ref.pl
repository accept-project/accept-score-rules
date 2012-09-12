#!/usr/bin/perl
#
# Automatically score segments in parallel files containing translations of
# original and corrected segments with respect to parallel reference file
# containing corresponding reference segments.
#
# For each triple, the script outputs whether the score of the corrected 
# segment was better/equal/worse than the one of the original segment 
# with respect to the reference translation, followed by the score of the
# original segment, followed by the score of the corrected segment.
# This results in a parallel scoring file.
#
# The scorer can be any process that takes a reference and a candidate 
# segment on stdin (each on a line), and returns the score as a number 
# on stdout. Use the "--invert" option to treat higher score numbers as 
# worse, which is e.g. the case with TER.

use warnings;
use FileHandle;
use IPC::Open3;

if (scalar(@ARGV) < 5) {
    print "$0 <scorer-cmd-with-args> <origfile> <correctedfile> <scorefile> <reffile> [--invert]\n";
    exit -1;
}

sub trim {
    my $str = shift;
    chomp $str;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//; 
    return $str;
}

$scorer = $ARGV[0];
$fnameO = $ARGV[1];
$fnameC = $ARGV[2];
$fnameS = $ARGV[3];
$fnameR = $ARGV[4];
$comparefactor = (scalar(@ARGV) >= 6) ? -1.0 : 1.0;

IPC::Open3::open3 (SCORERIN, SCOREROUT, SCORERERR, "$scorer");

open ORIGFILE, "$fnameO";
open CORRECTEDFILE, "$fnameC";
open SCOREFILE, ">$fnameS";
open REFFILE, "$fnameR";
while ($corrected = <CORRECTEDFILE>) {
    $corrected = trim($corrected);
    if (!($orig = <ORIGFILE>)) { die "$fnameO is shorter than $file!"; }
    $orig = trim($orig);
    if (!($ref = <REFFILE>)) { die "$fnameR is shorter than $file!"; }
    $ref = trim($ref);
    print SCORERIN "$ref\n";
    print SCORERIN "$orig\n";
    $scoreorig = <SCOREROUT>;
    chomp $scoreorig;
    print SCORERIN "$ref\n";
    print SCORERIN "$corrected\n";
    $scorecorrected =  <SCOREROUT>;
    chomp $scorecorrected;
    if ($scorecorrected*$comparefactor > $scoreorig*$comparefactor) { $compare = "better"; }
    if ($scorecorrected*$comparefactor < $scoreorig*$comparefactor) { $compare = "worse"; }
    if ($scorecorrected == $scoreorig) { $compare = "equal"; }
    print SCOREFILE sprintf("%s\t%s\t%s\n", $compare, $scoreorig, $scorecorrected);
}
close CORRECTEDFILE;
close ORIGFILE;
close REFFILE;
close SCOREFILE;
    
close SCORERIN;
close SCOREROUT;


