#!/usr/bin/perl
use warnings;
use FileHandle;
use IPC::Open3;

if ($#ARGV <= 0) {
    print "$0 <subfolder> <language model file>\n";
    exit -1;
}

$subfolder = $ARGV[0];
$lm = $ARGV[1];



@files = <$subfolder/*>;

$scorer = "/home/build/mosesdecoder/irstlm/bin/score-lm -lm $lm";
IPC::Open3::open3 (SCORERIN, SCOREROUT, SCORERERR, "$scorer");

print "SCORING of original and corrected segments\n";
print "------------------------------------------\n\n";

$summary = "";

foreach $file (@files) {
    next if ($file =~ /\.orig$/);
    next unless ($file =~ /^$subfolder\/(.*)$/);
    @parts = split(/\./, $1);
    $flagtype = $parts[0] || "";
    $rulename = $parts[1] || "";
    print "Flag type $flagtype, rule $rulename\n";
    print "--------------------------------------------------\n\n";
    $count = 0;
    $better = 0;
    $worse = 0;
    open CORRECTEDFILE, "$file";
    open ORIGFILE, "$file.orig";
    while ($corrected = <CORRECTEDFILE>) {
        chomp $corrected;
	$orig = <ORIGFILE>;
        chomp($orig);
        $count++;
        print SCORERIN "<s> $orig </s>\n";
        $scoreorig = <SCOREROUT>;
        chomp $scoreorig;
        print SCORERIN "<s> $corrected </s>\n";
        $scorecorrected =  <SCOREROUT>;
        chomp $scorecorrected;
        print "O Original segment: score $scoreorig\nO $orig\n";
        print "C Corrected segment: score $scorecorrected\nC $corrected\n";
        if ($scorecorrected > $scoreorig) { print "--> BETTER\n"; $better++; }
        if ($scorecorrected < $scoreorig) { print "--> WORSE\n"; $worse++; }
        if ($scorecorrected == $scoreorig) { print "--> EQUAL\n"; }
        print "\n";   
    }
    close CORRECTEDFILE;
    close ORIGFILE;
    $summary .= sprintf("%s,%s,%d,%d,%d,%d\n", $flagtype, $rulename, $count, $better, $worse, $count-$better-$worse);
}

close SCORERIN;
close SCOREROUT;


print "\nSUMMARY\n";
print "-------\n\n";
print "flag-type,rule-name,#segments,#better,#worse,#equal\n";
print $summary;
