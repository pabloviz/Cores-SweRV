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

echo "B7 01 58 D0" >> $2
echo "93 02 F0 0F" >> $2
echo "23 80 51 00" >> $2
echo "E3 0A 00 FE" >> $2
echo "13 00 00 00" >> $2
echo "13 00 00 00" >> $2
echo "13 00 00 00" >> $2
