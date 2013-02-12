#!/bin/bash

function ahtupcsec {
foot=`aht --$4 @$1.$2 drush --uri=$3 upc --pipe --security-only 2>/dev/null </dev/null`
#aht @microtech.prod drush upc --pipe --security-only
  temp=$IFS
  IFS=$'\n';
  for line in $foot;
  do
    echo "$line,$1,$2,$3,$5";
  done;
  IFS=$temp
}

while read arg
do
  ahtupcsec $arg >> csv/aht_results_upc_sec.csv
done < 'csv/source_sites.csv'
