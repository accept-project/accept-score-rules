#!/usr/bin/perl

# From a given summary file (created by adjoin.pl) containing for each flag
# flag info, orignal/corrected/reference segments, and scores of the various
# metrics, create a statistics file in tab-separated CSV format that
# indicates for each flag type, for each rule name, and for each metric
# in how many instances a suggestion of that rule has been applied, how
# often the translation improved according to the metric, how often it
# degraded, and how often it stayed the same.


if (scalar(@ARGV) < 2) {
    print "$0 <summary-file> <outfile>\n";
    exit -1;
}

$summary = shift;
$outfile = shift;
open INFILE, "$summary";
open OUTFILE, ">$outfile";

my %scores;
my @input_metrics = ('LM-EN', 'LM-DE', 'LM-FR', 'BLEU1', 'BLEU2', 'GTM1', 'GTM2', 'TER1', 'TER2', 'HUMAN');
my @output_metrics = ('LM-EN', 'LM-DE', 'LM-FR', 'AVG', 'HUMAN');
my @avg_metrics = ('BLEU1', 'BLEU2', 'GTM1', 'GTM2', 'TER1', 'TER2');
my $count_threshold = 13;

while ($str = <INFILE>) {
    my %record;
    do {
	chomp($str);
	if ($str =~ (/^([^\t]*)\t(.*)$/)) {
	    $record{$1} = $2;
	}
	$str = <INFILE>;
	chomp($str);
    } while ($str ne "");

    $info = $record{"FLAG"};
    @parts = split(/\t/, $info);
    if ($parts[0] eq "GRAMMAR" || $parts[0] eq "SPELLING" || $parts[0] eq "STYLE" || $parts[0] eq "TERM") {
	$flagtype = $parts[0];
	$rulename = $parts[1];
	foreach $metric (@input_metrics) {
	    $scoreline = $record{$metric};
	    if ($scoreline ne "") {
		@parts = split(/\t/, $scoreline);		
		$scores{$flagtype}{$rulename}{$metric}{$parts[0]}++;
		$scores{$flagtype}{$rulename}{$metric}{"count"}++;
		
	    }
	}
    }
}

foreach $flagtype (sort keys %scores) {
    foreach $rulename (sort keys %{$scores{$flagtype}}) {
	foreach $column ("better", "worse", "equal", "count") {
	    $metrics_count = 0;
	    foreach $metric (@avg_metrics) {
		if (exists $scores{$flagtype}{$rulename}{$metric}) {
		    $metrics_count++;
		    $scores{$flagtype}{$rulename}{"AVG"}{$column} +=
			$scores{$flagtype}{$rulename}{$metric}{$column};
		}
	    }
	    if ($metrics_count > 0) {
		$scores{$flagtype}{$rulename}{"AVG"}{$column} /= $metrics_count;
	    }
	}
    }
}

print OUTFILE "flagtype\trule name\tflagtype for chart\trulename for chart\tmetric\tcount\tbetter\tworse\tequal\n";
foreach $flagtype (sort keys %scores) {
    $flagtypeforchart = $flagtype;
    foreach $rulename (sort keys %{$scores{$flagtype}}) {
	$rulenameforchart = $rulename;
	$rulenameforchart =~ s/_/ /g;
	foreach $metric (@output_metrics) {
	    if (exists $scores{$flagtype}{$rulename}{$metric}) {
		%data = %{$scores{$flagtype}{$rulename}{$metric}};
		if ($data{'count'} >= $count_threshold) {
		    if ($rulenameforchart ne "") {
			$rulenameforchart .= " ($data{'count'})";
		    }
		    if ($data{'better'} eq "") { $data{'better'} = "0"; }
		    if ($data{'worse'} eq "") { $data{'worse'} = "0"; }
		    if ($data{'equal'} eq "") { $data{'equal'} = "0"; }
		    print OUTFILE "$flagtype\t$rulename\t$flagtypeforchart\t$rulenameforchart\t$metric\t$data{'count'}\t$data{'better'}\t$data{'worse'}\t$data{'equal'}\n";
		    $flagtypeforchart = "";
		    $rulenameforchart = "";
		}
	    }
	}
    }
}

close INFILE;
close OUTFILE;
