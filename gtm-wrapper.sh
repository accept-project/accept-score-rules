#!/bin/bash

export REFTMPFILE=`mktemp`
export CANDTMPFILE=`mktemp`

while read -r REF; do
    read -r CAND
    echo $REF > $REFTMPFILE
    echo $CAND > $CANDTMPFILE
    echo `java -jar gtm.jar -t $CANDTMPFILE $REFTMPFILE 2>/dev/null | cut -d ' ' -f 2`
done

rm $REFTMPFILE
rm $CANDTMPFILE

