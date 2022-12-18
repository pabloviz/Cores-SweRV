#!/bin/bash
rm $2
input=$1
while IFS= read -r line
do
  first=`echo "$line" | cut -b 7-8`;
  second=`echo "$line" | cut -b 5-6`;
  third=`echo "$line" | cut -b 3-4`;
  fourth=`echo "$line" | cut -b 1-2`;
  echo $first $second $third $fourth >> $2
done < "$input"
