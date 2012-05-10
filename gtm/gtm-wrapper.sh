#!/bin/bash

export THISDIR=`dirname $0`
export REFTMPFILE=`mktemp --tmpdir=$THISDIR`
export CANDTMPFILE=`mktemp --tmpdir=$THISDIR`

while read -r REF; do
    read -r CAND
    echo $REF > $REFTMPFILE
    echo $CAND > $CANDTMPFILE
    echo `java -jar $THISDIR/gtm.jar -t $CANDTMPFILE $REFTMPFILE 2>/dev/null | cut -d ' ' -f 2`
done

rm $REFTMPFILE
rm $CANDTMPFILE

