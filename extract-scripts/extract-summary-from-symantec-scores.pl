my %scores;
my $line = "";
my $app = "";

my $HUMAN_SCORES_INCLUDED = 1;
my $offset = ($HUMAN_SCORES_INCLUDED) ? 4 : 0;

sub scoreline {	
	($metricname, $origscore, $correctedscore, $invert) = @_;
	$factor = ($invert) ? -1.0 : 1.0;
	if ($origscore ne "" && $correctedscore ne "") {
		if ($correctedscore*$factor > $origscore*$factor) { return "$metricname\tbetter\t$origscore\t$correctedscore\n" };
		if ($correctedscore*$factor < $origscore*$factor) { return "$metricname\tworse\t$origscore\t$correctedscore\n" };
		if ($origscore == $correctedscore) { return "$metricname\tequal\t$origscore\t$correctedscore\n" };		
	}
	return "";
}

while ($line = <>) {
	chomp($line);
	@parts = split(/\t/, $line);
	if ($parts[0] eq "GRAMMAR" || $parts[0] eq "SPELLING" || $parts[0] eq "STYLE" || $parts[0] eq "TERM") {
		$HUMAN_SCORES_INCLUDED = (scalar(@parts) > 30) ? 1 : 0;
		$offset = ($HUMAN_SCORES_INCLUDED) ? 4 : 0;
		
		$flagtype = $parts[0];
		$rulename = $parts[1];
		$original_ref1_bleu_jar_score = $parts[2 + $offset];
		$original_ref1_ter_score      = $parts[3 + $offset];
		$original_ref1_ter_errors     = $parts[4 + $offset];
		$original_ref1_ter_ref_words  = $parts[5 + $offset];
		$original_ref1_gtm_precision  = $parts[6 + $offset];
		$original_ref1_gtm_recall     = $parts[7 + $offset];
		$original_ref1_gtm_fmeasure   = $parts[8 + $offset];
		$changed_ref1_bleu_jar_score  = $parts[9 + $offset];
		$changed_ref1_ter_score       = $parts[10 + $offset];
		$changed_ref1_ter_errors      = $parts[11 + $offset];
		$changed_ref1_ter_ref_words   = $parts[12 + $offset];
		$changed_ref1_gtm_precision   = $parts[13 + $offset];
		$changed_ref1_gtm_recall      = $parts[14 + $offset];
		$changed_ref1_gtm_fmeasure    = $parts[15 + $offset];
		$original_ref2_bleu_jar_score = $parts[16 + $offset];
		$original_ref2_ter_score      = $parts[17 + $offset];
		$original_ref2_ter_errors     = $parts[18 + $offset];
		$original_ref2_ter_ref_words  = $parts[19 + $offset];
		$original_ref2_gtm_precision  = $parts[20 + $offset];
		$original_ref2_gtm_recall     = $parts[21 + $offset];
		$original_ref2_gtm_fmeasure   = $parts[22 + $offset];
		$changed_ref2_bleu_jar_score  = $parts[23 + $offset];
		$changed_ref2_ter_score       = $parts[24 + $offset];
		$changed_ref2_ter_errors      = $parts[25 + $offset];
		$changed_ref2_ter_ref_words   = $parts[26 + $offset];
		$changed_ref2_gtm_precision   = $parts[27 + $offset];
		$changed_ref2_gtm_recall      = $parts[28 + $offset];
		$changed_ref2_gtm_fmeasure    = $parts[29 + $offset];

		$app .= scoreline("BLEU1", $original_ref1_bleu_jar_score, $changed_ref1_bleu_jar_score, 0);
		$app .= scoreline("BLEU2", $original_ref2_bleu_jar_score, $changed_ref2_bleu_jar_score, 0);
		
		$app .= scoreline("GTM1", $original_ref1_gtm_fmeasure, $changed_ref1_gtm_fmeasure, 0);
		$app .= scoreline("GTM2", $original_ref2_gtm_fmeasure, $changed_ref2_gtm_fmeasure, 0);
		
		$app .= scoreline("TER1", $original_ref1_ter_score, $changed_ref1_ter_score, 1);
		$app .= scoreline("TER2", $original_ref2_ter_score, $changed_ref2_ter_score, 1);		
		
		print "FLAG\t$parts[0]\t$parts[1]\t\t\t\t\t\n";
	}
	elsif ($parts[0] ne "") {
		if ($parts[0] eq "TC") {			
			$original_human_score = ""; $changed_human_score = "";
			if ($parts[2] eq "1") { $original_human_score = 0; $changed_human_score = 1; } 
			if ($parts[3] eq "1") { $original_human_score = 1; $changed_human_score = 0; } 
			if ($parts[4] eq "1") { $original_human_score = 1; $changed_human_score = 1; }
			$app .= scoreline("HUMAN", $original_human_score, $changed_human_score, 0);
		}
		print "$parts[0]\t$parts[1]\n";
	}
	else {
		print $app;
		print "\n";
		$app = "";
	}
}
