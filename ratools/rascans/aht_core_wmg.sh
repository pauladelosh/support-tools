#!/bin/bash

function ahtdrupverswmg {
foot=`aht --$4 @$1.$2 ssh sudo -u warnermusic drush5 @$1.$2 status drupal-version --pipe 2>/dev/null </dev/null`
#aht @wmgamnesty.prod ssh sudo -u warnermusic drush @wmgamnesty.prod status --uri=status
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
  ahtdrupverswmg $arg >> csv/aht_results_core_wmg.csv
done < 'csv/source_sites_wmg.csv'
