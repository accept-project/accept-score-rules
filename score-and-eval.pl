#!/usr/bin/perl
use warnings;
use FileHandle;
use IPC::Open3;

if ($#ARGV < 1) {
    print "$0 <subfolder> <input file> <language model file>\n";
    exit -1;
}

$subfolder = $ARGV[0];
$inputfile = $ARGV[1];
$lm = $ARGV[2];



@files = <$subfolder/$inputfile*>;

$scorer = "/home/build/mosesdecoder/irstlm/bin/score-lm -lm $lm";
IPC::Open3::open3 (SCORERIN, SCOREROUT, SCORERERR, "$scorer");

print "flag-type,rule-name,#segments,#better,#worse,#equal\n";

foreach $file (@files) {
    next if ($file =~ /\.orig$/);
    next unless ($file =~ /^$subfolder\/$inputfile\.(.*)$/);
    @parts = split(/\./, $1);
    $flagtype = $parts[0] || "";
    $rulename = $parts[1] || "";
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
        print SCORERIN "$corrected";
        $scorecorrected =  <SCOREROUT>;
        if ($scorecorrected > $scoreorig) { $better++ };
        if ($scorecorrected < $scoreorig) { $worse++ };     
    }
    close CORRECTEDFILE;
    close ORIGFILE;
    print "$flagtype,$rulename,$count,$better,$worse,", $count-$better-$worse, "\n";
}

close SCORERIN;
close SCOREROUT;

