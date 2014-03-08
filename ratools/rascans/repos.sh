#!/bin/bash
#
#  Usage:
#  Change module name to check for a specific module: in foot, do 'pmi modulename'
#  aht @etr.prod ssh sudo -u root du -sh /var/www/repo/etr | awk '{print $1}'
function ahtserver {
  foot=`aht --$4 @$1.$2 ssh sudo -u root du -sk /var/www/repo/$1 "\|" awk '{print $1}' 2>/dev/null </dev/null`

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
done < 'csv/source_random.csv'
