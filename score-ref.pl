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

if ($#ARGV+1 < 4) {
    print "$0 <scorer-name> <scorer-cmd-with-args> <cand-folder> <ref-folder> [invert]\n";
    exit -1;
}

sub trim {
    my $str = shift;
    chomp $str;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//; 
    return $str;
}

$type = $ARGV[0];
$scorer = $ARGV[1];
$candfolder = $ARGV[2];
$reffolder = $ARGV[3];
$comparefactor = ($#ARGV+1 >= 5) ? -1.0 : 1.0;

IPC::Open3::open3 (SCORERIN, SCOREROUT, SCORERERR, "$scorer");

print "$type SCORING of original and corrected segments in $candfolder\n";
print "-----------------------------------------------\n\n";

$summary = "";

@files = <$candfolder/*>;
foreach $filefull (@files) {
    next if ($filefull =~ /\.orig$/);
    next if ($filefull =~ /\.ref$/);
    next unless ($filefull =~ /^$candfolder\/(.*)$/);
    $file = $1;

    @parts = split(/\./, $file);
    $flagtype = $parts[0] || "";
    $rulename = $parts[1] || "";
    print "Flag type $flagtype, rule $rulename\n";
    print "--------------------------------------------------\n\n";
    $count = 0;
    $better = 0;
    $worse = 0;
    open CORRECTEDFILE, "$candfolder/$file";
    open ORIGFILE, "$candfolder/$file.orig";
    open REFFILE, "$reffolder/$file.ref";
    while ($corrected = <CORRECTEDFILE>) {
        $corrected = trim($corrected);
        if (!($orig = <ORIGFILE>)) { die "$file.orig is shorter than $file!"; }
        $orig = trim($orig);
        if (!($ref = <ORIGFILE>)) { die "$file.ref is shorter than $file!"; }
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
        print "R Reference segment:\nR $ref\n";
        print "O Original segment: score $scoreorig\nO $orig\n";
        print "C Corrected segment: score $scorecorrected\nC $corrected\n";
        if ($scorecorrected*$comparefactor > $scoreorig*$comparefactor) { print "--> BETTER\n"; $better++; }
        if ($scorecorrected*$comparefactor < $scoreorig*$comparefactor) { print "--> WORSE\n"; $worse++; }
        if ($scorecorrected == $scoreorig) { print "--> EQUAL\n"; }
        print "\n";   
    }
    close CORRECTEDFILE;
    close ORIGFILE;
    $summary .= sprintf("%s;%s;%d;%d;%d;%d\n", $flagtype, $rulename, $count, $better, $worse, $count-$better-$worse);
}


close SCORERIN;
close SCOREROUT;


print "\nSUMMARY ($type score of $candfolder)\n";
print "-------\n\n";
print "flag-type;rule-name;#segments;#better;#worse;#equal\n";
print $summary;
print "\n\n\n\n";

