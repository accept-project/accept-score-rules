#!/usr/bin/perl
use warnings;
use FileHandle;
use IPC::Open3;

if (scalar(@ARGV) < 6) {
    print "$0 <aafile> <origfile> <correctedfile> <aafile-lat> <origfile-lat> <correctedfile-lat>\n";
    exit -1;
}

$fnameA = $ARGV[0];
$fnameO = $ARGV[1];
$fnameC = $ARGV[2];
$fnameLA = $ARGV[3];
$fnameLO = $ARGV[4];
$fnameLC = $ARGV[5];



open AAFILE, "$fnameA";
open ORIGFILE, "$fnameO";
open CORRECTEDFILE, "$fnameC";
open AALATFILE, ">$fnameLA";
open ORIGLATFILE, ">$fnameLO";
open CORRECTEDLATFILE, ">$fnameLC";

my @corrections = ();

while ($infoline = <AAFILE>) {
    chomp($infoline);
    @parts = split(/\t/, $infoline);
    $suggnum = $parts[2];
    $suggcnt = $parts[3];
    
    $orig = <ORIGFILE>;
    chomp($orig);
    $corrected = <CORRECTEDFILE>;
    chomp($corrected);

    if ("$suggnum" eq "0") { 
	next; 
    }

    if ($parts[6] eq "0") {
	$option = "";
    } else {
	$option = substr $corrected, $parts[4], $parts[6];
    }

    push(@corrections, $option);

    if ($suggnum eq $suggcnt) {
	print AALATFILE "$parts[0]\t$parts[1]\t1\t1\t$parts[4]\t$parts[5]\n";
	print ORIGLATFILE "$orig\n";
	$start = "";
	$origpart = "";
	$end = "";
	$start = substr $orig, 0, $parts[4];
	$origpart = substr $orig, $parts[4], $parts[5]-$parts[4] if ($parts[4] < length($orig));
	$end = substr $orig, $parts[5] if ($parts[5] < length($orig));

	unshift (@corrections, $origpart);
	$str = "$start<options>";
	foreach $correction (@corrections) {
	    $str .= "<option>$correction</option>";
	}
	$str .= "</options>$end";
	print CORRECTEDLATFILE "$str\n";
	@corrections = ();
    }
}

close AAFILE;
close ORIGFILE;
close CORRECTEDFILE;
close AALATFILE;
close ORIGLATFILE;
close CORRECTEDLATFILE;

