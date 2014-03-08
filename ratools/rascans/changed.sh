#!/bin/bash

# function ahtchanged {
# foot=`aht @$1 "\|" grep "WELCOME" 2>/dev/null </dev/null`
# #aht @sitename | grep "^\-\- Deleted"

#   temp=$IFS
#   IFS=$'\n';
#   for line in $foot;
#   do
#     echo "$line,$1,$2";
#   done;
#   IFS=$temp
# }

# while read arg
# do
#   ahtchanged $arg >> csv/aht_random.csv
# done < 'csv/source_random.csv'

function ahtcorevers {
foot=`aht --@4 @$1.$2 drush5 --uri=$3 status drupal-version --pipe 2>/dev/null </dev/null`
#aht @client.prod drush status

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
  ahtcorevers $arg >> csv/aht_random.csv
done < 'csv/source_random.csv'
