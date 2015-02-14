#!/bin/sh

if [[ $# -lt 1 ]]
then
   echo "Usage: $0 <dirToProcess>"
   exit 1
fi

fileList=`ls $1/*R?.pdf $1/*R??.pdf`
for target in $fileList
do
   fname=`basename $target`
   echo "Processing $fname"
   parse1.rb $1/$fname > "${fname}.dat"
done

echo "done."
exit 0
