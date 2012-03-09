#!/usr/bin/perl
use warnings;
use FileHandle;
use IPC::Open3;

if ($#ARGV < 2) {
    print "$0 <subfolder> <input file> <language model file>\n";
    exit -1;
}

$subfolder = $ARGV[0];
$inputfile = $ARGV[1];
$lm = $ARGV[2];



@files = <$subfolder/$inputfile*>;

$scorer = "/home/build/mosesdecoder/irstlm/bin/score-lm -lm $lm";
IPC::Open3::open3 (SCORERIN, SCOREROUT, SCORERERR, "$scorer");

print "SCORING of original and corrected segments\n";
print "------------------------------------------\n\n";

$summary = "";

foreach $file (@files) {
    next if ($file =~ /\.orig$/);
    next unless ($file =~ /^$subfolder\/$inputfile\.(.*)$/);
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
	$orig = <ORIGFILE>;
        $count++;
        print SCORERIN "$orig";
        $scoreorig = <SCOREROUT>;
        chomp $scoreorig;
        print SCORERIN "$corrected";
        $scorecorrected =  <SCOREROUT>;
        chomp $scorecorrected;
        if ($scorecorrected > $scoreorig) { $better++ };
        if ($scorecorrected < $scoreorig) { $worse++ };     
        print "O Original segment: score $scoreorig\nO $orig\n";
        print "C Corrected segment: score $scorecorrected\nC $corrected\n\n";
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

