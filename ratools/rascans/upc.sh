#!/bin/bash

function ahtupc {
foot=`aht --$4 @$1.$2 drush5 --uri=$3 upc --pipe 2>/dev/null </dev/null`
#aht @microtech.prod drush upc --pipe
  temp=$IFS
  IFS=$'\n';
  for line in $foot;
  do
    echo "$line,$1,$2,$3,$5";
  done;
  IFS=$temp
  #  2>/dev/null </dev/null| tr -d
  #  ahmc @sevengen.test ssh 'sudo -u sevengen drush @sevengen.test upc --pipe --security-only'
}

while read arg
do
  ahtupc $arg >> csv/aht_results_upc.csv
done < 'csv/source_sites.csv'
