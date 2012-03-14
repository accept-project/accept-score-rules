#!/bin/bash

if [ $# -lt 4 ] ; then
  echo "Usage: findreftrans.sh segments.src segments.tgt orig.folder ref.folder"
  exit 1
fi


export SRCFILE=$1
export TGTFILE=$2
export SRCFOLDER=$3
export TGTFOLDER=$4

mkdir -p $TGTFOLDER

export TMPFILE=`mktemp`

for FILE in $SRCFOLDER/*.orig ; do
    export OUTFILE=$TGTFOLDER/`basename $FILE .orig`.ref
    echo "Writing reference translations for $FILE to $OUTFILE"
    touch $OUTFILE
    while read -r STR ; do
	echo "$STR" > $TMPFILE
	export LINE=`fgrep --line-number -f $TMPFILE $SRCFILE | head -1 | cut -d ':' -f 1`
	if [ -z "$LINE" ] ; then
            echo "Warning: no line found in $TGTFILE corresponding to the following sentence in $SRCFILE, outputting empty line:" >& 2
	    echo $STR >& 2
	    echo "" >> $OUTFILE
	else
	    sed -n "${LINE},${LINE}p" $TGTFILE >> $OUTFILE
	fi
    done < $FILE
done

rm $TMPFILE

