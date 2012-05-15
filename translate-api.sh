#!/bin/bash
echo x

if [ $# -lt 5 ] ; then
    echo "Usage: $0 <srcfolder> <srclang> <tgtfolder> <tgtlang> <api-url>"
    exit 1
fi

export thisdir=`dirname $0`

export srcfolder=$1
shift
export srclang=$1
shift
export tgtfolder=$1
shift
export tgtlang=$1
shift
export apiurl=$1
shift

for file in $srcfolder/* ; do
    if [ -e $tgtfolder/`basename $file` ] ; then
	echo "Skipping translation of $file, since translation already exists" >& 2
    else
	echo "Translating $file" >& 2
	(python $thisdir/accept-client.py -s $srclang -t $tgtlang -y sb -i $file -u $apiurl -o $tgtfolder/`basename $file` 1>&2) || exit 1
    fi
done
