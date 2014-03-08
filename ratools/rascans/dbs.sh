#!/bin/bash
#
#  Usage:
#  Change module name to check for a specific module: in foot, do 'pmi modulename'
#  aht @bnorris.dev drush5 sqlq "select table_schema, sum( data_length + index_length)/1024/1024 from information_schema.tables group by table_schema;"
#  or
#  aht @etr.prod drush5 sqlq "select table_schema 'DB name', round(sum( data_length + index_length)/1024/1024) 'Size in MB' from information_schema.tables where table_schema = 'etrprod;"
function ahtserver {
  foot=`aht @$1.$2 drush5 sqlq "select table_schema, sum( data_length + index_length)/1024/1024 from information_schema.tables group by table_schema;"  2>/dev/null </dev/null`

  temp=$IFS
  IFS=$'\n';
  for line in $foot;
  do
    echo "$line,$1,$5";
  done;
  IFS=$temp
}

while read arg
do
  ahtserver $arg >> csv/random1.csv
done < 'csv/source_sites.csv'
