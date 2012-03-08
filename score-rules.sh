#!/bin/bash

if [ $# -lt 2 ] ; then
  echo "Usage: score-rules.sh file language-model-file [autoApplyOptions] "
  echo " autoApplyOptions: e.g. -h host -p port -u user --pass pwd -l lang -r ruleset"
  exit 1
fi

export inputfile=$1
shift
export lm=$1
shift

[ ! -e $inputfile ] && { echo "Input file does not exist" ; exit 2; }
[ ! -e $lm ] && { echo "Language model file does not exist" ; exit 3; }

export subfolder=$inputfile.eval

rm -rf $subfolder
mkdir $subfolder

java -jar autoApplyClient/autoApplyClient-0.1.1-SNAPSHOT.jar -applySeparately -suppressResults -o $subfolder $* $inputfile

#tokenizer
#truecaser
#/home/build/mosesdecoder/irstlm/bin/add-begin-end.sh 

perl score-and-eval.pl $subfolder $inputfile $lm
