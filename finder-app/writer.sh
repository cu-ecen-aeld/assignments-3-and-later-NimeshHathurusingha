#!/bin/bash

handle_error(){
	echo "An error occure"
	exit 1
}

trap handle_error ERR

if [ "$#" -ne 2 ];
then
	echo "Two paramters are needed"
	exit 1
fi

file_path=$1
dir_path=${file_path%/*}

if [ $dir_path != $file_path -a ! -d "$dir_path"  ];
then
	mkdir -p $dir_path
fi

echo $2 > $file_path
