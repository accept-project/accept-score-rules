#!/usr/bin/perl
#
# Merge segments of different folders into one file:
# - source language folder (containing original and corrected segments)
# - MT-translated target language folder (containing original and corrected segments)
# - folder containing reference translation segments from reference set 1
# - folder containing reference translation segments from reference set 2
#

use warnings;
use FileHandle;

if ($#ARGV <= 2) {
    print "$0 <srcfolder> <tgtfolder> <ref1folder> <ref2folder>\n";
    exit -1;
}

$srcfolder = $ARGV[0];
$tgtfolder = $ARGV[1];
$ref1folder = $ARGV[2];
$ref2folder = $ARGV[3];

@files = <$srcfolder/*>;
foreach $file (@files) {
    next if ($file =~ /\.orig$/);
    next unless ($file =~ /^$srcfolder\/(.*)$/);
    $basename = $1;
    @parts = split(/\./, $basename);
    $flagtype = $parts[0] || "";
    $rulename = $parts[1] || "";
    open ORIGFILE, "$file.orig";
    open CORRECTEDFILE, "$file";
    open TGTORIGFILE, "$tgtfolder/$basename.orig";
    open TGTCORRECTEDFILE, "$tgtfolder/$basename";
    open REF1FILE, "$ref1folder/$basename.ref";
    open REF2FILE, "$ref2folder/$basename.ref";
    while ($orig = <ORIGFILE>) {
		$corrected = <CORRECTEDFILE>;
		$tgtorig = <TGTORIGFILE>;
		$tgtcorrected = <TGTCORRECTEDFILE>;
		$ref1 = <REF1FILE>;
		$ref2 = <REF2FILE>;
		chomp $orig;
		chomp $corrected;
		chomp $tgtorig;
		chomp $tgtcorrected;
		chomp $ref1;
		chomp $ref2;
		print "$flagtype\t$rulename\n";
		print "SO\t$orig\n";
		print "SC\t$corrected\n";
		print "TO\t$tgtorig\n";
		print "TC\t$tgtcorrected\n";
		print "R1\t$ref1\n";
		print "R2\t$ref2\n";
		print "\n";
    }
    close ORIGFILE;
    close CORRECTEDFILE;
    close TGTORIGFILE;
    close TGTCORRECTEDFILE;
    close REF1FILE;
    close REF2FILE;
}

    
