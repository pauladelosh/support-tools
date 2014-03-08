#!/bin/bash
#
#  Usage:
#  Change module name to check for a specific module: in foot, do 'pmi modulename'
#  aht @almondboard | grep WELCOME | awk '{print $5}'
function ahtwelcome {
  foot=`aht @$1.prod "\|" grep WELCOME "\|" awk '{print $5}' 2>/dev/null </dev/null`

  temp=$IFS
  IFS=$'\n';
  for line in $foot;
  do
    echo "$line,$1,$2,$5";
  done;
  IFS=$temp
}

while read arg
do
  ahtwelcome $arg >> csv/random1.csv
done < 'csv/source_sites.csv'
