#!/bin/bash
#
#  Usage:
#  Change module name to check for a specific module: in foot, do 'pmi modulename'
#  aht @etr.prod ssh sudo -u root du -sh /var/www/repo/etr | awk '{print $1}'
function ahtserver {
  foot=`aht @$1.prod "\|" grep prod "\|" awk '{print $7}' 2>/dev/null </dev/null`

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
  ahtserver $arg >> csv/random2.csv
done < 'csv/source_sites.csv'
