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

# Get the path to this script
SCRIPT_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_FOLDER

# Constants
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
SINGLECHECK=0
VERBOSE=0
DRUSHCMD='drush7'

function showhelp() {
  local cmd=$(basename $0)
  cat <<EOF
This is a sniff-out-everything script that uncovers a lot of potential problems.
Note: you should give it a --uri argument if auditing a multisite install.
Usage:
  $cmd [--uri=URI] [--mc|--dc|--ace] [--skip-(basic|drush|logs)]
     [--user=BASICAUTHUSER:BASICAUTHPASSWORD]
     [--stages=(ace|prod|ac|devcloud|network|smb|acsf|wmg|umg|all)]
     @sitename.env
     [--only=COMMAND]

Examples:
  $cmd --skip-basic @mysite.prod  # Skips some basic checks
  $cmd --uri=www.mysite.com @mysite.prod  # Give it a URI for drush
  $cmd --mc @mysite.prod  # Forces managed cloud, use --dc for devcloud

Run single commands: (run with --only=COMMAND or --command=COMMAND)
  Available commands:
EOF
  grep -o "function test_[^ ]*" ../lib/ahtpanic-functions.sh |cut -f2- -d_ |cut -f1 -d'(' |sort |awk '{ printf("  %s",$0) } END { printf "\n" }'
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
if [ ! -r "../lib/ahtpanic-functions.sh" ]
then
  echo "${COLOR_YELLOW}WARNING! Could not find ahtpanic-functions.sh"
  echo "Make sure the script has been set correctly."
  ahtsep
fi
# Include helper functions
. ../lib/ahtpanic-functions.sh

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
    -v | --verbose)
      VERBOSE=1
      ;;
  # ...

  # Special cases
    --)
      break
      ;;
    --d8)
      DRUSHCMD="drush8"
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
    --only=*)
      SINGLECHECK=`echo $1 |cut -f2- -d=`
      ;;
    --command=*)
      SINGLECHECK=`echo $1 |cut -f2- -d=`
      ;;
    --verbose)
      VERBOSE=1
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

  # Split apart combined short options
  #  -*)
  #    split=$1
  #    shift
  #    set -- $(echo "$split" | cut -c 2- | sed 's/./-& /g') "$@"
  #    continue
  #    ;;

  # Done with options
    @*)
      SITENAME=$1
      ;;
    http*)
      URI="--uri=$1"
      ;;
    www*)
      URI="--uri=$1"
      ;;
  esac

  shift
done

# Set some vars
tmpout=/tmp/tmp.$$
tmpout2=/tmp/tmp.$$.2

if [ ${SITENAME:-x} = x ]
then
  if [ ${URI:-x} = x ]
  then
    showhelp
    exit 1
  else
    uri=`echo $URI |cut -f2 -d=`
    # Get a list of matching entries using aht find-domain, including stage and sitename
    echo "No @app.env given, trying to resolve realm and application name from $uri..."
    aht --no-ansi --stages=all fd $uri |awk -F' ' '
    NR==1 {
      names["Acquia Cloud Enterprise"] = "ace"
      names["Acquia Cloud"] = "ac"
      names["Acquia Network"] = "network"
      names["SMB Gardens"] = "smb"
      names["WMG Gardens"] = "wmg"
      names["UMG Gardens"] = "umg"
      names["Acquia Cloud Site Factory"] = "acsf"
    }
    /^\[/ { stage_txt=substr($0,2,length($0)-3); }
    /^ / { print "STAGE=--stages=" names[stage_txt] "; SITENAME=@" $1 " # " stage_txt }
    ' >$tmpout
    if [ $? -eq 0 ]
    then
      if [ `grep -c . $tmpout` -gt 1 ]
      then
        echo "  Found more than one possible realm and application, using last one:"
        cat $tmpout
      fi
      . $tmpout
      echo "  Using application $SITENAME, realm $STAGE"
    else
      echo "  Could not find environment for URI $uri"
      exit 1
    fi
    ahtsep
  fi
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

# Trim @ from sitename
SITENAME=`echo $SITENAME |cut -c2-`

# split site/env
site=`echo $SITENAME |cut -f1 -d'.'`
env=`echo $SITENAME |cut -f2 -d'.'`

# Attempt to get the application information
# On failure, assume application exists on multiple realms and one needs to be picked.
echo | aht --no-ansi $STAGE @$SITENAME application:info 2>&1 |tr -d '\015' >$tmpout2
if [ `grep -c "Could not find application named" $tmpout2` -gt 0 ]
then
  echo "${COLOR_RED}Can't get basic application information.${COLOR_NONE}"
  echo "  Possibly, an application with that name exists on multiple realms."
  echo ""
  echo "  ${COLOR_YELLOW}Try adding --ace, --ac"
  echo "   or call script with http://[domain] to automatically identify the realm.${COLOR_NONE}"
  echo ""
  echo "  Domains available:"
  for nom in ace ac
  do
    echo "  ${COLOR_YELLOW}--$nom${COLOR_NONE}"
    aht --$nom @$SITENAME domains:list |awk 'NR<=5 { print "    " $0 } END { if (NR>5) print "     .. found " NR " domains, only showing first 5." }'
  done
  exit 1
fi

# Highlight 'high' load averages
if [ ${SINGLECHECK:-x} = 0 ]
then
  aht $STAGE @$SITENAME application:load
  ahtsep
fi

sitefoldername=`egrep --color=none -o "^\[$env: [0-9a-z_]*" $tmpout2 |awk -F': ' '{ print $2}'`
echo "Environment Machine Name: $sitefoldername"

# Detect FPM from the aht output.
if [ `grep -c -- "-fpm" $tmpout2` -gt 0 ]
then
  FPM_FLAG=1
else
  FPM_FLAG=0
fi

# Get firstweb
web=`ahtaht ssh hostname`
if [ ${web:-x} = x ]
then
  echo "${COLOR_RED}Can't SSH into web: you are probably not part of the team, or don't have SSH permission."
  echo "Exiting!${COLOR_NONE}"
  exit 1
fi
echo "First web: $web"

# Get the domain for the servers
server_domain=`echo $web |cut -f2- -d.`
echo "Server_domain: $server_domain"

# Get the webs. Note we ignore deds if we also have webs
# ... without out-of-rotation webs
webs=`egrep "srv-|web-|ded-|staging-|managed-" $tmpout2 |egrep -v ' (\*|†)' |awk -F' ' 'NR==1 { show=1 } /web-/ { foundweb=1 } /ded-/ { if (foundweb==1) show=0 } show==1 { print $1 ".'$server_domain'" }'`
# ... with out-of-rotation webs
webs_raw=`egrep "srv-|web-|ded-|staging-|managed-" $tmpout2 |awk -F' ' 'NR==1 { show=1 } /web-/ { foundweb=1 } /ded-/ { if (foundweb==1) show=0 } show==1 { print $1 ".'$server_domain'" }'`
#echo "Webs: $webs_raw"

# devcloud/not devcloud
devcloud=`echo $web |grep -c srv-`
# livedev/not livedev
# Detect FPM from the aht output.
LIVEDEV_FLAG=`grep -c -- "LIVEDEV" $tmpout2`

ahtsep

# Run only single check
if [ ${SINGLECHECK:-x} != 0 ]
then
  type -t test_${SINGLECHECK} >/dev/null 2>&1
  if [ $? -eq 1 ]
  then
    echo "${COLOR_RED}ERROR: Command $SINGLECHECK doesn't exist."
    echo "Available commands:"
    grep -o "function test_[^ ]*" ../lib/ahtpanic-functions.sh |cut -f2- -d_ |cut -f1 -d'(' |sort |awk '{ printf("  %s",$0) } END { printf "\n" }'
    ahtsep
    exit 1
  fi
  test_${SINGLECHECK}
  exit $?
fi


# Run basic checks
if [ $BASICCHECK_FLAG = 1 ]
then
  test_show_panic_links
  if [ $devcloud -eq 0 ]
  then
    test_code_deploy
  fi
  test_nagios_info
  test_xfs_freeze
  test_php_memory_limit
  test_syslog_check
  test_daemonlog_check
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
  test_php_session_gc
  test_external_connections
  test_dns
  test_varnish_stats
  test_nginx_max_conn
  test_tasks
  #test_email_volume
  test_anonsession
fi

# Run Drush-based checks
if [ $DRUSH_FLAG -eq 1 ]
then
  test_ahtaudit

  # Run some more checks, but only if drush works.
  if [ $drushworks_flag -eq 1 ]
  then
    test_db_update_status
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
  test_phpla
fi

# Finish & cleanup.
rm $tmpout $tmpout2 2>/dev/null
