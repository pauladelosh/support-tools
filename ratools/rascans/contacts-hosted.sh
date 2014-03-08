#!/bin/bash

function ahtcontacts {
foot=`aht @$1.prod contacts --raw 2>/dev/null </dev/null`
#aht @client.prod drush status

  temp=$IFS
  IFS=$'\n';
  for line in $foot;
  do
    echo "$line,$1,$2,$3";
  done;
  IFS=$temp
}

while read arg
do
  ahtcontacts $arg >> csv/random1.csv
done < 'csv/source_random.csv'
