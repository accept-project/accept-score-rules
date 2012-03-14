#!/bin/bash

if [ $# -lt 4 ] ; then
  echo "Usage: score-rules.sh text-file language-model-file truecase-model tok-lang [autoApplyOptions] " >&2
  echo " autoApplyOptions: e.g. -h host -p port -u user --pass pwd -l lang -r ruleset" >&2
  exit 1
fi

export inputfile=$1
shift
export lm=$1
shift
export truecasemodel=$1
shift
export toklang=$1
shift

[ ! -e $inputfile ] && { echo "Input file does not exist" >&2 ; exit 2; }
[ ! -e $lm ] && { echo "Language model file does not exist" >&2 ; exit 3; }

[ ! -e $truecasemodel ] && { echo "True case model file not found; skipping truecasing" >&2 ; export truecasemodel=""; }

[ -z $toklang ] && { echo "Assuming English as tokenization language" >&2 ; export toklang="en"; }



export aafolder=$inputfile.autoapply

if [ -d $aafolder ] ; then
    echo "Skipping auto-apply step, because $aafolder already exists" >& 2
else
    rm -rf $aafolder
    mkdir $aafolder

    echo "Auto-applying suggestions to $inputfile, writing to $aafolder..." >&2
    echo "Options: $*" >&2

    java -jar autoApplyClient/autoApplyClient-0.1.1-SNAPSHOT.jar -applySeparately -suppressResults -o $aafolder $* $inputfile
fi




export tokfolder=$inputfile.tokenized

if [ -d $tokfolder ] ; then
    echo "Skipping tokenizing, truecasing & segmentation, because $tokfolder already exists" >& 2
else
    mkdir $tokfolder

    echo "Tokenizing, truecasing & segmenting files in $aafolder to $tokfolder..." >&2
    echo "Tokenizer language: $toklang, truecaser model: $truecasemodel" >&2

    export tokcmd="/home/build/mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $toklang"
    if [ ! -z $truecasemodel ] ; then
	export tccmd="/home/build/mosesdecoder/scripts/recaser/truecase.perl --model $truecasemodel"
    else
	export tccmd="cat"
    fi

    for file in $aafolder/*
    do
	cat $file | $tokcmd | $tccmd > $tokfolder/`basename $file`
    done
fi

export reportfile=$inputfile.report

echo "Writing results into $reportfile" >&2
rm -f $reportfile

echo "Auto-application & scoring of rules for MT pre-editing" > $reportfile
echo "======================================================" >> $reportfile
echo "" >> $reportfile
echo "Parameters:" >> $reportfile
echo "Input document: $inputfile" >> $reportfile
echo "Language model file: $lm" >> $reportfile
echo "Tokenization language: $toklang" >> $reportfile
echo "Truecaser model: $truecasemodel" >> $reportfile
echo "Options for autoApplyClient: $*\n\n" >> $reportfile

perl score-and-eval.pl $tokfolder $lm >> $reportfile

echo "Done." >&2

