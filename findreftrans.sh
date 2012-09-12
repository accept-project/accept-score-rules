#!/usr/bin/env bash
#
# Find all reference translations of segments in a file.
# The results are written into a parallel target file.
# For each segment, its reference translations is found by finding 
# it in the source segments file, and by searching for the reference
# translation in the corresponding parallel target segments file.


if [ $# -lt 4 ] ; then
  echo "Usage: findreftrans.sh corpus.src corpus.tgt segments.src segments.tgt"
  exit 1
fi


export SRCCORPUS=$1
export TGTCORPUS=$2
export SRCFILE=$3
export TGTFILE=$4

export TMPFILE=$SRCFILE.tmp

touch $TGTFILE
while read -r STR ; do
    echo "$STR" > $TMPFILE
    export LINE=`fgrep --line-number -f $TMPFILE $SRCCORPUS | head -1 | cut -d ':' -f 1`
    if [ -z "$LINE" ] ; then
	echo "Warning: no line found in $TGTCORPUS corresponding to the following sentence in $SRCCORPUS, outputting empty line:" >& 2
	cat $TMPFILE >& 2
	echo "" >> $TGTFILE
    else
	sed -n "${LINE},${LINE}p" $TGTCORPUS >> $TGTFILE
    fi
done < $SRCFILE

rm $TMPFILE

