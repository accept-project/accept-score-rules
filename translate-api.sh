#!/bin/bash
#
# Translate all files in a folder using the Google Translate API of a Moses server 
# (wrapper for accept-client.py)
#

if [ $# -lt 5 ] ; then
    echo "Usage: $0 <srcfile> <srclang> <tgtfile> <tgtlang> <api-url>"
    exit 1
fi

export thisdir=`dirname $0`

export srcfile=$1
shift
export srclang=$1
shift
export tgtfile=$1
shift
export tgtlang=$1
shift
export apiurl=$1
shift

(python -u $thisdir/accept-client.py -s $srclang -t $tgtlang -y sb -i $srcfile -u $apiurl -o $tgtfile) || exit 1
