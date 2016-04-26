#!/bin/bash

#####################################
# Functions
#####################################
AHTCOMMAND="aht"

# SSHs into an address in a way that won't generate (too many?) strict warnings
function ahtssh() {
  option="-o LogLevel=quiet"
  if [ $VERBOSE -eq 1 ]
  then
    option=""
    echo "${COLOR_GRAY}-- ssh -t -o StrictHostKeyChecking=no $option -F $HOME/.ssh/ah_config $@ ${COLOR_NONE}" >/dev/stderr
  fi
  ssh -t -o StrictHostKeyChecking=no $option -F $HOME/.ssh/ah_config $@ |tr -d '\015'
}

function ahtssh2() {
  option="-o LogLevel=quiet"
  if [ $VERBOSE -eq 1 ]
  then
    option=""
    echo "${COLOR_GRAY}-- ssh -t -o StrictHostKeyChecking=no $option -F $HOME/.ssh/ah_config $@ ${COLOR_NONE}" >/dev/stderr
  fi
  ssh -t -o StrictHostKeyChecking=no $option -F $HOME/.ssh/ah_config $@
}

# Create SSL tunnel to DB on local port 33066
# Usage: ahtdbtunnel site.env
function ahtdbtunnel() {
  echo "Getting DB connection string:"
  $AHTCOMMAND @$@ $DRUSHCMD $URI sql-connect
  echo "Running ssh tunnel to $@ on local port 33066..."
  db=`ahtactivedb $@`
  ahtssh -N -L 33066:localhost:3306 $db
}

# Print out the active DB server (e.g. fsdb-1234 or ded-1234)
# Usage: ahtactivedb site.env
function ahtactivedb() {
  $AHTCOMMAND @$@ |fgrep active |cut -f2 -d' '
}
# Returns either the passive DB (if prod) or the active one
function ahtpassiveoractivedb() {
  $AHTCOMMAND $STAGE @$1 |tr -d '\015' | awk '
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
  ahtaht sitegroup:info --show=bal |grep ' bal-' | awk '$3+0 > 0 { print $1 }'
}

# Returns the name of the first web
function ahtfirstweb() {
  echo $webs |cut -f1 -d' '
}

# Just output a nice separator!
function ahtsep() {
  echo ""
  echo "${COLOR_GRAY}-----------------------------------------------------------${COLOR_NONE}"
}

# Finds which server a logfile lives at.
# Usage: ahtfindlog sitename.env xyz.log [breakonfirst]
function ahtfindlog() {
  for nom in $webs_raw
  do
    domainless=`echo $nom |cut -f1 -d.`
    here=`ahtssh $nom 'sudo find /var/log/sites/'$sitefoldername'/logs/'"$domainless/$1"' -size +1k 2>/dev/null'`
    if [ "${here:-x}" != x ]
    then
      echo $nom:$here
      if [ "${2:-x}" = "breakonfirst" ]
      then
        break
      fi
    fi
  done
}

# Shorthand aht command used by ahtaudit command (below)
function ahtaht() {
  #echo "** Aht command:    $AHTCOMMAND $STAGE @$SITENAME $URI $@" 1>&2
  #aht $STAGE @$SITENAME $URI $@ |tr -d '\015'
  aht $STAGE @$SITENAME $@ |tr -d '\015'
}
function ahtaht2() {
  aht $STAGE @$SITENAME $@
}

# Shorthand aht command used by ahtaudit command (below)
function ahtdrush() {
  aht $STAGE @$SITENAME $DRUSHCMD $URI $@ |tr -d '\015'
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
    if [ "${4:-x}" = "TABLE" ]
    then
      cat $1 |column -t
    else
      cat $1
    fi
  fi
}

# Report the amount of email being sent by the webs
# See: https://confluence.acquia.com/pages/viewpage.action?pageId=12158281
function test_email_volume() {
  olddir=`pwd`
  tmpdir=/tmp/test-email-volume-$$
  mkdir $tmpdir && cd $tmpdir
  echo "Reporting on the amount of email sent by the webs for last 5 days:"
  printf "  Fetching logs from: "
  for web in $webs
  do
    printf " $web"
    for logfile in mainlog mainlog.1 $(for i in {2..5} ; do echo "mainlog.$i.gz " ; done)
    do
      printf "."
      rsync --archive -e "ssh -F $HOME/.ssh/ah_config -o StrictHostKeyChecking=no -o LogLevel=quiet" --rsync-path="/usr/bin/sudo /usr/bin/rsync" $web:/var/log/exim4/$logfile $web-$logfile
    done
  done
  echo "done."
  ls | grep -v '.gz' | xargs -I foo gzip foo
  zgrep 'Completed' * | grep -o '[0-9]\{4\}-[0-9]*-[0-9]*' | sort | uniq -c
  ahtsep
  rm -rf $tmpdir
  cd $olddir
}

# Check that all webs have the same code deployed
function test_code_deploy() {
  folder="/var/www/html/$sitefoldername"
  echo "Checking deployed code across every webserver (including out-of-rotation webs) in $folder"
  cat /dev/null >$tmpout
  for web in $webs_raw
  do
    echo "$web: " `ahtssh2 $web "find $folder -maxdepth 4 -type d |wc -l"` >>$tmpout
  done
  awk -F: '
    { n=$2+0; }
    NR==1 {
      max=n; err=0;
    }
    NR > 1 {
      if (n!=max) { err=1; }
      if (n > max) { max = n; }
      data[$1]=n;
    }
    END {
      if (err) {
        print ""; print "PROBLEM FOUND! There should be " max " folders.";
        for (web in data) {
          n=data[web]+0;
          printf web ": " n " folders";
          if (n<max) { printf " ***PROBLEM***"; }
          print "";
        }
      }
      else {
        print ""; print "'$COLOR_GREEN'  OK. " max " folders found in deployed code in every webserver."
      }
    }' $tmpout |egrep --color=always "^|PROBLEM"
  ahtsep
}

function test_show_panic_links() {
  ahtaht2 panic --links
  ahtsep
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
  if [ $devcloud -eq 0 ]
  then
    echo "Detected downtime from nagios:"
    nagios_url="https://perf-mon.acquia.com/site_downtime.php?stage=mc&sitename=${site}"
    curl --max-time 10 -s "${nagios_url}" >$tmpout
    if [ `grep -c "401 Authorization Required" $tmpout` -eq 0 ]
    then
      cat $tmpout |sed -e "s/<br>/\n/g" |sed -e '1,2d' |grep '20.*$' >$tmpout2
      if [ `grep -c . $tmpout2` -gt 0 ]
      then
        today=`date -u +'%Y-%m-%d|%Y-%m-%d %H'`
        head -15 $tmpout2 |egrep --color=always "^|$today"
        #if [ `grep -c . $tmpout2` -gt 15 ]
        #then
          echo "  ... Complete list at: ${nagios_url}"
        #fi
      else
        echo "  ${COLOR_GREEN}OK: No recent downtime found at ${nagios_url}"
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


# Check for XFS freeze
function test_xfs_freeze() {
  echo "Checking XFS freeze:"
  aht $STAGE @$SITENAME ssh --db "ps auxf | grep -A3 [a]h-freeze-mountpoint" >$tmpout
  if [ `grep -c . $tmpout` -gt 0 ]
  then
    echo "${COLOR_YELLOW}POTENTIAL PROBLEM!!! Found xfs frozen:"
    cat $tmpout
    echo ""
    echo "  See: https://backlog.acquia.com/browse/OP-42914 and https://backlog.acquia.com/browse/CL-10193"
  else
    echo "  ${COLOR_GREEN}OK, No freeze found."
  fi
  ahtsep
}

# Get PHP memory limit
function test_php_memory_limit() {
  echo "Checking memory limits/use:"
  ahtaht php:ini-grep memory_limit |egrep --color=always "^|[2-9][0-9][0-9][0-9]*"
  ahtsep
}

# Check hosting release
function test_hosting_release_version() {
  echo "Checking hosting release version:"
  for web in $webs
  do
    echo -n "  $web: "
    ahtssh2 $web "sudo cat /var/acquia/HOSTING_VERSION"
  done
  ahtsep
}

# How are the webs?
function test_webs_cpu() {
  echo "Checking CPU on webs:"
  for web in $webs
  do
    echo "= $web =============";
    ahtssh2 $web "sudo pidstat 2 2" | awk '{ print "  " $0 }' |egrep --color '^|[456789][0-9]\.[0-9][0-9]'
  done
  ahtsep
}

# Check puppet/other messages from syslog
function test_syslog_check() {
  echo "Checking for important /var/log/syslog messages on webs:"
  date_time=`date -u +'%h %_d %H:'`
  date=`date -u +'%h %_d '`
  # webs_raw includes out-of-rotation webs
  for web in $webs_raw
  do
    echo "= $web =============";
    ahtssh2 $web "sudo tail -3000 /var/log/syslog" >$tmpout
    grep -v "AH_SPLIT_BRAIN: Split brain detected: db=acquia" $tmpout | egrep 'not enough memory|could not be unfrozen|Out of memory|Killed process [0-9]* \([^\)]*\)|AH_SERIOUS_|AH_SPLIT_BRAIN|Applying configuration version|ah-callback: task [0-9]* triggering .*| deploying .*|Restarting .*' |egrep --color=always "^|$date_time|$date|not enough memory|could not be unfrozen|Out of memory|Killed process|handling overloaded server|sending 503" |tail -100
  done
  ahtsep
}

# Check puppet/other messages from syslog
function test_daemonlog_check() {
  echo "Checking for important /var/log/daemon.log messages on webs:"
  date_time=`date -u +'%h %_d %H:'`
  date=`date -u +'%h %_d '`
  # webs_raw includes out-of-rotation webs
  for web in $webs_raw
  do
    echo "= $web =============";
    ahtssh2 $web "sudo tail -5000 /var/log/daemon.log" >$tmpout
    fgrep 'AH_SERIOUS_' $tmpout |egrep --color "^|$date_time|$date"
  done
  ahtsep
}

# Check for
function test_nginx_max_conn() {
  echo "Checking for nging max_conn parameter in nginx:"
  echo 'zgrep max_conn /etc/nginx/conf.d/*' |aht $STAGE @$SITENAME ssh --bal 2>/dev/null |grep $site | egrep --color '^|[1-5][0-9][0-9];$'
  ahtsep
}

# Get Varnish cached/uncached statistics
function test_varnish_stats() {
  days=5
  echo "Varnish cached/uncached statistics for last $days days:"
  ahtaht hosting:stats --start=-${days}days --end=now --csv | awk -F',' 'BEGIN { OFS=","; uncached_ratio_bad=0.075 } NR==1 { print $0 } (NR>1 && $4>0) { if (($5/$4) > uncached_ratio_bad) { $5 = "'$COLOR_RED'" $5 "'$COLOR_NONE'"; } print $0 } END { if (NR==1) { print "No_data.";   } }' |column -t -s','
  ahtsep
}

#PHP-CGI Check process limit settings
function test_phpcgi_procs() {
  echo "Checking PHP-CGI proc limits/status:"
  ahtaht php:list-cgi-procs -cgi --conf |grep -v defunct |awk '
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
      "ahtssh2 " server " free -m |egrep Mem" |getline;
      total_mem=$2;
      free_mem=$3;
      # Print the line
      print server " " max_overall "  " total_running " " max_docroot " " alert(docroot_running, docroot_running>=max_docroot) " " alert(free_mem, free_mem/total_mem <0.2) "MB " total_mem "MB";
    }' |column -t
  ahtsep
}

#PHP-FPM Check process limit settings
function test_phpfpm_procs() {
  echo "Checking PHP-FPM proc limits/status:"
  echo $webs |tr ' ' '\n' |awk '
    function alert(value, flag) {
      return value (flag ? "⚠warn!" : "");
    }
    BEGIN {
      user="'${site}'";
      dotless_sitename="'${site}'" ("'$env'" != "prod" ? "'$env'" : "")
      # Header
      print "Server MaxProcs-'$site$env' Active-'$site$env' FreeMem TotalMem"
    }
    # For each server
    {
      server=$0
      # Get max fpm processes config
      cmd = "grep pm.max_children /var/www/site-fpm/'$SITENAME'/pool.d/*conf |cut -f2 -d=";
      # Get memory info from server.
      cmd = cmd " && free -m |grep Mem"
      # Get number of processes running per docroot
      cmd = cmd " && ps -ef |grep -c [0-9].php-fpm:.pool." dotless_sitename;
      
      # Enclose the command into a remote SSH command
      cmd = "ssh -t -o StrictHostKeyChecking=no -o LogLevel=quiet -F $HOME/.ssh/ah_config " server " \"" cmd "\""
      #print cmd;
      cmd |getline max_docroot;
      cmd |getline
      total_mem=$2;
      free_mem=$4;
      cmd |getline docroot_running;
      close(cmd)

      # Print the line
      print server " " max_docroot " " alert(docroot_running, docroot_running>=max_docroot) " " alert(free_mem, free_mem/total_mem <0.2) "MB " total_mem "MB";
    }' |column -t
  echo ""
  ahtaht2 php:procs
  ahtsep
}

# PHP-CGI number of skip spawns
function test_phpcgi_skips() {
  ahtssh $web "sudo grep \"skip the spawn request\" /var/log/apache2/error.log |awk -F: '{ print substr(\$1,2) \":XX\" }' |sort |uniq -c" >$tmpout
  echo "Skip-spawns for today:"
  ahtcatnonempty $tmpout "${COLOR_GREEN}OK: No skip spawns found.${COLOR_NONE}" "${COLOR_RED}"
  ahtsep
}

#FPM number of skip spawns
function test_phpfpm_skips() {
  echo 'tail -5000 fpm-error.log | egrep "you may need to increase pm.start_servers|server reached max_children setting"' |ahtaht ssh logs |awk -F: '{ print $1 ":XX:XX" }' |sort |uniq -c  >$tmpout
  echo "Skip-spawns for today:"
  ahtcatnonempty $tmpout "${COLOR_GREEN}OK: No skip spawns found.${COLOR_NONE}" "${COLOR_RED}"
  ahtsep
}

#Check for any stuck outgoing connections
function test_external_connections() {
  echo "Checking for any open external connections from all webs:"
  for web in $webs
  do
    echo "= $web =============";
    ahtssh2 $web 'sudo lsof |awk "NR==1 || /^php.*TCP / { print }" | egrep -v ":mysql|:11211" |column -t' > $tmpout;
    if [ `grep -c . $tmpout` -gt 1 ]
    then
      awk '{ print "  " $0 }' $tmpout
    else
      echo "  ${COLOR_GREEN}None found.${COLOR_NONE}"
    fi
  done
  ahtsep
}

# Check for bad session.gc_ settings
function test_php_session_gc() {
  echo "Checking php.ini session.gc_* settings:"
  ahtaht php:ini-grep session.gc_ |egrep --color=always "^|overrides"
  ahtsep
}


#FPM number of errors
function test_phpfpm_errors() {
  echo "Checking count of SIGSEGV errors in fpm-error.log across all webs:"
  for web in $webs
  do
    echo -n "  $web: "
    domainless=`echo $web |cut -f1 -d.`
    ahtssh2 $web "sudo grep -c SIGSEGV /var/log/sites/${sitefoldername}/logs/${domainless}/fpm-error.log"
  done
  ahtsep
}

# Check DNS is pointing at Acquia.
function test_dns() {
  echo "Checking domains against DNS:"
  ahtaht domains:check |sort -k 3,3 |egrep --color=always "^|not pointing at Acquia|No DNS entry" >$tmpout
  ahtcatnonempty $tmpout "${COLOR_RED}No domains configured.${COLOR_NONE}"
  ahtsep
}

# Flag any important recent tasks.
function test_tasks() {
  days=5
  echo "Last $days days' workflow messages:"
  today=`date -u +'%Y-%m-%d|%Y-%m-%d %H'`
  ahtaht task:list --days=$days --limit=50 --all |egrep --color=always -i "^|db-migrate|purge-domain|save.site_config_setting|php.ini|code-push|Prod|commit|elevate code|reboot|$today" >$tmpout
  ahtcatnonempty $tmpout "${COLOR_GREEN}No messages found in last $days days."
  ahtsep
}

function test_block_cache() {
  echo "Checking for problematic block cache (modules not explicitly defining block caching):"
  aht $STAGE @$SITENAME $DRUSHCMD $URI ev 'echo "Module|Block-delta|Cache|Info\n"; $m = module_implements("block_info"); foreach ($m as $module) { $b = module_invoke($module, "block_info"); foreach ($b as $id=>$block) { echo "$module|$id|" . (empty($block["cache"])?"undefined":$block["cache"]) . "|" . $block["info"] . "\n"; } }' |column -s'|' -t
  ahtsep
}

function test_domain_sites_mapping() {
  echo "Showing domain -> site mapping:"
  if [ ${URI:-x} != x ]
  then
    # If a single domain given, use just that.
    echo " == Domain for $URI";
    ahtaht $DRUSHCMD st $URI | grep " path" | awk '{ print "  " $0 }';
  else
    ahtaht domains:list |tr -d '\015' | sed -e 's/\*/XXX/g' >$tmpout
    count=`grep -c . $tmpout`
    if [ $count -gt 15 ]
    then
      echo "${COLOR_YELLOW}  ** More than 15 domains found ($count); checking only first 15 **${COLOR_NONE}";
    fi
    # Cycle thru domains and check for session cookies.
    for domain in `head -15 $tmpout`
    do
      echo " == Domain: $domain";
      ahtaht $DRUSHCMD st --uri=$domain | grep " path" | awk '{ print "  " $0 }';
    done
  fi
  ahtsep
}

# Check for Pressflow
function test_pressflow() {
  echo "Checking for Pressflow/D7:"
  # Copy script to web
cat <<EOF >$tmpout
<?php
ini_set('display_errors', 0);
error_reporting(0);
list(\$v, ) = explode(".", VERSION);
if (\$v == 6) {
echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . " " . VERSION . "\n";
}
else {
echo "Drupal " . VERSION . "\n";
}
EOF
  dest=/tmp/testpressflow_$$.php
  echo "  Copying $tmpout to $web:$dest ..."
  rsync --archive -e "ssh -F $HOME/.ssh/ah_config -o StrictHostKeyChecking=no -o LogLevel=quiet" --rsync-path="/usr/bin/sudo /usr/bin/rsync" $tmpout $web:$dest

  ahtdrush scr $dest >$tmpout2 2>/dev/null
  if [ `grep -c "Drupal 6" $tmpout2` -gt 0 ]
  then
    echo "  ${COLOR_RED}: WARNING: D6 installed; No Pressflow:"
    ahtfiglet "No Pressflow!"
  else
    echo "  ${COLOR_GREEN}Drupal version OK:"
  fi
  cat $tmpout2 |awk '{ print "  " $0 }'
  ahtsep
}

# Check to see if there's a session cookie being set for anon users
function test_anonsession() {
  echo "Checking for anonymous user sessions:"
  problem=0
  if [ ${URI:-x} != x ]
  then
    # One domain only, put the domain into the list
    echo $URI |cut -f2 -d= >$tmpout
  else
    # Get valid domains (only those marked "OK" by aht domain-check + not-wildcarded)
    ahtaht domains:check |grep "ok" |fgrep -v '*' |awk '{ print $1 }' >$tmpout
  fi
  
  ## Add http:// to domains...
  cat $tmpout | awk '{ if (substr($0,1,4) != "http") { print "http://" $0; print "https://" $0; } else { print } }' >$tmpout2

  count=`grep -c . $tmpout`
  if [ $count -gt 15 ]
  then
    echo "${COLOR_YELLOW}  ** More than 15 domains found ($count); checking only first 15 **${COLOR_NONE}";
  fi
  # Cycle thru domains and check for session cookies.
  for domain in `head -15 $tmpout2`
  do
    #Get headers
    curl --max-time 5 $BASIC_AUTH_USERPASS -vv -o /dev/null $domain >$tmpout 2>&1
    if [ $? -gt 0 ]
    then
      echo "  ${COLOR_YELLOW}$domain: timeout!${COLOR_NONE}"
    else
      grep -e "^[<>]" $tmpout >$tmpout2
      #TODO: Check for failure: "Operation timed out" in output.... or... $? -gt 0
      # Check if there's a Set-Cookie: ... SESS  somewhere
      if [ `grep -c "< Set-Cookie: .*SESS" $tmpout2` -gt 0 ]
      then
        echo "  ${COLOR_RED}$domain: Anonymous SESS cookie found!!${COLOR_NONE}"
        problem=1
        # Try to get anon. sessions from the DB table
        echo "    * ${COLOR_RED}10 most recent sessions set in {sessions} table:"
        echo "SELECT uid,hostname,timestamp,FROM_UNIXTIME(timestamp),LEFT(session,80) FROM sessions WHERE uid = 0 ORDER BY timestamp DESC LIMIT 0,10;" |ahtaht $DRUSHCMD --uri=$domain sql-cli |awk '{ print "      " $0 }'
        echo "${COLOR_NONE}"
      else
        # Check for redirection
        grep ". Location:" $tmpout2 > $tmpout
        if [ `grep -c . $tmpout` -eq 1 ]
        then
          # Show redirect header
          echo "  ${COLOR_YELLOW}$domain ==> Redirect: "`cat $tmpout`
        else
          # No redirect nor SESS cookie, say things are OK.
          echo "  ${COLOR_GREEN}$domain: OK, no SESS cookie${COLOR_NONE}"
        fi
      fi
    fi
  done
  if [ $problem -eq 1 ]
  then
    echo "$COLOR_RED"
    ahtfiglet "Anonymous sessions found"
    echo "$COLOR_NONE"
  fi
  ahtsep
}

# Various tests around modules
function test_modules() {
  echo "Checking for any known problematic modules that are enabled:"
  # Get list of all enabled modules
  ahtdrush pml --type=module --status=enabled --pipe |sort >$tmpout

  # Check for offending modules
  for type in Incompatible Use-with-caution
  do
    if [ $type = "Incompatible" ]
    then
      # Incompatible modules
      modules="autoslave|backup_migrate|bean_entitycache|boost|cas|civicrm|db_maintenance|fbconnect|filecache|filter_harmonizer|fupload|hierarchical_select|imagefield_crop|ip_geoloc|mobile_tools|pubdlcnt|recaptcha|role_memory_limit|session_api|session_cache|serial|textsize|varnish"
      color="$COLOR_RED"
    else
      # Use-with-caution modules
      modules="adaptive_image|bean|cdn|contact_importer|context_show_regions|dblog|ds|elysia_cron|fivestar|honeypot|htmlpurifier|httprl|ldap|ligthbox2|linkchecker|menu_minipanels|migrate|multicron|performance|plupload|poormanscron|quicktabs|radioactivity|robotstxt|search404|statistics|supercron|taxonomy_menu|tcpdf|workbench_moderation|wurfl|wysiwig_ckfinder"
      color="$COLOR_YELLOW"
    fi
    echo "  $type modules found:${color}"
    egrep  "^($modules)$" $tmpout >$tmpout2 2>/dev/null
    if [ `grep -c . $tmpout2` -gt 0 ]
    then
      awk '{ print "    " $0 }' $tmpout2
      echo "$COLOR_NONE"
    else
      echo "    ${COLOR_GREEN}OK: None found.${COLOR_NONE}"
    fi
  done
  echo ""
  echo "  See per-module details here:"
  echo "    https://docs.acquia.com/articles/module-incompatibilities-acquia-cloud"
  echo "    https://docs.acquia.com/articles/module-list-acquia-cloud-caution"
  ahtsep

  # Check for how many modules enabled
  num=`grep -c . $tmpout`
  if [ $num -gt 200 ]
  then
    echo "Checking number of modules enabled:"
    echo "  ${COLOR_RED}WARNING: >200 modules enabled! ($num)"
    ahtfiglet $num' modules enabled!'
    echo "${COLOR_NONE}"
    ahtsep
  fi

  # Check for modules that need security updates
  echo "Checking for modules that need updates/security updates:"
  ahtdrush pm-updatestatus --format=table --fields=name,existing_version,candidate_version,status_msg >$tmpout 2>/dev/null
  ahtcatnonempty $tmpout "${COLOR_GREEN}OK: No modules need security updates.${COLOR_NONE}" "$COLOR_RED" |grep '^ ' |egrep --color "^|SECURITY UPDATE available|Installed version not supported"
  ahtsep
}

# Check caching settings
function test_cacheaudit() {
  echo "Cacheaudit of site:"
  echo ""
  ahtaht cacheaudit $URI >$tmpout 2>&1
  #awk '{ print "  " $0 }' $tmpout |grep -v "Disabled" |egrep --color=always '^|page_cache_maximum_age  *0| cache  *0|Enabled  *($|none)|DRUPAL_NO_CACHE'
  awk '
NR==1 { highlight=0 }
/page_cache_maximum_age  *0| cache  *0|Enabled  *($|none)|DRUPAL_NO_CACHE/ {
  highlight=1
}
## Just pipe the first portion of the cacheaudit output (first 10 lines)
NR<=10 {
  print "  " $0;
}
/Enabled/ {
  print (highlight ? "'$COLOR_RED'" : "") "  " $0 (highlight ? "'$COLOR_NONE'" : "");
  highlight=0;
}' $tmpout
  ahtsep
}

# Check DB size
function test_dbsize() {
  echo "Showing DB data use:"
  cat <<EOF |ahtdrush sql-cli |column -t |awk '{ print "  " $0 }'
SELECT IFNULL(B.engine,'Total') "Storage Engine",
CONCAT(LPAD(REPLACE(FORMAT(B.DSize/POWER(1024,pw),3),',',''),17,' '),' ',
SUBSTR(' KMGTP',pw+1,1),'B') "Data Size", CONCAT(LPAD(REPLACE(
FORMAT(B.ISize/POWER(1024,pw),3),',',''),17,' '),' ',
SUBSTR(' KMGTP',pw+1,1),'B') "Index Size", CONCAT(LPAD(REPLACE(
FORMAT(B.TSize/POWER(1024,pw),3),',',''),17,' '),' ',
SUBSTR(' KMGTP',pw+1,1),'B') "Table Size" FROM
(SELECT engine,SUM(data_length) DSize,SUM(index_length) ISize,
SUM(data_length+index_length) TSize FROM
information_schema.tables WHERE table_schema NOT IN
('mysql','information_schema','performance_schema') AND
engine IS NOT NULL GROUP BY engine WITH ROLLUP) B,
(SELECT 3 pw) A ORDER BY TSize;
EOF
  ahtsep

  echo "Showing largest database tables:"
  ahtaht db:size --num-tables=10 |egrep --color=always '^| [1-9][0-9][0-9][0-9]*\.[0-9][0-9] MB|\| [0-9]{4,20} \|'
  ahtsep

  # Cache_form entries...
  echo "Showing largest cache_form entries from database:"
  if [ `egrep -c '\.cache_form *[1-9]' $tmpout` -gt 0 ]
  then
    echo "  ${COLOR_YELOW}Skipping cache_form table report, because table has >1M items.${COLOR_NONE}";
  else
    cat <<EOF |ahtdrush sql-cli |column -t |awk '{ print "  " $0 }' |egrep --color=always '^.*'
SELECT concat(length(data)/1048576, "MB") AS Size, cid FROM cache_form WHERE length(data) > 1048576 ORDER BY Size desc LIMIT 5;
EOF
  fi
  ahtsep
}

function test_ahtaudit() {
  echo "Problems found from basic site audit:"
  ahtaht audit $URI >$tmpout
  if [ `grep -c "Drush was not able to start" $tmpout` -gt 0 ]
  then
    echo "  ${COLOR_RED}ERROR: Drush not bootstrapping!${COLOR_NONE}"
    echo "You may want to try with a --uri argument using a valid URI."
    echo "Here are the sites on the docroot:"
    ahtaht application:sites | awk '{ print "  " $0}'
    drushworks_flag=0
  else
    drushworks_flag=1
    echo $COLOR_YELLOW
    cat $tmpout |grep '\[error\]' |tr -d '\015' |sed 's:\x1B\[[0-9;]*[mK]::g' |sed 's/\[error\]//g' |sed 's/[ \t]*$//' |awk '{ print "  " $0 }'
    echo "$COLOR_NONE"
    echo "* See canned suggestions at:
  https://support.acquia.com/doc/index.php/Performance_AHT_AUDIT_advise"
  fi
  ahtsep
}

function test_db_update_status() {
  echo "Checking for pending DB updates:${COLOR_RED}"
  ahtdrush updbst
  ahtsep
}

# Check for duplicate module files
function test_duplicatemodules() {
  # Get the really-real enabled projects first:
  # TODO: doesn't work with table prefixes yet.
  echo "SELECT filename FROM system WHERE type IN ('module', 'theme', 'profile') AND status='enabled'" | ahtdrush sql-cli |sed -e 's/\.module/.info/g' -e 's/\.theme/.info/g' >$tmpout2
  # Now show all duplicates. showing which one (if any) is really enabled.
  echo "Check for duplicate modules/themes:"
  prefix=""
  if [ $LIVEDEV_FLAG -eq 1 ]
  then
    prefix="docroot/"
  fi
  echo 'find '$prefix'modules '$prefix'themes '$prefix'sites '$prefix'profiles -name "*.info" -type f | grep -oe "[^/]*\.info" | sort | uniq -d | egrep -v "drupal_system_listing_(in|)compatible_test" | xargs -I{} find . -name "{}" |cut -f2- -d/' |ahtaht ssh html >$tmpout
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
  echo "SELECT count(1) as Num_of_Variables, max(length(value)) as Maximum_variable_size, sum(length(value)) as Combined_variables_size FROM variable\\G" |ahtdrush sql-cli | sed -n '2,$p' >$tmpout
  egrep --color=always "^|Num_of_Variables: [0-9][0-9][0-9][0-9][0-9]*|Maximum_variable_size: [0-9][0-9][0-9][0-9][0-9][0-9]*|Combined_variables_size: [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*" $tmpout
  ahtsep
}

# Get last times for cache flushes
function test_cacheflushes() {
  echo "Getting times of latest cache flushes in Drupal:"
  ahtdrush vget cache_flush > $tmpout
  if [ `grep -c 'No matching variable found.' $tmpout` -eq 1 ]
  then
    echo "  Couldn't find cache_flush variable."
  else
    which gawk >/dev/null
    if [ $? -eq 0 ]
    then
      cat $tmpout | sort -k2n |tr -d '\015' |awk -F ':' '{ print $1 "\t" $2 "\t" strftime("%a %b %e %H:%M:%S %Z %Y", $2) " (=" systime()-$2 " seconds ago)"; }' |column -s $'\t' -t >$tmpout2
      today=`date +'%h %_d|%h %_d %H'`
      egrep --color=always "^|${today}|.*=[1-9](.|..|...) seconds ago" $tmpout2
    else
      cat $tmpout | sort -k2n | xargs -I{} sh -c 'echo -n "{} : " ; date -d "@$(echo {} | awk '\''{ print $2 }'\'')"' |sed -e 's/: /|/g' | column -t -s'|' | sed -e 's/^/  /' >$tmpout2
      today=`date +'%h %_d|%h %_d %H'`
      egrep --color=always "^|${today}" $tmpout2
    fi
  fi
  ahtsep
}

function test_phpla() {
  echo "Looking at PHP queue (Q-time) and execution (P-time) times:"
  ahtaht2 log-analysis --type=drupal-requests --by=ten-min
  ahtsep
}

# Run ahtaudit script on access.log
function test_logs() {
  logfilename=access.log
  echo "Looking for and analyzing $logfilename..."
  scriptname=$SCRIPT_FOLDER/aht-log-report.sh
  if [ ! -r $scriptname ]
  then
    echo "  ${COLOR_YELLOW}Could not find $scriptname!"
    echo "  Check that it exists and try again.${COLOR_NONE}"
    ahtsep
    return
  fi
  tmpscript=/mnt/tmp/ahtaudit_script.$$.bash
  findlog=`ahtfindlog $logfilename breakonfirst`
  if [ "${findlog:-x}" != x ]
  then
    server=`echo $findlog |cut -f1 -d:`
    logfile=`echo $findlog |cut -f2 -d:`
    logfiledir=`dirname $logfile`
    echo "  $logfile is in $server."
    rsync --archive -e "ssh -F $HOME/.ssh/ah_config -o StrictHostKeyChecking=no -o LogLevel=quiet" --rsync-path="/usr/bin/sudo /usr/bin/rsync" $scriptname $server:$tmpscript
    ahtsep
    echo "sudo bash $tmpscript $logfiledir $sitefoldername" | ahtssh $server
  else
    echo "  ${COLOR_YELLOW}No $logfilename found!${COLOR_NONE}"
    echo ""
    ahtsep
  fi
}

# Run ahtaudit script on drupal-watchdog.log
function test_drupalwatchdog() {
  logfilename=drupal-watchdog.log
  echo "Looking for and analyzing $logfilename..."
  scriptname=$SCRIPT_FOLDER/aht-drupal-requests-report.sh
  if [ ! -r $scriptname ]
  then
    echo "  ${COLOR_YELLOW}Could not find $scriptname!"
    echo "  Check that it exists and try again.${COLOR_NONE}"
    ahtsep
    return
  fi
  tmpscript=/mnt/tmp/ahtaudit_script.$$.bash
  findlog=`ahtfindlog $logfilename breakonfirst`
  if [ ${findlog:-x} != x ]
  then
    server=`echo $findlog |cut -f1 -d:`
    logfile=`echo $findlog |cut -f2 -d:`
    echo "  $logfile is in $server."
    rsync --archive -e "ssh -F $HOME/.ssh/ah_config -o StrictHostKeyChecking=no -o LogLevel=quiet" --rsync-path="/usr/bin/sudo /usr/bin/rsync" $scriptname $server:$tmpscript
    ahtsep
    echo "sudo bash $tmpscript $logfile" | ahtssh $server
  else
    echo "  ${COLOR_YELLOW}No $logfilename found!${COLOR_NONE}"
    echo ""
    ahtsep
  fi
}
