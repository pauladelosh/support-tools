#!/bin/bash

function ahtdeleted {
foot=`aht @$1.prod "\|" grep "^\-\- Delet" 2>/dev/null </dev/null`
#aht @sitename | grep "^\-\- Deleted"

  temp=$IFS
  IFS=$'\n';
  for line in $foot;
  do
    echo "$line,$1,$2";
  done;
  IFS=$temp
}

while read arg
do
  ahtdeleted $arg >> csv/random2.csv
done < 'csv/source_sites.csv'