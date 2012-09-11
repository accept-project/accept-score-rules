#!/usr/bin/perl
#
# Score segments of a folder containing original and corrected segments using KenLM and a given language model.
# The output contains the scores, as well as the BETTER/WORSE/EQUAL ranking for each segment.
# Some aggregated statistics (group by rule) are printed at the end.

use warnings;
use FileHandle;
use IPC::Open3;

if ($#ARGV+1 < 4) {
    print "$0 <origfile> <correctedfile> <scorefile> <language model file>\n";
    exit -1;
}

sub get_score
{
    my $result = shift;
    chomp ($result);
    if ($result =~ /Total:\s+(\S+)\s+OOV:/) {
	return $1;
    }
    return -1000.0;
}

sub trim {
    my $str = shift;
    chomp $str;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//; 
    return $str;
}

$fnameO = $ARGV[0];
$fnameC = $ARGV[1];
$fnameS = $ARGV[2];
$lm = $ARGV[3];

#$scorer = "$MOSES_DIR/irstlm/bin/score-lm -lm $lm";
$scorer = "$MOSES_DIR/kenlm/query $lm";
IPC::Open3::open3 (SCORERIN, SCOREROUT, SCORERERR, "$scorer");

#print "LM SCORING of original and corrected segments in $subfolder\n";
#print "---------------------------------------------\n\n";

$summary = "";

#@files = <$subfolder/*>;
#foreach $file (@files) {
#    next if ($file =~ /\.orig$/);
#    next unless ($file =~ /^$subfolder\/(.*)$/);
#    @parts = split(/\./, $1);
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
while ($corrected = <CORRECTEDFILE>) {
    $corrected = trim($corrected);        
    if (!($orig = <ORIGFILE>)) { die "$fnameO is shorter than $fnameC!"; };
    $orig = trim($orig);
    $count++;
    print SCORERIN "<s> $orig </s>\n";
    $scoreorigres = <SCOREROUT>;
    $scoreorig = get_score($scoreorigres);
    print SCORERIN "<s> $corrected </s>\n";
    $scorecorrectedres =  <SCOREROUT>;
    $scorecorrected = get_score($scorecorrectedres);
#        print "O Original segment: score $scoreorig\nO $orig\n";
#        print "C Corrected segment: score $scorecorrected\nC $corrected\n";
#        if ($scorecorrected > $scoreorig) { print "--> BETTER\n"; $better++; }
#        if ($scorecorrected < $scoreorig) { print "--> WORSE\n"; $worse++; }
#        if ($scorecorrected == $scoreorig) { print "--> EQUAL\n"; }
    if ($scorecorrected > $scoreorig) { $compare = "better"; }
    if ($scorecorrected < $scoreorig) { $compare = "worse"; }
    if ($scorecorrected == $scoreorig) { $compare = "equal"; }
    print SCOREFILE "%s\t%s\t%s\n", $compare, $scoreorig, $scorecorrected;
}
close CORRECTEDFILE;
close ORIGFILE;
close SCOREFILE;
#    $summary .= sprintf("%s;%s;%d;%d;%d;%d\n", $flagtype, $rulename, $count, $better, $worse, $count-$better-$worse);
#}

close SCORERIN;
close SCOREROUT;

#print "\nSUMMARY (LM score of $subfolder)\n";
#print "-------\n\n";
#print "flag-type;rule-name;#segments;#better;#worse;#equal\n";
#print $summary;
#print "\n\n\n\n";
