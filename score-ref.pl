#!/usr/bin/perl
#
# Score segments in a candidate folder containing original and corrected segments
# with respect to a reference folder containing corresponding reference segments.
# For each triple, the script output whether the score of the corrected segment was
# better/equal/worse than the one of the original segment with respect to the reference translation.
# The scorer can be any process that takes a reference and a candidate segment on stdin (each on a line), and
# returns the score as a number on stdout.
# Use the "invert" option to treat higher score numbers as worse, which is e.g. the case with TER.

use warnings;
use FileHandle;
use IPC::Open3;

if ($#ARGV+1 < 5) {
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
$comparefactor = ($#ARGV+1 >= 6) ? -1.0 : 1.0;

IPC::Open3::open3 (SCORERIN, SCOREROUT, SCORERERR, "$scorer");

#print "$type SCORING of original and corrected segments in $candfolder\n";
#print "-----------------------------------------------\n\n";

#$summary = "";

#@files = <$candfolder/*>;
#foreach $filefull (@files) {
#    next if ($filefull =~ /\.orig$/);
#    next if ($filefull =~ /\.ref$/);
#    next unless ($filefull =~ /^$candfolder\/(.*)$/);
#    $file = $1;

#    @parts = split(/\./, $file);
#    $flagtype = $parts[0] || "";
#    $rulename = $parts[1] || "";
#    print "Flag type $flagtype, rule $rulename\n";
#    print "--------------------------------------------------\n\n";
#    $count = 0;
#    $better = 0;
#    $worse = 0;
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
    $count++;
    print SCORERIN "$ref\n";
    print SCORERIN "$orig\n";
    $scoreorig = <SCOREROUT>;
    chomp $scoreorig;
    print SCORERIN "$ref\n";
    print SCORERIN "$corrected\n";
    $scorecorrected =  <SCOREROUT>;
    chomp $scorecorrected;
#    print "R Reference segment:\nR $ref\n";
#    print "O Original segment: score $scoreorig\nO $orig\n";
#    print "C Corrected segment: score $scorecorrected\nC $corrected\n";
#        if ($scorecorrected*$comparefactor > $scoreorig*$comparefactor) { print "--> BETTER\n"; $better++; }
#        if ($scorecorrected*$comparefactor < $scoreorig*$comparefactor) { print "--> WORSE\n"; $worse++; }
#        if ($scorecorrected == $scoreorig) { print "--> EQUAL\n"; }
    if ($scorecorrected*$comparefactor > $scoreorig*$comparefactor) { $compare = "better"; }
    if ($scorecorrected*$comparefactor < $scoreorig*$comparefactor) { $compare = "worse"; }
    if ($scorecorrected == $scoreorig) { $compare = "equal"; }
    print SCOREFILE, "%s\t%s\t%s\n", $compare, $scoreorig, $scorecorrected;
}
close CORRECTEDFILE;
close ORIGFILE;
close REFFILE;
close SCOREFILE;
    
#    $summary .= sprintf("%s;%s;%d;%d;%d;%d\n", $flagtype, $rulename, $count, $better, $worse, $count-$better-$worse);
#}


close SCORERIN;
close SCOREROUT;


#print "\nSUMMARY ($type score of $candfolder)\n";
#print "-------\n\n";
#print "flag-type;rule-name;#segments;#better;#worse;#equal\n";
#print $summary;
#print "\n\n\n\n";

