#!/bin/bash

function ahtcontacts {
foot=`aht contacts --uuid=$1 --raw 2>/dev/null </dev/null`
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
  ahtcontacts $arg >> csv/contacts.csv
done < 'csv/source_sites.csv'
