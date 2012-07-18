#!/bin/bash
# A wrapper for TER that reads the reference segment and the candidate segment from the command-line, writes them into temp files,
# passes them to TER, cuts out the score and writes the score to stdout. The wrapper is used in conjunction with score-ref.pl 
# (which in turn reads files and passes them line-by-line to this wrapper - completely inefficient and unnecessary, but well...)

export THISDIR=`dirname $0`
export REFTMPFILE=`mktemp --tmpdir=$THISDIR`
export CANDTMPFILE=`mktemp --tmpdir=$THISDIR`
export OUTTMPFILE=`mktemp --dry-run --tmpdir=$THISDIR`

while read -r REF; do
    read -r CAND
    echo $REF "  (0)" > $REFTMPFILE
    echo $CAND "  (0)" > $CANDTMPFILE
    java -jar $THISDIR/tercom.7.25.jar -r $REFTMPFILE -h $CANDTMPFILE -n $OUTTMPFILE -o ter > /dev/null
    tail -n +3 $OUTTMPFILE.ter | cut -d ' ' -f 4
done

rm $REFTMPFILE
rm $CANDTMPFILE
rm $OUTTMPFILE.ter