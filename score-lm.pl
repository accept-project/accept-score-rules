#!/usr/bin/perl
#
# Score segments of parallel documents containing original and corrected 
# segments using KenLM and a given language model.
# The output file contains the scores, as well as the BETTER/WORSE/EQUAL 
# ranking for each segment. The output file is thus line-aligned to 
# the original and corrected file.

use warnings;
use FileHandle;
use IPC::Open3;

if (scalar(@ARGV) < 4) {
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

$MOSES_DIR=$ENV{MOSES_DIR};

$scorer = "$MOSES_DIR/lm/query $lm";
IPC::Open3::open3 (SCORERIN, SCOREROUT, SCORERERR, "$scorer");

open ORIGFILE, "$fnameO";
open CORRECTEDFILE, "$fnameC";
open SCOREFILE, ">$fnameS";
while ($corrected = <CORRECTEDFILE>) {
    $corrected = trim($corrected);        
    if (!($orig = <ORIGFILE>)) { die "$fnameO is shorter than $fnameC!"; };
    $orig = trim($orig);
    print SCORERIN "<s> $orig </s>\n";
    $scoreorigres = <SCOREROUT>;
    $scoreorig = get_score($scoreorigres);
    print SCORERIN "<s> $corrected </s>\n";
    $scorecorrectedres =  <SCOREROUT>;
    $scorecorrected = get_score($scorecorrectedres);
    if ($scorecorrected > $scoreorig) { $compare = "better"; }
    if ($scorecorrected < $scoreorig) { $compare = "worse"; }
    if ($scorecorrected == $scoreorig) { $compare = "equal"; }
    print SCOREFILE sprintf("%s\t%s\t%s\n", $compare, $scoreorig, $scorecorrected);
}
close CORRECTEDFILE;
close ORIGFILE;
close SCOREFILE;

close SCORERIN;
close SCOREROUT;
