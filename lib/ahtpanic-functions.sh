#!/bin/bash

#####################################
# Functions
#####################################

# SSHs into an address in a way that won't generate (too many?) strict warnings
function ahtssh() {
  ssh -t -t -o StrictHostKeyChecking=no -o LogLevel=quiet $@
}

# Create SSL tunnel to DB on local port 33066
# Usage: ahtdbtunnel site.env
function ahtdbtunnel() {
  echo "Getting DB connection string:"
  aht @$@ drush sql-connect
  echo "Running ssh tunnel to $@ on local port 33066..."
  db=`ahtactivedb $@`
  ahtssh -N -L 33066:localhost:3306 $db
}

# Print out the active DB server (e.g. fsdb-1234 or ded-1234)
# Usage: ahtactivedb site.env
function ahtactivedb() {
  aht @$@ |fgrep active |cut -f2 -d' '
}
# Returns either the passive DB (if prod) or the active one
function ahtpassiveoractivedb() {
  aht $STAGE @$1 |tr -d '\015' | awk '
  # Match xxx-123
  NR == 1 { found_active_flag = 0 }
  $1 ~ /^[a-z]+-[0-9]+/ {
    if (found_active_flag == 1) {
      passive_db_host = $1;
      found_active_flag = 0;
    }
    if ($2 == "active-db") {
      active_db_host = $1;
      found_active_flag=1
    }
  }
  END {
    print passive_db_host ? passive_db_host : active_db_host;
  }'
}
# Show last 2000 lines of slow query log from the active DB
# Usage: ahtslowquerylog site.env
function ahtslowquerylog() {
  db=`ahtactivedb $@`
  ahtssh $db "sudo cat /var/lib/mysql/${db}-slow.log /var/lib/mysql/mysqld-slow.log 2>/dev/null |tail -5000"
}
# Dump the results of mk-query-digest (using the active dbmaster's slow query log) to stdout
# Usage: ahtslowquerydigest site.env
function ahtslowquerydigest() {
  db=`ahtactivedb $@`
  ahtssh $db "sudo cat /var/lib/mysql/${db}-slow.log /var/lib/mysql/mysqld-slow.log 2>/dev/null >/mnt/tmp/mysqld-slow.log; sudo mk-query-digest /mnt/tmp/mysqld-slow.log"
}

# Get the name(s) of the active balancer(s)
function ahtgetactivebals() {
  aht $STAGE @$1 --show=bal |grep ' bal-' |tr -d '\015' | awk '$3+0 > 0 { print $1 }'
}

# Get the names of the web(s)
function ahtgetwebs() {
  aht $STAGE @$1 |tr -d '\015' | egrep "srv-|web-|ded-|staging-" |cut -f2 -d' '
}

# Returns the name of the first web
function ahtfirstweb() {
  #echo ahtfirstweb STAGE:$STAGE site:$1
  ahtgetwebs $1 |head -1
}

# Find the number (1-X) of a web (like web-4917)
# Usage: ahtgetwebnumber sitename.env web-xxxx
function ahtgetwebnumber() {
  ahtgetwebs $1 |grep -n $2 |cut -f1 -d':'
}

# Just output a nice separator!
function ahtsep() {
  echo ""
  echo "${COLOR_GRAY}-----------------------------------------------------------${COLOR_NONE}"
}

# Finds which server a logfile lives at.
# Usage: ahtfindlog sitename.env xyz.log [breakonfirst]
function ahtfindlog() {
  for nom in `ahtgetwebs $1`
  do
    here=`ahtssh $nom 'sudo find /var/log/sites/'"$1"'/logs/'"$nom/$2"' -size +1k 2>/dev/null'`
    if [ "${here:-x}" != x ]
    then
      echo $nom:$here
      if [ "${3:-x}" = "breakonfirst" ]
      then
        break
      fi
    fi
  done
}

# Shorthand aht command used by ahtaudit command (below)
function ahtaht() {
  #echo "** Aht command:    aht $STAGE @$SITENAME $URI $@" 1>&2
  aht $STAGE @$SITENAME $URI $@ |tr -d '\015'
}

function ahtfiglet() {
  which figlet >/dev/null
  if [ $? -eq 0 ]
  then
    figlet -k -f slant $@
  fi
}

# Output a non-empty file, otherwise show a message
function ahtcatnonempty() {
  if [ `grep -c . $1` -eq 0 ]
  then
    echo "  $2"
  else
    #Output header
    if [ "${3:-x}" != x ]
    then
      echo $3
    fi
    cat $1
  fi
}

# 
function test_nagios_info() {
  # Nagios urls
  echo "Nagios link:"
  url="https://tasty.acquia.com/check_mk/view.py?view_name=hostgroup&hostgroup=prod_${site}_servers"
  if [ $devcloud -eq 1 ]
  then
    url="https://devcloud-mon.acquia.com/check_mk/view.py?view_name=hostgroup&hostgroup=devcloud_${site}_servers"
  fi
  echo $url
  ahtsep
  
  # Nagios downtime
  if [ $devcloud -eq 0 -a "${CONFIG_NAGIOS_USERPASS:-x}" != x ]
  then
    echo "Detected downtime from nagios:"
    nagios_url="https://perf-mon.acquia.com/site_downtime.php?stage=mc&sitename=${site}"
    curl -s "${nagios_url}" >$tmpout
    if [ `grep -c "401 Authorization Required" $tmpout` -eq 0 ]
    then
      cat $tmpout |sed -e "s/<br>/\n/g" |sed -e '1,2d' |grep '20.*$' >$tmpout2
      if [ `grep -c . $tmpout2` -gt 0 ]
      then
        head -15 $tmpout2 |egrep --color=always "^|"`date +%Y-%m-%d`
        if [ `grep -c . $tmpout2` -gt 15 ]
        then
          echo "  ... Complete list at: ${nagios_url}"
        fi
      else
        echo "  ${COLOR_GREEN}OK: No recent downtime found at ${nagios_url}."
      fi
    else
      echo "  ${COLOR_YELLOW}Can't parse Nagios due to IP restriction."
      echo "  Try either using the VPN or viewing on your browser instead:"
      echo "     ${nagios_url}"
    fi
    echo "${COLOR_NONE}"
    ahtsep
  fi
}

# Link to helpful graphs.
function test_balancer_graphs() {
  hours=12
  stage='prod'
  if [ $devcloud -eq 1 ]
  then
    stage='devcloud'
  fi
  
  echo "Graph of HTTP requests, per type, last ${hours} hours, per active balancer:"
  for bal in $bals
  do
    echo " $bal :"
    url="http://stats-2.acquia.com/render/?width=1613&height=822&_salt=1360104080.634&target=logster.varnish.${stage}.${bal}.http_2xx&target=logster.varnish.${stage}.${bal}.http_3xx&target=logster.varnish.${stage}.${bal}.http_4xx&target=logster.varnish.${stage}.${bal}.http_5xx&from=-${hours}hours"
    echo $url
  done
  #xdg-open "$url"
  ahtsep
}

# Get PHP memory limit
function test_php_memory_limit() {
  echo "Checking memory limits/use:"
  ahtaht ini-grep memory |egrep --color=always "^|[2-9][0-9][0-9][0-9]*"
  ahtsep
}

# Get Varnish cached/uncached statistics
function test_varnish_stats() {  
  echo "Varnish cached/uncached statistics for last 2 days"
  ahtaht stats --start=yesterday --end=now --csv | awk -F',' 'BEGIN { OFS=","; uncached_ratio_bad=0.075 } NR==1 { print $0 } (NR>1 && $4>0) { if (($5/$4) > uncached_ratio_bad) { $5 = "'$COLOR_RED'" $5 "'$COLOR_NONE'"; } print $0 } END { if (NR==1) { print "No_data.";   } }' |column -t -s','
  ahtsep
}
  
#PHP-CGI Check process limit settings, number of skip spawns
function test_phpcgi_procs() {
  echo "Checking PHP proc limits/status:"
  ahtaht php-cgi --conf |grep -v defunct |awk '
    function alert(value, flag) {
      #return (flag ? "'$COLOR_RED'" : "") value "'$COLOR_NONE'";
      return value (flag ? "⚠warn!" : "");
    }
    BEGIN { 
      user="'${site}'";
      # Header 
      print "Server MaxProcsTotal ActiveTotal MaxProcs-" user " Active-" user " FreeMem TotalMem"
    }
    # Line with the server
    /\[/ { 
      server=substr($0, 2, length($0)-2);
      # Reset running counts.
      total_running=0;
      docroot_running=0;
    }
    $1==user && $2>0 { docroot_running++; }
    /procs running/ { total_running=$1; }
    /MaxProcessCount/ { max_overall=$2; }
    /DefaultMaxClass/ { 
      max_docroot=$2;
      # Get memory info from server.
      "ssh -o StrictHostKeyChecking=no -o LogLevel=quiet " server " free -m |grep Mem" |getline;
      total_mem=$2; 
      free_mem=$3;
      # Print the line
      print server " " max_overall "  " total_running " " max_docroot " " alert(docroot_running, docroot_running>=max_docroot) " " alert(free_mem, free_mem/total_mem <0.2) "kB " total_mem "kB";
    }' |column -t
  ahtsep
}

# PHP-CGI
function test_phpcgi_skips() {
  #ahtssh $web "sudo grep \"skip the spawn request\" /var/log/apache2/error.log |awk -F: '{ print \$1 \":\" substr(\$2,1,1) \"X:XX\" }' |sort |uniq -c" >$tmpout
  ahtssh $web "sudo grep \"skip the spawn request\" /var/log/apache2/error.log |awk -F: '{ print substr(\$1,2) \":XX\" }' |sort |uniq -c" >$tmpout
  echo "Skip-spawns for today:"
  ahtcatnonempty $tmpout "${COLOR_GREEN}OK: No skip spawns found.${COLOR_NONE}" "${COLOR_RED}"
  ahtsep
}

#FPM
function test_phpfpm_skips() {
  #echo 'tail -5000 fpm-error.log | grep "you may need to increase pm.start_servers"' |ahtaht ssh logs |awk -F: '{ print $1 ":" substr($2,1,1) "X:XX" }' |sort |uniq -c  >$tmpout
  echo 'tail -5000 fpm-error.log | grep "you may need to increase pm.start_servers"' |ahtaht ssh logs |awk -F: '{ print $1 ":XX:XX" }' |sort |uniq -c  >$tmpout
  echo "Skip-spawns for today:"
  ahtcatnonempty $tmpout "${COLOR_GREEN}OK: No skip spawns found.${COLOR_NONE}" "${COLOR_RED}"
  ahtsep
}

# Check DNS is pointing at Acquia.
function test_dns() {
  echo "Checking domains against DNS:"
  ahtaht dc |sort -k 3,3 |egrep --color=always "^|not pointing at Acquia|No DNS entry" >$tmpout
  ahtcatnonempty $tmpout "${COLOR_RED}No domains configured.${COLOR_NONE}"
  ahtsep
}

# Flag any important recent tasks.
function test_tasks() {
  days=5
  echo "Last $days days' workflow messages:"
  ahtaht tasks --days=$days |egrep --color=always -i "^|commit|elevate code|reboot|"`date +%Y-%m-%d` >$tmpout
  ahtcatnonempty $tmpout "${COLOR_GREEN}No messages found in last $days days."
  ahtsep
}

# Check for Pressflow
function test_pressflow() {
  echo "Checking for Pressflow/D7:"
  # Copy script to web
cat <<EOF >$tmpout
<?php
list(\$v, ) = explode(".", VERSION);
if (\$v == 6) { 
echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . " " . VERSION . "\n"; 
}
else { 
echo "Drupal " . VERSION . "\n";
}
EOF
  scp -q $tmpout $web:/tmp/tmpscript.php 2>/dev/null
  ahtaht drush scr /tmp/tmpscript.php >$tmpout2 2>/dev/null
  if [ `grep -c "Drupal 6" $tmpout2` -gt 0 ]
  then
    echo "  ${COLOR_RED}: WARNING: D6 installed; No Pressflow:"
    ahtfiglet "No Pressflow!"
  else
    echo "  ${COLOR_GREEN}Drupal version OK:"
  fi
  cat $tmpout2
  ahtsep
}

# Varios tests around modules
function test_modules() {
  echo "Checking for any known offending modules that are enabled:"
  # Get list of all enabled modules
  ahtaht drush pml --type=module --status=enabled --pipe |tr -d '\015' >$tmpout
  
  # Check for offending modules
  # TODO: Separate criticals from warnings
  egrep  "^(dblog|quicktabs|civicrm|pubdlcnt|db_maintenance|role_memory_limit|fupload|plupload|boost|backup_migrate|ds|search404|hierarchical_select|mobile_tools|taxonomy_menu|recaptcha|performance|statistics|elysia_cron|supercron|multicron|varnish|cdn|fbconnect|migrate|cas|context_show_regions|imagefield_crop|session_api|role_memory_limit|filecache|session_api)$" $tmpout >$tmpout2 2>/dev/null
  if [ `grep -c . $tmpout2` -gt 0 ]
  then
    echo $COLOR_RED
    awk '{ print "  " $0 }' $tmpout2
    echo "$COLOR_NONE"
    echo "  See per-module details here:"
    echo "    https://docs.acquia.com/articles/module-incompatibilities-acquia-cloud"
    echo "    https://docs.google.com/a/acquia.com/spreadsheet/ccc?key=0Ash1ngKLN4uYdExPVzNFeV9QSm5WdjBWRDZKa09yUEE#gid=0"
  else
    echo "  ${COLOR_GREEN}OK: No offending modules found.${COLOR_NONE}"
  fi
  ahtsep
  
  # Check for how many modules enabled
  num=`grep -c . $tmpout`
  if [ $num -gt 150 ]
  then
    echo "Checking number of modules enabled:"
    echo "  ${COLOR_RED}WARNING: >150 modules enabled! ($num)"
    ahtfiglet $num' modules enabled!'
    echo "${COLOR_NONE}"
    ahtsep
  fi
  
  # Check for modules that need security updates
  echo "Checking for modules that need security updates:"
  # If update module is enabled...
  if [ `grep -c update $tmpout` -eq 1 ]
  then
    ahtaht drush upc --security-only --pipe --simulate |grep -v "wget" |tr -d '\015' >$tmpout 2>&1
    ahtcatnonempty $tmpout "${COLOR_GREEN}OK: No modules need security updates.${COLOR_NONE}" "$COLOR_RED"
  else
    echo "  ${COLOR_YELLOW}Update.module disabled, can't check status of security updates.${COLOR_NONE}"
  fi
  ahtsep
}

# Check caching settings
function test_cacheaudit() {
  echo "Cacheaudit of site:"
  echo ""
  ahtaht cacheaudit >$tmpout 2>&1
  awk '{ print "  " $0 }' $tmpout |grep -v "Disabled" |egrep --color=always '^|page_cache_maximum_age  *0| cache  *0|Enabled  *($|none)'
  ahtsep
}

# Check DB size
function test_dbsize() {
  echo "Showing largest database tables:"
  cat <<EOF |ahtaht drush sql-cli |column -t |awk '{ print "  " $0 }' |egrep --color=always '| [1-9]\.[0-9][0-9][MG]'
SELECT CONCAT(table_schema, '.', table_name) as Table_name,
CONCAT(ROUND(table_rows / 1000000, 2), 'M') rows,
CONCAT(ROUND(data_length / ( 1024 * 1024 * 1024 ), 2), 'G') DATA,
CONCAT(ROUND(index_length / ( 1024 * 1024 * 1024 ), 2), 'G') idx,
CONCAT(ROUND(( data_length + index_length ) / ( 1024 * 1024 * 1024 ), 2), 'G') total_size,
ROUND(index_length / data_length, 2) idxfrac
FROM information_schema.TABLES
ORDER BY data_length + index_length DESC
LIMIT 10;
EOF
  ahtsep
}

function test_ahtaudit() {
  echo "Problems found from basic site audit:"
  ahtaht audit >$tmpout
  if [ `grep -c "Drush was not able to start" $tmpout` -gt 0 ]
  then
    echo "  ${COLOR_RED}ERROR: Drush not bootstrapping!${COLOR_NONE}"
    echo "You may want to try with a --uri argument using a valid URI."
    echo "Here are the sites on the docroot:"
    ahtaht sites | awk '{ print "  " $0}'
    drushworks_flag=0
  else
    drushworks_flag=1
    echo $COLOR_YELLOW
    cat $tmpout |grep error|tr -d '\015' |sed 's:\x1B\[[0-9;]*[mK]::g'|sed 's/\[error\]//g'|sed 's/[ \t]*$//' |awk '{ print "  " $0 }'
    echo "$COLOR_NONE"
    echo "* See canned suggestions at:
  https://support.acquia.com/doc/index.php/Performance_AHT_AUDIT_advise"
  fi  
  ahtsep
}
  
# Check for duplicate module files
function test_duplicatemodules() {
  # Get the really-real enabled projects first:
  # TODO: doesn't work with table prefixes yet.
  echo "SELECT filename FROM system WHERE type IN ('module', 'theme', 'profile') AND status='enabled'" | ahtaht drush sql-cli |sed -e 's/\.module/.info/g' -e 's/\.theme/.info/g' >$tmpout2
  # Now show all duplicates. showing which one (if any) is really enabled.
  echo "Check for duplicate modules/themes:"
  echo 'find modules themes sites profiles -name "*.info" -type f | grep -oe "[^/]*\.info" | sort | uniq -d | egrep -v "drupal_system_listing_(in|)compatible_test" | xargs -I{} find . -name "{}" |cut -f2- -d/' |ahtaht ssh html >$tmpout
  if [ `grep -c . $tmpout` -gt 0 ]
  then
    # Print out list, inserting extra newline when last /xxxx component not equal.
    awk -F '/' '
      function output_stuff() {
        # Print out what is enabled
        if (enabled_file) {
          print "  '${COLOR_GREEN}'" enabled_file " <== enabled'${COLOR_NONE}'";
          print "  " not_enabled_file;
          print ""
        }
      }
      NR==1 { 
        last=$NF;
        # Read in list of enabled projects and put it on enabled[] array.
        while (getline path < "'$tmpout2'") { 
          enabled[path]=path; 
        }
      } 
      last!=$NF {
        output_stuff();
        enabled_file="";
        not_enabled_file="";
      }
      {
        if (enabled[$0]) { 
          enabled_file=$0
        }
        else {
          not_enabled_file=$0
        }
        last=$NF;
      }
      END {
        output_stuff()
      }' $tmpout
  else
    echo "  ${COLOR_GREEN}OK: No duplicate module/theme candidates found.${COLOR_NONE}"
  fi
  ahtsep
}

# Check Drupal variables and size
function test_vars() {
  echo "Checking size (in bytes) and quantity of Drupal variables:"
  echo "SELECT count(1) as Num_of_Variables, max(length(value)) as Maximum_variable_size, sum(length(value)) as Combined_variables_size FROM variable\\G" |ahtaht drush sql-cli | sed -n '2,$p' >$tmpout
  egrep --color=always "^|Num_of_Variables: [0-9][0-9][0-9][0-9][0-9]*|Maximum_variable_size: [0-9][0-9][0-9][0-9][0-9][0-9]*|Combined_variables_size: [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*" $tmpout
  ahtsep
}
  
# Run ahtaudit script on access.log
function test_logs() {
  echo "Looking for and analyzing access.log..."
  if [ ! -r $HELPER_SCRIPTS_PATH/bin/aht-log-report.sh ]
  then
    echo "  ${COLOR_YELLOW}Could not find $HELPER_SCRIPTS_PATH/bin/aht-log-report.sh!"
    echo "  Check that it exists and try again.${COLOR_NONE}"
    ahtsep
    return
  fi
  tmpscript=/tmp/ahtaudit_script.$$.bash
  findlog=`ahtfindlog $SITENAME access.log |head -1`
  if [ ${findlog:-x} != x ]
  then
    server=`echo $findlog |cut -f1 -d:`
    #logfile=`echo $findlog |cut -f2 -d:`
    echo "  access.log is in $server."
    #echo $logfile
    scp -q $HELPER_SCRIPTS_PATH/bin/aht-log-report.sh $server:$tmpscript 2>/dev/null
    if [ $env != 'prod' ]
    then
      site=$site$env
    fi
    ahtsep
    echo "bash $tmpscript $site" | ahtaht ssh logs 
  else
    echo "  ${COLOR_YELLOW}No access.log found!${COLOR_NONE}"
    echo ""
    ahtsep
  fi
}
  
# Run ahtaudit script on drupal-watchdog.log
function test_drupalwatchdog() {
  echo "Looking for and analyzing drupal-watchdog.log ..."
  if [ ! -r $HELPER_SCRIPTS_PATH/bin/aht-drupal-requests-report.sh ]
  then
    echo "  ${COLOR_YELLOW}Could not find $HELPER_SCRIPTS_PATH/bin/aht-drupal-requests-report.sh!"
    echo "  Check that it exists and try again.${COLOR_NONE}"
    ahtsep
    return
  fi
  tmpscript=/tmp/ahtaudit_script.$$.bash
  findlog=`ahtfindlog $SITENAME drupal-watchdog.log breakonfirst |head -1`
  if [ ${findlog:-x} != x ]
  then
    server=`echo $findlog |cut -f1 -d:`
    logfile=`echo $findlog |cut -f2 -d:`
    echo "  $logfile is in $server."
    scp -q $HELPER_SCRIPTS_PATH/bin/aht-drupal-requests-report.sh $server:$tmpscript 2>/dev/null
    ahtsep
    echo "sudo bash $tmpscript $logfile" | ahtssh $server 
  else
    echo "  ${COLOR_YELLOW}No drupal-watchdog.log found!${COLOR_NONE}"
    echo ""
  fi
}
