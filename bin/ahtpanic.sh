#
# ahtpanic.sh
#
# HUGE sniff-out-everything script that uncovers a lot of potential problems.
# Run without arguments for help.
#
# TODOS:
# * Check that settings.php use $_ENV instead of $_SERVER for AH_ variables
#   (so that they work with drush too)

# Constants
# Folder where this and other supporting scripts are installed
HELPER_SCRIPTS_PATH="."
# See http://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/
COLOR_RED=$(tput setaf 1) #"\[\033[0;31m\]"
COLOR_YELLOW=$(tput setaf 3) #"\[\033[0;33m\]"
COLOR_GREEN=$(tput setaf 2) #"\[\033[0;32m\]"
COLOR_GRAY=$(tput setaf 7) #"\[\033[2;37m\]"
COLOR_NONE=$(tput sgr0) #"\[\033[0m\]"
# Environment for aht runs
STAGE=''
SITENAME=''
URI=''
# Flags for what test sets should be run
BASICCHECK_FLAG=1
DRUSH_FLAG=1
LOGS_FLAG=1

function showhelp() {
  cat <<EOF
This is a sniff-out-everything script that uncovers a lot of potential problems.
Note: you should give it a --uri argument if auditing a multisite install.
Usage: 
  $0 [--uri=URI] [--mc|--dc] [--skip-(basic|drush|logs)] 
     [--user=BASICAUTHUSER:BASICAUTHPASSWORD]
     @sitename.env
  
Examples:
  $0 --skip-basic @eluniverso.prod  # Skips some basic checks
  $0 --uri=www.eluniverso.com @eluniverso.prod  # Give it a URI for drush
  $0 --mc @eluniverso.prod  # Forces managed cloud, use --dc for devcloud
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
    --user=*)
      BASIC_AUTH_USERPASS=$1
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
    --ac)
      STAGE=$1
      ;;
    --ace)
      STAGE=$1
      ;;
    --stages=*)
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
    --skip-logs)
      LOGS_FLAG=0
      ;;
    --skiplogs)
      LOGS_FLAG=0
      ;;
    --*)
      # error unknown (long) option $1
      echo "${COLOR_RED}Unknown option $1${COLOR_NONE}"
      ;;
    -?)
      # error unknown (short) option $1
      echo "${COLOR_RED}Unknown option $1${COLOR_NONE}"
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
    @*)
      SITENAME=$1
      ;;
  esac

  shift
done

if [ ${SITENAME:-x} = x ]
then
  showhelp
  exit 1
fi

cat <<EOF
Running with these options:
  Sitename: $SITENAME
     Stage: $STAGE
       URI: $URI
BASICCHECK_FLAG: $BASICCHECK_FLAG
     DRUSH_FLAG: $DRUSH_FLAG
      LOGS_FLAG: $LOGS_FLAG

Color key:
   ${COLOR_GREEN}GREEN: OK
  ${COLOR_YELLOW}YELLOW: Warning
     ${COLOR_RED}RED: Potentially bad or error!${COLOR_NONE}
EOF
ahtsep

# Set some vars
tmpout=/tmp/tmp.$$
tmpout2=/tmp/tmp.$$.2

# Trim @ from sitename
SITENAME=`echo $SITENAME |cut -c2-`
  
# split site/env
site=`echo $SITENAME |cut -f1 -d'.'`
env=`echo $SITENAME |cut -f2 -d'.'`
  
# Dump aht --inet output, highlight load avgs >= 1.00 AND c1.mediums
ahtaht --load |egrep --color=always '^| [1-9]\.[0-9][0-9](,|$)| [1-9][0-9]\.[0-9][0-9](,|$)|c1.medium' | tee $tmpout
ahtsep
# Detect FPM from the aht output.
if [ `grep -c -- "-fpm" $tmpout` -gt 0 ]
then
  FPM_FLAG=1
else
  FPM_FLAG=0
fi
# Get the webs
webs=`egrep "srv-|web-|ded-|staging-" $tmpout |grep -v ' \*' |cut -f2 -d' '`
webs_raw=`egrep "srv-|web-|ded-|staging-" $tmpout |cut -f2 -d' '`
# Get firstweb
web=`ahtfirstweb $SITENAME`
# devcloud/not devcloud
devcloud=`echo $web |grep -c srv-`
# livedev/not livedev
# Detect FPM from the aht output.
LIVEDEV_FLAG=`grep -c -- "LIVEDEV" $tmpout`
# Detect all dedicated balancers
#dedicated_bals=`cat $tmpout |egrep 'bal-[0-9]+ *dedicated *[1-9]' |awk '{ print $1 }'`

# DEBUG STUFF HERE!
#test_puppet_log_check
#exit


# Run basic checks
if [ $BASICCHECK_FLAG = 1 ]
then
  test_show_panic_links
  if [ $devcloud -eq 0 ]
  then
    test_code_deploy
  fi
  test_nagios_info
  
  # Add graphs to balancers if dedicated
  #if [ "${dedicated_bals:-x}" != x -a 1 -eq 2 ]   #DISABLED!!
  #then
  #  test_balancer_graphs
  #fi
  
  test_php_memory_limit
  test_puppet_log_check
  test_hosting_release_version

  # Check process limit settings, number of skip spawns
  # Is site running php-cgi or FPM?
  if [ $FPM_FLAG -eq 0 ]
  then
    test_phpcgi_procs
    test_phpcgi_skips
  else
    test_phpfpm_procs
    test_phpfpm_skips
    test_phpfpm_errors
  fi
  test_external_connections
  test_dns
  test_varnish_stats
  test_tasks
  test_email_volume
  test_anonsession
fi

# Run Drush-based checks
if [ $DRUSH_FLAG -eq 1 ]
then
  test_ahtaudit
  
  # Run some more checks, but only if drush works.
  if [ $drushworks_flag -eq 1 ]
  then
    test_domain_sites_mapping
    test_pressflow
    test_modules
    test_cacheaudit
    test_block_cache
    test_duplicatemodules
    test_vars
    test_cacheflushes
    test_dbsize
  fi
fi

# Run Drush-based checks
if [ $LOGS_FLAG -eq 1 ]
then
  test_logs
  test_drupalwatchdog
fi

# Finish & cleanup.
rm $tmpout $tmpout2 2>/dev/null
