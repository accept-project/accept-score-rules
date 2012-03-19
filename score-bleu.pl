#!/usr/bin/perl
use warnings;
use FileHandle;
use IPC::Open3;

if ($#ARGV <= 0) {
    print "$0 <cand-folder> <ref-folder>\n";
    exit -1;
}

$candfolder = $ARGV[0];
$reffolder = $ARGV[1];

$scorer = "java -cp bleu/src lingutil.bleu.Main --";
IPC::Open3::open3 (SCORERIN, SCOREROUT, SCORERERR, "$scorer");

print "BLEU SCORING of original and corrected segments in $candfolder\n";
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
        chomp $corrected;
	$orig = <ORIGFILE>;
        chomp($orig);
        $ref = <REFFILE>;
        chomp($ref);
        $count++;
        print SCORERIN "$ref\n";
        print SCORERIN "$orig\n";
        $scoreorig = <SCOREROUT>;
        chomp $scoreorig;
        print SCORERIN "$ref\n";
        print SCORERIN "$corrected\n";
        $scorecorrected =  <SCOREROUT>;
        chomp $scorecorrected;
        print "R Reference segment:\n R $ref\n";
        print "O Original segment: score $scoreorig\nO $orig\n";
        print "C Corrected segment: score $scorecorrected\nC $corrected\n";
        if ($scorecorrected > $scoreorig) { print "--> BETTER\n"; $better++; }
        if ($scorecorrected < $scoreorig) { print "--> WORSE\n"; $worse++; }
        if ($scorecorrected == $scoreorig) { print "--> EQUAL\n"; }
        print "\n";   
    }
    close CORRECTEDFILE;
    close ORIGFILE;
    $summary .= sprintf("%s;%s;%d;%d;%d;%d\n", $flagtype, $rulename, $count, $better, $worse, $count-$better-$worse);
}


close SCORERIN;
close SCOREROUT;


print "\nSUMMARY (BLEU score of $candfolder)\n";
print "-------\n\n";
print "flag-type;rule-name;#segments;#better;#worse;#equal\n";
print $summary;
print "\n\n\n\n";

