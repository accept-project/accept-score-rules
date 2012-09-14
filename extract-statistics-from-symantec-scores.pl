my %scores;

while (<>) {
	@parts = split(/\t/, $_);
	if ($parts[0] eq "GRAMMAR" || $parts[0] eq "SPELLING" || $parts[0] eq "STYLE" || $parts[0] eq "TERM") {
		$flagtype = $parts[0] || "";
		$rulename = $parts[1] || "";
		$original_ref1_bleu_jar_score = $parts[6] || "";
		$original_ref1_ter_score      = $parts[7] || "";
		$original_ref1_ter_errors     = $parts[8] || "";
		$original_ref1_ter_ref_words  = $parts[9] || "";
		$original_ref1_gtm_precision  = $parts[10] || "";
		$original_ref1_gtm_recall     = $parts[11] || "";
		$original_ref1_gtm_fmeasure   = $parts[12] || "";
		$changed_ref1_bleu_jar_score  = $parts[13] || "";
		$changed_ref1_ter_score       = $parts[14] || "";
		$changed_ref1_ter_errors      = $parts[15] || "";
		$changed_ref1_ter_ref_words   = $parts[16] || "";
		$changed_ref1_gtm_precision   = $parts[17] || "";
		$changed_ref1_gtm_recall      = $parts[18] || "";
		$changed_ref1_gtm_fmeasure    = $parts[19] || "";
		$original_ref2_bleu_jar_score = $parts[20] || "";
		$original_ref2_ter_score      = $parts[21] || "";
		$original_ref2_ter_errors     = $parts[22] || "";
		$original_ref2_ter_ref_words  = $parts[23] || "";
		$original_ref2_gtm_precision  = $parts[24] || "";
		$original_ref2_gtm_recall     = $parts[25] || "";
		$original_ref2_gtm_fmeasure   = $parts[26] || "";
		$changed_ref2_bleu_jar_score  = $parts[27] || "";
		$changed_ref2_ter_score       = $parts[28] || "";
		$changed_ref2_ter_errors      = $parts[29] || "";
		$changed_ref2_ter_ref_words   = $parts[30] || "";
		$changed_ref2_gtm_precision   = $parts[31] || "";
		$changed_ref2_gtm_recall      = $parts[32] || "";
		$changed_ref2_gtm_fmeasure    = $parts[33] || "";
		
		if ($original_ref1_bleu_jar_score < $changed_ref1_bleu_jar_score) { $scores{"BLEU1"}{$flagtype}{$rulename}{"better"}++; }
		if ($original_ref1_bleu_jar_score == $changed_ref1_bleu_jar_score) { $scores{"BLEU1"}{$flagtype}{$rulename}{"equal"}++; }
		if ($original_ref1_bleu_jar_score > $changed_ref1_bleu_jar_score) { $scores{"BLEU1"}{$flagtype}{$rulename}{"worse"}++; }
		$scores{"BLEU1"}{$flagtype}{$rulename}{"count"}++;
		
		if ($original_ref2_bleu_jar_score < $changed_ref2_bleu_jar_score) { $scores{"BLEU2"}{$flagtype}{$rulename}{"better"}++; }
		if ($original_ref2_bleu_jar_score == $changed_ref2_bleu_jar_score) { $scores{"BLEU2"}{$flagtype}{$rulename}{"equal"}++; }
		if ($original_ref2_bleu_jar_score > $changed_ref2_bleu_jar_score) { $scores{"BLEU2"}{$flagtype}{$rulename}{"worse"}++; }
		$scores{"BLEU2"}{$flagtype}{$rulename}{"count"}++;

		if ($original_ref1_gtm_fmeasure < $changed_ref1_gtm_fmeasure) { $scores{"GTM1"}{$flagtype}{$rulename}{"better"}++; }
		if ($original_ref1_gtm_fmeasure == $changed_ref1_gtm_fmeasure) { $scores{"GTM1"}{$flagtype}{$rulename}{"equal"}++; }
		if ($original_ref1_gtm_fmeasure > $changed_ref1_gtm_fmeasure) { $scores{"GTM1"}{$flagtype}{$rulename}{"worse"}++; }
		$scores{"GTM1"}{$flagtype}{$rulename}{"count"}++;

		if ($original_ref2_gtm_fmeasure < $changed_ref2_gtm_fmeasure) { $scores{"GTM2"}{$flagtype}{$rulename}{"better"}++; }
		if ($original_ref2_gtm_fmeasure == $changed_ref2_gtm_fmeasure) { $scores{"GTM2"}{$flagtype}{$rulename}{"equal"}++; }
		if ($original_ref2_gtm_fmeasure > $changed_ref2_gtm_fmeasure) { $scores{"GTM2"}{$flagtype}{$rulename}{"worse"}++; }
		$scores{"GTM2"}{$flagtype}{$rulename}{"count"}++;

		if ($original_ref1_ter_score > $changed_ref1_ter_score) { $scores{"TER1"}{$flagtype}{$rulename}{"better"}++; }
		if ($original_ref1_ter_score == $changed_ref1_ter_score) { $scores{"TER1"}{$flagtype}{$rulename}{"equal"}++; }
		if ($original_ref1_ter_score < $changed_ref1_ter_score) { $scores{"TER1"}{$flagtype}{$rulename}{"worse"}++; }
		$scores{"TER1"}{$flagtype}{$rulename}{"count"}++;

		if ($original_ref2_ter_score > $changed_ref2_ter_score) { $scores{"TER2"}{$flagtype}{$rulename}{"better"}++; }
		if ($original_ref2_ter_score == $changed_ref2_ter_score) { $scores{"TER2"}{$flagtype}{$rulename}{"equal"}++; }
		if ($original_ref2_ter_score < $changed_ref2_ter_score) { $scores{"TER2"}{$flagtype}{$rulename}{"worse"}++; }
		$scores{"TER2"}{$flagtype}{$rulename}{"count"}++;
	}
	elsif ($parts[0] eq "TC") {
		if ($parts[2] eq "1") { $scores{"HUMAN"}{$flagtype}{$rulename}{"better"}++; } 
		if ($parts[3] eq "1") { $scores{"HUMAN"}{$flagtype}{$rulename}{"worse"}++; } 
		if ($parts[4] eq "1") { $scores{"HUMAN"}{$flagtype}{$rulename}{"equal"}++; } 
		if ($parts[2] eq "1" || $parts[3] eq "1" || $parts[4] eq "1") { $scores{"HUMAN"}{$flagtype}{$rulename}{"count"}++; }
	}
}

foreach $metric (keys %scores) {
    print "SUMMARY OF $metric SCORES\n";
    print "========================================\n";
    foreach $flagtype (keys %{$scores{$metric}}) {
	foreach $rulename (keys %{$scores{$metric}{$flagtype}}) {
	    %data = %{$scores{$metric}{$flagtype}{$rulename}};
	    if ($data{'better'} == "") { $data{'better'} = "0"; }
	    if ($data{'worse'} == "") { $data{'worse'} = "0"; }
	    if ($data{'equal'} == "") { $data{'equal'} = "0"; }
	    print "$flagtype;$rulename;$data{'count'};$data{'better'};$data{'worse'};$data{'equal'}\n";
	}
    }
    print "\n";
}

