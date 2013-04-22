#!/bin/bash
#
#  Usage:
#  Change module name to check for a specific module: in foot, do 'pmi modulename'
#
function ahtmodcheck {
  foot=`$4 @$1.$2 ssh "sudo -u root drush5 --uri=$3 \@$1.$2 pmi update | grep Status" 2>/dev/null </dev/null | awk '{print $1,","$2,","$3","$4}' | tr -d '\r'`
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
  ahtmodcheck $arg >> csv/aht_results_modcheck.csv
done < 'csv/source_sites.csv'
