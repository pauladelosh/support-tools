#!/bin/bash
#
# Run this script within the folder where access.log, drupal-requests.log
# and php-errors.log are located

# TODO: SEE tickets...
#  15066-73369 
#  15066-73398
# for some canned responses to go along with
# the output below.
topcount=5     #Number of lines per 'top' report
portion=200000 #Latest # of lines to process in log, when log is too large
slowtime=5     #Slow request time in secs.
days=5         #Days back to report for some reports.

tmpout=/tmp/ahtlogreport.$$.tmp
tmpout2=/tmp/ahtlogreport2.$$.tmp
hostname=`hostname -s`

# See http://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/
TERM=xterm-color
COLOR_RED=$(tput setaf 1) #"\[\033[0;31m\]"
COLOR_YELLOW=$(tput setaf 3) #"\[\033[0;33m\]"
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
  sort |uniq -c |sort -nr |head -$topcount >$tmpout2
  if [ `grep -c . $tmpout2` -eq 0 ]
  then
    echo "  ${COLOR_GRAY}No data to report.${COLOR_NONE}"
  else
    cat $tmpout2
  fi
}
# Output a table, header optional (as first argument).
# Columns are space-separated.
function ahttable() {
  if [ "${1:-x}" != x ]
  then
    printf $1"\n" >$tmpout
    cat >>$tmpout
    column -s$'\t' -t $tmpout
  else
    column -s$'\t' -t
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

echo "Check for low disk space on $hostname:"
df -k |tr -s ' ' |grep "/dev/sd" |awk -F' ' '
{
  if ($4 < 10240) {
    prob[$1]= $0;
    errors=1;
  }
}
END {
  if (errors) {
    print "Filesystem 1K-blocks Used Available Use% Mounted-on"
    for (i in prob) {
      $0 = prob[i];
      $4 = sprintf("%1.2fM", $4/1024);
      print $0 " '$COLOR_RED'**WARNING**'$COLOR_NONE'";
    }
  }
  else {
    print "  '$COLOR_GREEN'OK! All filesystems have >10M free'$COLOR_NONE'" >"/dev/stderr"
  }
}' |ahttable
ahtsep

echo "Total byte sizes for logs on $hostname:"
stat *.log --format="%s %n" | sort -nr |awk '{ printf("%.1fM\t%s\n",$1/1024/1024, $2 ($1+0 > 10000000 ? " '$COLOR_YELLOW'**WARNING**'$COLOR_NONE'" : "")) }' |ahttable "Size\tFilename"
ahtsep

sitename=$1
slowout=/tmp/slow.$$.txt
cat /dev/null >$slowout
echo "Per-hour requests and slow requests for $sitename on $hostname: (Note: Times are GMT+0)"
ahtcat access.log |awk -F ' ' '
NR==1 { 
  slowtime='$slowtime';
}
/hosting_site='$sitename' / { 
  pos=index($0, "request_time=");
  if (pos>0) { 
    dur=substr($0, pos + 13)/1000000; 
    time=substr($4, 2, 14)":XX";
    times[time]=time; 
    numtot[time]++; 
    durtot[time]+=dur; 
    if (dur>slowtime) { 
      slow[time]++; 
      print >>"'$slowout'"
    }
    max[time] = (max[time] < dur) ? dur : max[time];
    stat=substr($9,1,1) "XX"
    stats[time stat]++
  }
} 
END {
  print "Date/Time\t#Reqs\tAvg(s)\tMax(s)\t#>" slowtime "s\tHTTP:2XX\t3XX\t4XX\t5XX";
  for (t in times) {
    printf ("%s\t%d\t%.2f\t%.2f\t%d", t, numtot[t], durtot[t]/numtot[t], max[t],
      (slow[t]/numtot[t] > 0.05 ? "'${COLOR_RED}'" : "") slow[t] "'${COLOR_NONE}'");
    # Print count per status
    printf ("\t%d\t%d\t%s%d'"${COLOR_NONE}"'\t%s%d'"${COLOR_NONE}"'\n",
      stats[t "2XX"],
      stats[t "3XX"],
      # Determine color
      (stats[t "4XX"]/numtot[t]) > 0.05 ? "'${COLOR_RED}'" : "",
      stats[t "4XX"],
      (stats[t "5XX"]) > 0 ? "'${COLOR_RED}'" : "", 
      stats[t "5XX"])
  }
}' |sort -n |ahttable
ahtsep

if [ -r $slowout ]
then
  echo "Count of top slow HTTP requests on $hostname:"
  cat $slowout |awk -F' ' '
  {
    req=substr($6,2) "\t" $7
    dur=substr($0, index($0, "request_time=") + 13)/1000000;
    if (dur>max[req]) { max[req] = dur }
    cnt[req]++
    reqs[req]=req
    tot[req]+=dur
  }
  END {
    for (r in reqs) {
      if (cnt[r] > 0) {
        printf("%d\t%.2f\t%.2f\t%s\n", cnt[r], max[r], tot[r]/cnt[r], r);
      }
    }
  }' | sort -nr |head -10 | ahttable "Count\tMax(s)\tAvg(s)\tMethod\tURL"
  ahtsep
fi

echo "Count of top paths that caused a 5XX error on $hostname:"
echo "${COLOR_NONE}Today:${COLOR_RED}"
ahtcat access.log |awk -F' ' 'substr($9,1,2) == "50" { print $7 }' |ahtcounttop
echo ""
echo "${COLOR_NONE}Per hour:${COLOR_RED}"
ahtcat access.log |awk -F' ' 'substr($9,1,2) == "50" { print substr($4,2,15) "|" substr($7,1,40) }' |ahtcounttop
ahtsep

echo "Count of hits with 'page=...' arguments like Views, etc. by User-agent on $hostname:"
ahtcat access.log |egrep 'page=[1-9]' | cut -f6 -d'"' |ahtcounttop
ahtsep

#echo "Count of top image requests unnecessarily bootstrapping Drupal:"
#ahtcat drupal-requests.log |egrep "\.(jpg|png|gif|jpeg|ico) query=" |egrep -v "styles/|imagecache/" |cut -f5 -d' ' |ahtcounttop
#ahtsep

echo "Latest cron calls in access.log on $hostname:"
ahtcat access.log |fgrep "GET /cron.php" |tail -$topcount >$tmpout2
ahtcatnonempty $tmpout2 "${COLOR_GREEN}No calls to cron.php via HTTP request found (Good!)" "${COLOR_RED}"
ahtsep

echo "Count of top error messages in php-errors.log on $hostname:"
cut -f2- -d']' php-errors.log |ahtcounttop |egrep --color=always "^|PHP Fatal error"
#ahtcatnonempty $tmpout "${COLOR_GREEN}No errors found." "${COLOR_RED}"
ahtsep

# Cleanup
rm $tmpout $slowout 2>/dev/null
