#!/bin/bash
#
# A wrapper for GTM that reads the reference segment and the candidate segment from the command-line, writes them into temp files,
# passes them to GTM, cuts out the score and writes the score to stdout. The wrapper is used in conjunction with score-ref.pl 
# (which in turn reads files and passes them line-by-line to this wrapper - completely inefficient and unnecessary, but well...)

export THISDIR=`dirname $0`
export REFTMPFILE=`mktemp --tmpdir=$THISDIR`
export CANDTMPFILE=`mktemp --tmpdir=$THISDIR`

while read -r REF; do
    read -r CAND
    echo $REF > $REFTMPFILE
    echo $CAND > $CANDTMPFILE
    echo `java -jar $THISDIR/gtm.jar -e 1.2 -t $CANDTMPFILE $REFTMPFILE 2>/dev/null | cut -d ' ' -f 2`
done

rm $REFTMPFILE
rm $CANDTMPFILE

