#!/bin/bash

if [ $# -lt 4 ] ; then
  echo "Usage: tokenize.sh infolder outfolder truecase-model tok-lang" >& 2
  exit 1
fi

export infolder=$1
shift
export outfolder=$1
shift
export truecasemodel=$1
shift
export toklang=$1
shift

[ ! -d $infolder ] && { echo "Input file does not exist" >&2 ; exit 2; }
[ ! -d $outfolder ] && { echo "$outfolder does not exist, creating it" >& 2 ; mkdir -p $outfolder; }
[ ! -e $truecasemodel ] && { echo "True case model file not found; skipping truecasing" >&2 ; export truecasemodel=""; }

export tokcmd="/home/build/mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $toklang"
if [ ! -z $truecasemodel ] ; then
    export tccmd="/home/build/mosesdecoder/scripts/recaser/truecase.perl --model $truecasemodel"
else
    export tccmd="cat"
fi

for file in $infolder/*
do
    cat $file | $tokcmd | $tccmd > $outfolder/`basename $file`
done
