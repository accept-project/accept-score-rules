
## Rule scoring framework

This repository contains the set of scripts that has been used for the AMTA paper
(Johann Roturier, Linda Mitchell, Robert Grabowski and Melanie Siegel: Using Automatic Machine Translation Metrics to Analyze the Impact of Source Reformulations, AMTA 2012)

# score-rules.sh 

This is the main rule scoring script.

The script...
- runs the AutoApply client on a given input text file, creating a set
  of original and corrected segments in two parallel files,
  in addition to information about the flag in a third file
- tokenizes and truecases the original and corrected segments 
  using a source language truecaser and tokenizer
- finds the reference translations of the original and corrected
  segments using a reference file that is parallel to the input file
- translates the original and corrected segments using Moses 
  (either via the Moses server XML-RPC interface, or via the 
   Google Translate API)
- tokenizes and truecases the translated original and corrected segments 
  using a target language truecaser and tokenizer
- tokenizes and truecases the reference translations using a target 
  language truecaser and tokenizer

- scores the tokenized original and corrected segments using a
  language model for the source language
- scores the translated+tokenized original and corrected segments 
  using a language model for the target language
- scores the translated+tokenized original and corrected segments 
  against the tokenized reference segments using smoothed BLEU, TER, and GTM
- collects all scores and compares them, resulting a statistics CSV file
  with better/equal/worse rankings grouped by Acrolinx rule

Progress messages are output and written to a log file.
The script usually does not create a data file if it already exists.

# Usage

The script needs the tokenizer and truecaser scripts from the
mosesdecoder repository. The root path to the mosesdecoder repository
is hard-coded in the script file as the variable MOSES_DIR at the
beginning. Please change that first.

General invocation: 

score-rules.sh experiment-name text-file src-lmodel src-tcmodel src-toklang mosesServer ref-file-1 ref-file-2 tgt-lmodel tgt-tcmodel tgt-toklang [autoApplyOptions] 

mosesServer: 
  either e.g. localhost:8081 (to translate via mosesserver XML-RPC),
  or e.g. http://server/translate.php (to translate via Translate API)
autoApplyOptions: 
  e.g. -h host -p port -u user --pass pwd -l lang -r ruleset
  (run autoApplyClient for complete list)
src-tcmodel/tgt-tcmodel:
  can be "" to skip true-casing


Example invocation:

bash score-rules.sh amta_experiment symc_bip_15_source.clean 1002-10.binlm truecase-model.1.en en 'http://user:pass@accept.statmt.org/demo/translate.php' symc_bip_17_target1.de.clean symc_bip_19_target2.de.clean 1002-06.binlm truecase-model.1.de de -h accept.acrolinx.com -p 80 -u USER --pass PASS -l en -r Preediting_SMT_SYMC -t Symantec -ts DEPRECATED,ADMITTED,VALID -skipReuseCheck

Output:

amta_experiment.summary:
	The complete result, one record per correction instance: autoApply output, Moses translations, and all scores
amta_experiment.statistics.csv:
	The summary aggregated/grouped by rule.
  

# Notes

The script still contains a lot of code duplication that should be
factored out to make it more flexible.
