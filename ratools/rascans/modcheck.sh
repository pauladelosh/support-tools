#!/bin/bash
#
#  Usage:
#  Change module name to check for a specific module: in foot, do 'pmi modulename'
#
function ahtmodcheck {
  foot=`aht @$1.$2 drush5 pmi fb_tweet "\|" grep "Status" "\|" awk '{print $3}' 2>/dev/null </dev/null`

  #aht @aeuk.prod drush5 pmi og | grep Status | awk '{print $3}'
  temp=$IFS
  IFS=$'\n';
  for line in $foot;
  do
    echo "fb_tweet,$line,$1,$2,$5";
  done;
  IFS=$temp
}

while read arg
do
  ahtmodcheck $arg >> csv/aht_results_modcheck.csv
done < 'csv/source_sites_wmg.csv'
