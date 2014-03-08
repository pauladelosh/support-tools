#!/bin/bash

function ahtpressflow {
foot=`aht @$1.$2 drush5 php-eval 'echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . "\n";' 2>/dev/null </dev/null`
#aht @client.prod drush5 php-eval 'echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . "\n";'

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
  ahtpressflow $arg >> csv/aht_results_random.csv
done < 'csv/source_random.csv'
