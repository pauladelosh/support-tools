#!/bin/bash
#
#  Usage:
#  Change module name to check for a specific module: in foot, do 'pmi modulename'
#   aht @powerone | grep staging | awk '{print $1}'
function ahtserver {
  foot=`aht @$1 "\|" grep "staging" "\|" awk '{print $1}' 2>/dev/null </dev/null`

  temp=$IFS
  IFS=$'\n';
  for line in $foot;
  do
    echo "$line,$1,$5";
  done;
  IFS=$temp
}

while read arg
do
  ahtserver $arg >> csv/aht_random.csv
done < 'csv/source_sites.csv'
