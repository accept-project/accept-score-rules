#!/bin/bash
#
# The main rule scoring script.
#
# The script...
# - runs the AutoApply client on a given input text file, creating a set of original and corrected segments grouped by Acrolinx rule
# - tokenizes and truecases the original and corrected segments using a source language truecaser and tokenizer
# - scores the tokenized original and corrected segments using a language model for the source language
# - finds the reference translations of the original and corrected segments using a reference file that is parallel to the input file
# - translates the original and corrected segments using Moses (either via the Moses server XML-RPC interface, or via the Google Translate API)
# - tokenizes and truecases the translated original and corrected segments using a target language truecaser and tokenizer
# - scores the translated+tokenized original and corrected segments using a language model for the target language
# - tokenizes and truecases the reference translations using a target language truecaser and tokenizer
# - scores the translated+tokenized original and corrected segments against the tokenized reference segments
#   using smoothed BLEU, TER, and GTM
# - outputs the results for all phases (absolute scores as well as better/equal/worse statistics grouped by Acrolinx rule)

if [ $# -lt 11 ] ; then
  echo "Usage: score-rules.sh experiment-name text-file src-lmodel src-tcmodel src-toklang mosesserver:port ref-file-1 ref-file-2 tgt-lmodel tgt-tcmodel tgt-toklang [autoApplyOptions] " >&2
  echo " autoApplyOptions: e.g. -h host -p port -u user --pass pwd -l lang -r ruleset" >&2
  exit 1
fi

export MOSES_DIR=/home/build/mosesdecoder

export expname=$1
shift
export fname=$1
shift
export srclm=$1
shift
export srctcmodel=$1
shift
export srctoklang=$1
shift
export mosesserver=$1
shift
export reffile1=$1
shift
export reffile2=$1
shift
export tgtlm=$1
shift
export tgttcmodel=$1
shift
export tgttoklang=$1
shift

export thisdir=`dirname $0`
export bname=$thisdir/$expname
export rep=$bname.report
rm -f $rep
touch $rep

export summary=$bname.summary
export stats=$bname.stats.csv



function log {
    echo $1 |& tee -a $rep
}

log "Auto-application & scoring of rules for MT pre-editing"
log "======================================================"
log ""
log "Parameters:"
log "Input document: $fname"
log "Source language model file: $srclm"
log "Source language truecaser model: $srctcmodel"
log "Source language for tokenizer: $srctoklang"
log "Moses server: $mosesserver"
log "Reference document 1: $reffile1"
log "Reference document 2: $reffile2"
log "Target language model file: $tgtlm"
log "Target language truecaser model: $tgttcmodel"
log "Target language for tokenizer: $tgttoklang"
log "Options for autoApplyClient: $*"
log "Writing log into: $rep"
log "Writing combined summary into: $summary"
log "Writing statistics into: $stats"
log ""

[ ! -e $fname ] && { log "Input file does not exist" ; exit 2; }
[ ! -e $srclm ] && { log "Input language model file does not exist" ; exit 3; }
[ ! -e $reffile ] && { log "Reference file does not exist" ; exit 2; }
[ ! -e $tgtlm ] && { log "Output language model file does not exist" ; exit 3; }


log "*** Creating data to score..."

export src=$bname.src.autoapplyinfo
export srcO=$bname.src.original
export srcC=$bname.src.corrected

if [ -e $src ] ; then
	log "Skipping auto-apply step, because $src already exists"
else
    rm -f $src
    rm -f $srcO
    rm -f $srcC

    log "Auto-applying suggestions to $fname, writing to $expname.autoapplyinfo/original/corrected..."
    log "Options: $*"

    java -jar $thisdir/autoApplyClient/autoApplyClient-0.1.4-SNAPSHOT-jar-with-dependencies.jar -applySeparately -suppressResults -o `dirname $fname` $* $fname |& tee -a $rep
    mv $fname.autoapplyinfo $src
    mv $fname.original $srcO
    mv $fname.corrected $srcC
fi


export srctokO=$srcO.tok

if [ -e $srctokO ] ; then
    log "Skipping tokenizing and truecasing of original source language data, because $srctokO already exists"
else
    log "Tokenizing and truecasing from $srcO to $srctokO..."
    log "Tokenizer language: $srctoklang, truecaser model: $srctcmodel"

    sh $thisdir/tokenize.sh $srcO $srctokO "$srctcmodel" "$srctoklang" |& tee -a $rep
fi

export srctokC=$srcC.tok

if [ -e $srctokC ] ; then
    log "Skipping tokenizing and truecasing of corrected source language data, because $srctokC already exists" 
else
    log "Tokenizing and truecasing from $srcC to $srctokC..."
    log "Tokenizer language: $srctoklang, truecaser model: $srctcmodel"

    sh $thisdir/tokenize.sh $srcC $srctokC "$srctcmodel" "$srctoklang" |& tee -a $rep
fi

export tgtO=$bname.tgt.original

if [ -e $tgtO ] ; then
    log "Skipping translation of original sentences, because $tgtO already exists" 
else
    if [[ $mosesserver == http* ]] ; then
	log "Translating $srcO to $tgtO using translation API at $mosesserver" 	
	bash $thisdir/translate-api.sh $srcO $srctoklang $tgtO $tgttoklang $mosesserver |& tee -a $rep
    else
	log "Translating $srctokO to $tgtO using Moses server at $mosesserver" 
	perl $thisdir/translate.pl $srctokO $tgtO $mosesserver |& tee -a $rep
    fi
fi

export tgtC=$bname.tgt.corrected

if [ -e $tgtC ] ; then
    log "Skipping translation of corrected sentences, because $tgtC already exists" 
else
    if [[ $mosesserver == http* ]] ; then
	log "Translating $srcC to $tgtC using translation API at $mosesserver" 	
	bash $thisdir/translate-api.sh $srcC $srctoklang $tgtC $tgttoklang $mosesserver |& tee -a $rep
    else
	log "Translating $srctokC to $tgtC using Moses server at $mosesserver" 
	perl $thisdir/translate.pl $srctokC $tgtC $mosesserver |& tee -a $rep
    fi
fi


export tgttokO=$tgtO.tok

if [ -e $tgttokO ] ; then
    log "Skipping tokenizing and truecasing of original translation, because $tgttokO already exists" 
else
    log "Tokenizing and truecasing from $tgtO to $tgttokO..."
    log "Tokenizer language: $tgttoklang, truecaser model: $tgttcmodel"

    if [[ $mosesserver == http* ]] ; then
	sh $thisdir/tokenize.sh $tgtO $tgttokO "$tgttcmodel" "$tgttoklang" |& tee -a $rep
    else
	cp $tgtO $tgttokO
    fi
fi

export tgttokC=$tgtC.tok

if [ -e $tgttokC ] ; then
    log "Skipping tokenizing and truecasing of corrected translation, because $tgttokC already exists" 
else
    log "Tokenizing and truecasing from $tgtC to $tgttokC..."
    log "Tokenizer language: $tgttoklang, truecaser model: $tgttcmodel"

    if [[ $mosesserver == http* ]] ; then
	sh $thisdir/tokenize.sh $tgtC $tgttokC "$tgttcmodel" "$tgttoklang" |& tee -a $rep
    else
	cp $tgtC $tgttokC
    fi
fi


export ref1=$bname.refs1
if [ -e $ref1 ] ; then
    log "Skipping finding of reference translations, because $ref1 alread exists" 
else
    log "Writing reference translations for original segments in $srcO to $ref1" 
    log "Using $fname and $reffile1 as parallel corpus" 
    bash $thisdir/findreftrans.sh $fname $reffile1 $srcO $ref1 |& tee -a $rep
fi

if [ -n $reffile2 ] ; then
    export ref2=$bname.refs2

    if [ -e $ref2 ] ; then
	log "Skipping finding of reference translations, because $ref2 alread exists" 
    else
	log "Writing reference translations for original segments in $srcO to $ref2" 
	log "Using $fname and $reffile2 as parallel corpus" 
	bash $thisdir/findreftrans.sh $fname $reffile2 $srcO $ref2 |& tee -a $rep
    fi
fi


export reftok1=$ref1.tok
if [ -e $reftok1 ] ; then
    log "Skipping tokenizing and truecasing of reference file, because $reftok1 already exists" 
else
    log "Tokenizing and truecasing from $ref1 to $reftok1..."
    log "Tokenizer language: $tgttoklang, truecaser model: $tgttcmodel"

    sh $thisdir/tokenize.sh $ref1 $reftok1 "$tgttcmodel" "$tgttoklang" |& tee -a $rep
fi

if [ -n $reffile2 ] ; then
    export reftok2=$ref2.tok
    if [ -e $reftok2 ] ; then
	log "Skipping tokenizing and truecasing of reference file, because $reftok2 already exists" 
    else
	log "Tokenizing and truecasing from $ref2 to $reftok2..."
	log "Tokenizer language: $tgttoklang, truecaser model: $tgttcmodel"
	
	sh $thisdir/tokenize.sh $ref2 $reftok2 "$tgttcmodel" "$tgttoklang" |& tee -a $rep
    fi
fi


log "*** Scoring data" 

export lmsrcS=$bname.lm-$srctoklang
if [ -e $lmsrcS ] ; then
    log "Skipping LM scoring of source language files, since $lmsrcS already exists"
else
    log "LM Scoring and comparing source language file in $srctokO and $srctokC" 
    log "Language model: $srclm" 
    perl $thisdir/score-lm.pl $srctokO $srctokC $lmsrcS $srclm |& tee -a $rep
fi

export lmtgtS=$bname.lm-$srctoklang
if [ -e $lmtgtS ] ; then
    log "Skipping LM scoring of target language files, since $lmtgtS already exists"
else
    log "LM Scoring and comparing translated files in $tgttokO $tgttokC" 
    log "Language model: $tgtlm" 
    perl $thisdir/score-lm.pl $tgttokO $tgttokC $lmtgtS $tgtlm |& tee -a $rep
fi

function runscorer {
    if [ -e $3 ] ; then
	log "Skipping $1 scoring, since $3 already exists"
    else
	log "$1 scoring and comparison of translated files in $tgttokO and $tgttokC against $4"
	perl $thisdir/score-ref.pl $2 $tgttokO $tgttokC $3 $4 $5 |& tee -a $rep
    fi
}

export bleuS1=$bname.bleu1
export bleuS2=$bname.bleu2
export gtmS1=$bname.gtm1
export gtmS2=$bname.gtm2
export terS1=$bname.ter1
export terS2=$bname.ter2
runscorer BLEU "java -jar $thisdir/bleu/bleu.jar --" $bleuS1 $reftok1
runscorer GTM "sh $thisdir/gtm/gtm-wrapper.sh" $gtmS1 $reftok1
runscorer TER "sh $thisdir/ter/ter-wrapper.sh" $terS1 $reftok1 --invert
if [ -n $reffile2 ] ; then
    runscorer BLEU "java -jar $thisdir/bleu/bleu.jar --" $bleuS2 $reftok2
    runscorer GTM "sh $thisdir/gtm/gtm-wrapper.sh" $gtmS2 $reftok2
    runscorer TER "sh $thisdir/ter/ter-wrapper.sh" $terS2 $reftok2 --invert
fi


log "*** Combining data" 

export humanS=$bname.human
export scores=R1 $ref1 BLEU1 $bleuS1 GTM1 $gtmS1 TER1 $terS1
if [ -n $reffile 2 ] ; then
    export scores=$scores R2 $ref2 BLEU2 $bleuS2 GTM2 $gtmS2 TER2 $terS2
fi
if [ -e $humanS ] ; then
    export scores=$scores HUMAN $humanS
fi

perl adjoin.pl $summary FLAG $src SO $srcO SC $srcC TO $tgtO TC $tgtC $scores |& tee -a $rep


log "*** Creating statistics"

perl createstats.pl $summary $stats |& tee -a $rep

cat $stats | tee -a $rep

log "Done."
