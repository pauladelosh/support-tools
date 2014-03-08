#!/bin/bash

function ahtsites {
foot=`aht @$1.$2 sites 2>/dev/null </dev/null`
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
  ahtsites $arg >> csv/random1.csv
done < 'csv/source_random.csv'
