#!/bin/bash
#
# usage: check_file_age.sh [-s <secs>] [-t <secs>] [-f <file>]
#

opt_filesize=$1
opt_time=$2
opt_file=$3
usage="usage: check_file_age.sh [-s <secs>] [-t <secs>] [-f <file>]"



if [[ $opt_file == '' ]];then
   echo $usage
   exit 3
fi

if [[ ! -f $opt_file ]];then
   echo "$File is missing"
   exit 3
fi

filesize=$(stat -c %s $opt_file)

age=$(stat -c %Y $opt_file)

echo $filesize
echo $age

if [ $opt_filesize -gt $filesize ]
then
   echo "Filesize too small: minimum size: $opt_filesize is: $filesize"
   exit 2
elif [ $opt_time -gt $age ]
then
   echo "Fileage too young: maximum age: $opt_time is: $age"
   exit 1
else
   echo "File OK: Size: $filesize Age: $age"
fi
exit 0

