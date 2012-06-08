#!/bin/bash

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