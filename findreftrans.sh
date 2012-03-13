#!/bin/bash

if [ $# -lt 2 ] ; then
  echo "Usage: findreftrans.sh segments.src segments.tgt < lines.src > lines.tgt " >&2
  exit 1
fi


export SRCFILE=$1
export TGTFILE=$2

export TMPFILE=`mktemp`

while read STR ; do
    echo $STR > $TMPFILE
    export LINE=`fgrep --line-number -f $TMPFILE $SRCFILE | cut -d ':' -f 1`
    if [ -z "$LINE" ] ; then
        echo "Warning: no line found in $TGTFILE corresponding to the following sentence in $SRCFILE, outputting empty line:" >& 2
	echo $STR >& 2
	echo ""
    else
	sed -n "${LINE},${LINE}p" $TGTFILE
    fi
done

rm $TMPFILE

