#!/bin/bash
#
# Run this script within the folder where drupal-requests.log is located
topcount=5     #Number of lines per report
portion=200000 #Latest # of lines to process in log, when log is too large
slowtime=5     #Slow request time in secs.
days=5         #Days back to report for some reports.

tmpout=/tmp/ahtlogreport.$$.tmp
tmpout2=/tmp/ahtlogreport.$$.drupal-watchdog.tmp

# See http://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/
TERM=xterm-color
COLOR_RED=$(tput setaf 1) #"\[\033[0;31m\]"
COLOR_YELLOW=$(tput setaf 5) #"\[\033[0;33m\]"
COLOR_GREEN=$(tput setaf 2) #"\[\033[0;32m\]"
COLOR_GRAY=$(tput setaf 7) #"\[\033[2;37m\]"
COLOR_NONE=$(tput sgr0) #"\[\033[0m\]"

# Just a separator. Nothing to see here
function ahtsep() {
  echo ""
  echo "${COLOR_GRAY}-----------------------------------${COLOR_NONE}"
}
# Count stuff, and report the top $topcount items.
function ahtcounttop() {
  sort |uniq -c |sort -nr |head -$topcount
}
# Output a table, header optional (as first argument).
# Columns are space-separated.
function ahttable() {
  if [ "${1:-x}" != x ]
  then
    echo $1 >$tmpout
    sed 's/^\s\+//' >>$tmpout
    column -t $tmpout
  else
    sed 's/^\s\+//' |column -t
  fi
}

# Passthru (cat) files smaller than 5MB;
# when larger, only pass thru the last $portion lines.
function ahtcat() {
  size=`stat $1 --format=%s`
  if [ $size -lt 5242880 ]
  then
    cat $1
  else
    tail -$portion $1
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

################################
# START
################################

if [ "${1:-x}" = x ]
then
  echo "Usage: $0 path/to/drupal-watchdog.log"
  echo
  exit
fi

logfilename=$1
if [ ! -r $logfilename ]
then
  echo "${COLOR_YELLOW}WARNING: No $logfilename available!${COLOR_NONE}"
  ahtsep
else
  # If format is '; '-separated instead of |-separated, make a derivative file.
  # NOTE: This other format needs reordering of the fields too!
  if [ `head -20 $logfilename |awk -F'; ' 'NR==1 {n=0} { if (NR>n) n=NF; } END { print n }'` -gt 5 ]
  then
    echo "${COLOR_YELLOW}Found ;-separated drupal-watchdog.log format.${COLOR_NONE}"
    awk -F'; ' '{
      split($1, tmp, ":");
      time_ip_sitegroup=tmp[1] ":" tmp[2] ":" tmp[3];
      msg=substr(tmp[4],2);
      siteurl=$2
      timestamp=$3
      type=$4
      ip=$5
      url=$6
      userid=$8
      # Output the reorganized log line
      printf("%s: %s|%s|%s|%s", time_ip_sitegroup, siteurl, timestamp, type, ip)
      printf("|%s||%s||%s\n", url, userid, msg)
    }' $logfilename >$tmpout2
    # Now use this other file for the rest of the script!
    logfilename=$tmpout2
  fi

  echo "Count of top Drupal-watchdog messages by type on $logfilename:"
  ahtcat $logfilename |cut -f3 -d"|"  |ahtcounttop >$tmpout
  cat $tmpout |egrep --color=always "^|^  *[1-9][0-9][0-9][0-9][0-9][0-9]* .*"
  ahtsep

  #Find top 2 message types (but omit 'search' and 'page not found' types), report on them using a loop
  msgs=`grep -v -e '^(search|page not found)$' $tmpout |head -2 |sed 's/^\s\+//' |cut -f2- -d' ' |tr ' ' '*'`
  for msg in $msgs
  do
    msg=`echo $msg |tr '*' ' '`
    echo "Count of top '$msg' messages on $logfilename:"
    ahtcat $logfilename |awk -F '|' '$3=="'"$msg"'" { print $9 }' |sed -e 's/ request_id="[^"]*"//' |ahtcounttop |egrep --color=always "^|^  *[1-9][0-9][0-9][0-9][0-9]*" |egrep --color=always -i "^|exception|error"
    ahtsep
  done

  echo "Count of top paths bootstrapping Drupal for 'page not found' response on $logfilename:"
  ahtcat $logfilename |awk -F '|' '$3=="page not found" { print $5 }' |ahtcounttop |egrep --color=always "^|^  *[1-9][0-9][0-9][0-9][0-9]* .*"
  ahtsep

  echo "Recent cron runs from $logfilename:"
  ahtcat $logfilename |awk -F '|' '$3=="cron" { print $1 "|" $9 }' |sed -e 's/ request_id="[^"]*"//' |tail -10 |egrep -i --color=always "^|exception" >$tmpout
  ahtcatnonempty $tmpout "${COLOR_RED}No cron runs found.${COLOR_NONE}"
  ahtsep

  echo "Modules enabled/disabled from last ${days} days on $logfilename:"
  logfiles=`ls -tr $logfilename*.gz $logfilename 2>/dev/null|tail -${days}`
  today_date=`date +'%h %d '`
  cat /dev/null >$tmpout
  for file in $logfiles
  do
    zgrep -e 'module .*abled' $file| cut -f1,9 -d'|' |sed -e 's/ request_id="[^"]*"//' |egrep -i --color=always "^|${today_date}|(dblog|statistics) module enabled|" >>$tmpout
  done
  ahtcatnonempty $tmpout "${COLOR_GREEN}No modules enabled/disabled in last 5 days.${COLOR_NONE}"
  ahtsep

  # Remove temp files.
  rm $tmpout $tmpout2 2>/dev/null
fi
