#!/bin/bash

function ahtcorevers {
foot=`aht --$4 @$1.test drush5 --uri=$3 status drupal-version --pipe 2>/dev/null </dev/null`
#aht @client.prod drush status

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
  ahtcorevers $arg >> csv/aht_results_core_testenv.csv
done < 'csv/source_sites.csv'
