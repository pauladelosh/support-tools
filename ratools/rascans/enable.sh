#!/bin/bash

function ahtenable {
foot=`aht @$1.$2 drush --uri=@3 en update --yes 2>/dev/null </dev/null`
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
  ahtenable $arg >> csv/random2.csv
done < 'csv/source_sites_wmg.csv'