#!/usr/bin/perl

if ($#ARGV+1 < 2) {
    print "$0 <summary-file> <outfile>\n";
    exit -1;
}

$summary = shift;
$outfile = shift;
open INFILE, "$summary";
open OUTFILE, ">$outfile";

my %scores;

while ($str = <INFILE>) {
    my %record = {};
    do {
	if ($str =~ (/^([^\t])*\t(.*)$/, $_)) {
	    $record{$1} = $2;
	}
    } while ($str != "");

    $info = $record{"FLAG"};
    @parts = split(/\t/, $info);
    if ($parts[0] eq "GRAMMAR" || $parts[0] eq "SPELLING" || $parts[0] eq "STYLE" || $parts[0] eq "TERM") {
	$flagtype = $parts[0];
	$rulename = $parts[1];
	foreach $metric ('BLEU1', 'BLEU2', 'GTM1', 'GTM2', 'TER1', 'TER2', 'HUMAN') {
	    $scoreline = $record{$metric};
	    if ($scoreline ne "") {
		@parts = split(/\t/, $scoreline);		
		$scores{$flagtype}{$rulename}{$metric}{$parts[0]}++;
		$scores{$flagtype}{$rulename}{$metric}{"count"}++;		
	    }
	}
    }
}


print OUTFILE, "flagtype;rulename;metric;count;better;worse;equal\n";
foreach $flagtype (keys %scores) {
    foreach $rulename (keys %{$scores{$flagtype}}) {
	foreach $metric (keys %{$scores{$flagtype}{$rulename}}) {
	    %data = %{$scores{$flagtype}{$rulename}{$metric}};
	    if ($data{'better'} == "") { $data{'better'} = "0"; }
	    if ($data{'worse'} == "") { $data{'worse'} = "0"; }
	    if ($data{'equal'} == "") { $data{'equal'} = "0"; }
	    print OUTFILE, "$flagtype;$rulename;$metric;$data{'count'};$data{'better'};$data{'worse'};$data{'equal'}\n";
	}
    }
}

close INFILE;
close OUTFILE;
