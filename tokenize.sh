#!/bin/bash
#
# Tokenize and truecase a file using the respective Moses scripts.
# Specify the truecase model and tokenization language like 'en'.

if [ $# -lt 4 ] ; then
  echo "Usage: tokenize.sh infile outfile truecase-model tok-lang" >& 2
  exit 1
fi

export infile=$1
shift
export outfile=$1
shift
export truecasemodel=$1
shift
export toklang=$1
shift

[ ! -e $infile ] && { echo "Input file does not exist" >&2 ; exit 2; }
[ ! -e $truecasemodel ] && { echo "True case model file not found; skipping truecasing" >&2 ; export truecasemodel=""; }

export tokcmd="$MOSES_DIR/scripts/tokenizer/tokenizer.perl -a -q -l $toklang"
if [ ! -z $truecasemodel ] ; then
    export tccmd="$MOSES_DIR/scripts/recaser/truecase.perl --model $truecasemodel"
else
    export tccmd="cat"
fi

cat $infile | $tokcmd | $tccmd > $outfile
