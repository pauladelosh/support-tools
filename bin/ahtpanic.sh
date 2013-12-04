#!/bin/bash
#
# ahtpanic.sh
#
# HUGE sniff-out-everything script that uncovers a lot of potential problems.
# Run without arguments for help.
#
# TODOS:
# * Check that settings.php use $_ENV instead of $_SERVER for AH_ variables
#   (so that they work with drush too)
# * Get fpm settings.

# Constants
# Folder where this script is installed
HELPER_SCRIPTS_PATH="."
# See http://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/
COLOR_RED=$(tput setaf 1) #"\[\033[0;31m\]"
COLOR_YELLOW=$(tput setaf 5) #"\[\033[0;33m\]"
COLOR_GREEN=$(tput setaf 2) #"\[\033[0;32m\]"
COLOR_GRAY=$(tput setaf 7) #"\[\033[2;37m\]"
COLOR_NONE=$(tput sgr0) #"\[\033[0m\]"
STAGE=''
SITENAME=''
URI=''
BASICCHECK_FLAG=1
DRUSH_FLAG=1

function showhelp() {
  cat <<EOF
This is a sniff-out-everything script that uncovers a lot of potential problems.
Note: you should give it a --uri argument if auditing a multisite install.
Usage: $0 sitename.env
      $0 --skipbasic eluniverso.prod  # Skips some basic checks and goes directly to the good stuff.
      $0 --uri=www.eluniverso.com eluniverso.prod  # Give it a URI for drush
      $0 --mc eluniverso.prod  # Forces managed cloud, use --dc for devcloud
EOF
}

####################################################
# START
####################################################

# Basic checks
# Check for aht command
which aht >/dev/null 2>&1
if [ $? -gt 0 ]
then
  echo "${COLOR_RED}aht command not found!"
  ahtsep
  exit
fi
#Check the functions exist
if [ ! -r "$HELPER_SCRIPTS_PATH/lib/ahtpanic-functions.sh" ]
then
  echo "${COLOR_YELLOW}WARNING! Could not find lib/ahtpanic-functions.sh at $HELPER_SCRIPTS_PATH"
  echo "Make sure the HELPER_SCRIPTS_PATH is set correctly."
  ahtsep
fi
# Include helper functions
. $HELPER_SCRIPTS_PATH/lib/ahtpanic-functions.sh

# Show help on empty call.
if [ "${1:-x}" = x ]
then
  showhelp
  exit
fi

# Get options 
# http://stackoverflow.com/questions/402377/using-getopts-in-bash-shell-script-to-get-long-and-short-command-line-options/7680682#7680682
while test $# -gt 0
do
  case $1 in

  # Normal option processing
    -h | --help)
      # usage and help
      showhelp
      exit
      ;;
    -v | --version)
      # version info
      ;;
  # ...

  # Special cases
    --)
      break
      ;;
    --uri=*)
      URI=$1
      ;;
    --mc)
      STAGE=$1
      ;;
    --dc)
      STAGE=$1
      ;;
    --skipbasic)
      BASICCHECK_FLAG=0
      ;;
    --skip-basic)
      BASICCHECK_FLAG=0
      ;;
    --skip-drush)
      DRUSH_FLAG=0
      ;;
    --skipdrush)
      DRUSH_FLAG=0
      ;;
    --*)
      # error unknown (long) option $1
      echo "Unknown option $1"
      ;;
    -?)
      # error unknown (short) option $1
      echo "Unknown option $1"
      ;;

  # FUN STUFF HERE:
  # Split apart combined short options
  #  -*)
  #    split=$1
  #    shift
  #    set -- $(echo "$split" | cut -c 2- | sed 's/./-& /g') "$@"
  #    continue
  #    ;;

  # Done with options, the sitename comes last.
    *)
      SITENAME=$1
      break
      ;;
  esac

  shift
done

echo "Running with these options:"
echo "  Sitename: $SITENAME"
echo "     Stage: $STAGE"
echo "       URI: $URI"
ahtsep

# Set some vars
tmpout=/tmp/tmp.$$
tmpout2=/tmp/tmp.$$.2
  
# Get firstweb
web=`ahtfirstweb $SITENAME`
# devcloud/not devcloud
devcloud=`echo $web |grep -c srv-`
# split site/env
site=`echo $SITENAME |cut -f1 -d'.'`
env=`echo $SITENAME |cut -f2 -d'.'`
  
# Dump aht --inet output, highlight load avgs >= 1.00
ahtaht --load |egrep --color=always '^| [1-9]\.[0-9][0-9](,|$)| [1-9][0-9]\.[0-9][0-9](,|$)' | tee $tmpout
ahtsep
# Detect FPM from the aht output.
if [ `grep -c -- "-fpm" $tmpout` -eq 1 ]
then
  FPM_FLAG=1
else
  FPM_FLAG=0
fi
# Detect all dedicated balancers
#dedicated_bals=`cat $tmpout |egrep 'bal-[0-9]+ *dedicated *[1-9]' |awk '{ print $1 }'`
  
if [ $BASICCHECK_FLAG = 1 ]
then
  test_nagios_info
  
  # Add graphs to balancers if dedicated
  #if [ "${dedicated_bals:-x}" != x -a 1 -eq 2 ]   #DISABLED!!
  #then
  #  test_balancer_graphs
  #fi
  
  test_php_memory_limit

  # Check process limit settings, number of skip spawns
  # Is site running php-cgi or FPM?
  if [ $FPM_FLAG -eq 0 ]
  then
    test_phpcgi_procs
    test_phpcgi_skips
  else
    test_phpfpm_skips
  fi
  test_dns
  test_varnish_stats
  test_tasks
fi

if [ $DRUSH_FLAG -eq 1 ]
then
  test_ahtaudit
  
  # Run some more checks, but only if drush works.
  if [ $drushworks_flag -eq 1 ]
  then
    test_pressflow
    test_modules
    test_cacheaudit
    test_dbsize
  fi
fi

test_duplicatemodules
test_vars
test_logs
test_drupalwatchdog

# Finish & cleanup.
rm $tmpout $tmpout2

