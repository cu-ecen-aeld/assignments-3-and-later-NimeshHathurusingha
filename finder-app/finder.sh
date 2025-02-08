#!/bin/bash

handle_error(){
	echo "En Error Occure"
	exit 1
}

trap handle_error ERR

if [ 2 -ne $# ];
then
	echo "two paramter are needed"
	exit 1
fi

filedir=$1
searchstr=$2

if [ -d "$filedir" ];
then
	file_count=$(grep "$searchstr" $filedir/*.txt -c | wc -l)
	match_count=$(grep "$searchstr" $filedir/*.txt | wc -l)
	echo "The number of files are $file_count and the number of matching lines are $match_count"
else
	echo "file diretcory is wrong"
	exit 1
fi
