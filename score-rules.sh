#!/bin/bash

if [ $# -lt 9 ] ; then
  echo "Usage: score-rules.sh text-file src-lmodel src-tcmodel src-toklang mosesserver:port ref-file tgt-lmodel tgt-tcmodel tgt-toklang [autoApplyOptions] " >&2
  echo " autoApplyOptions: e.g. -h host -p port -u user --pass pwd -l lang -r ruleset" >&2
  exit 1
fi

export inputfile=$1
shift
export srclm=$1
shift
export srctcmodel=$1
shift
export srctoklang=$1
shift
export mosesserver=$1
shift
export reffile=$1
shift
export tgtlm=$1
shift
export tgttcmodel=$1
shift
export tgttoklang=$1
shift

[ ! -e $inputfile ] && { echo "Input file does not exist" >&2 ; exit 2; }
#[ ! -e $srclm ] && { echo "Input language model file does not exist" >&2 ; exit 3; }
[ ! -e $reffile ] && { echo "Reference file does not exist" >&2 ; exit 2; }
#[ ! -e $tgtlm ] && { echo "Output language model file does not exist" >&2 ; exit 3; }

export thisdir=`dirname $0`

echo "*** Creating data to score..." >& 2

export aafolder=$inputfile.autoapply

if [ -d $aafolder ] ; then
    echo "Skipping auto-apply step, because $aafolder already exists" >& 2
else
    mkdir $aafolder

    echo "Auto-applying suggestions to $inputfile, writing to $aafolder..." >&2
    echo "Options: $*" >&2

    java -jar $thisdir/autoApplyClient/autoApplyClient-0.1.2-SNAPSHOT-jar-with-dependencies.jar -applySeparately -suppressResults -o $aafolder $* $inputfile
fi


#export srctokfolder=$inputfile.tokenized

#if [ -d $srctokfolder ] ; then
#    echo "Skipping tokenizing and truecasing of source language data, because $srctokfolder already exists" >& 2
#else
#    echo "Tokenizing and truecasing from $aafolder to $srctokfolder..." >&2
#    echo "Tokenizer language: $srctoklang, truecaser model: $srctcmodel" >&2

#    mkdir $srctokfolder
#    sh $thisdir/tokenize.sh $aafolder $srctokfolder "$srctcmodel" "$srctoklang"
#fi



export transfolder=$inputfile.translated

if [ -d $transfolder ] ; then
    echo "Skipping translation step, because $transfolder already exists" >& 2
else
    mkdir $transfolder
    if [[ $mosesserver == http* ]] ; then
	echo "Translating files in $aafolder to $transfolder using translation API at $mosesserver" >& 2	
	bash $thisdir/translate-api.sh $aafolder $srctoklang $transfolder $tgttoklang $mosesserver
    else
	echo "Translating files in $srctokfolder to $transfolder using Moses server at $mosesserver" >& 2
	perl $thisdir/translate.pl $srctokfolder $transfolder $mosesserver
    fi
fi


export reffolder=$reffile.ref

if [ -d $reffolder ] ; then
    echo "Skipping finding of reference translations, because $reffolder alread exists" >& 2
else
    mkdir $reffolder
    echo "Writing reference translations for original segments in $srctokfolderto $reffolder" >& 2
    echo "Using $inputfile and $reffile as parallel corpus" >& 2
    bash $thisdir/findreftrans.sh $inputfile $reffile $aafolder $reffolder
fi


#export reftokfolder=$reffile.tokenized

#if [ -d $reftokfolder ] ; then
#    echo "Skipping tokenizing and truecasing of reference file, because $reftokfolder already exists" >& 2
#else
#    echo "Tokenizing and truecasing from $reffolder to $reftokfolder..." >&2
#    echo "Tokenizer language: $tgttoklang, truecaser model: $tgttcmodel" >&2

#    mkdir $reftokfolder
#    sh $thisdir/tokenize.sh $reffolder $reftokfolder "$tgttcmodel" "$tgttoklang"
#fi


exit 1


export reportfile=$inputfile.report

echo "Writing results into $reportfile" >&2
rm -f $reportfile


echo "*** Scoring data" >& 2

echo "Auto-application & scoring of rules for MT pre-editing" > $reportfile
echo "======================================================" >> $reportfile
echo "" >> $reportfile
echo "Parameters:" >> $reportfile
echo "Input document: $inputfile" >> $reportfile
echo "Source language model file: $srclm" >> $reportfile
echo "Source language truecaser model: $srctcmodel" >> $reportfile
echo "Source language for tokenizer: $srctoklang" >> $reportfile
echo "Moses server: $mosesserver" >> $reportfile
echo "Reference document: $reffile" >> $reportfile
echo "Target language model file: $tgtlm" >> $reportfile
echo "Target language truecaser model: $tgttcmodel" >> $reportfile
echo "Target language for tokenizer: $tgttoklang" >> $reportfile
echo "Options for autoApplyClient: $*" >> $reportfile
echo "" >> $reportfile

echo "LM Scoring and comparing source language files in $srctokfolder" >& 2
echo "Language model: $srclm" >& 2
perl $thisdir/score-lm.pl $srctokfolder $srclm >> $reportfile

echo "LM Scoring and comparing translated files in $transfolder" >& 2
echo "Language model: $tgtlm" >& 2
perl $thisdir/score-lm.pl $transfolder $tgtlm >> $reportfile

echo "BLEU Scoring and comparing translated files in $transfolder" >& 2
echo "Tokenized reference translations: $reftokfolder" >& 2
perl $thisdir/score-ref.pl BLEU "java -jar $thisdir/bleu/bleu.jar --" $transfolder $reftokfolder >> $reportfile

echo "GTM Scoring and comparing translated files in $transfolder" >& 2
echo "Tokenized reference translations: $reftokfolder" >& 2
perl $thisdir/score-ref.pl GTM "sh $thisdir/gtm/gtm-wrapper.sh" $transfolder $reftokfolder >> $reportfile

echo "Done." >&2
