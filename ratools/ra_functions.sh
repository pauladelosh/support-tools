############################################################################################
# remote admin bash functions
#
# written by Matt Lavoie
# based on original scripts by George Cassie and Maria McDowell
#
# add the following block to ~/.bash_profile to use the ratools scripts. 
# make sure to uncomment the variable lines and set them to your information. 
#
# set ratools variables and include the script
# RA_INITIALS=""
# SVN_USERNAME=""
# SVN_PASSWORD=""
# source ~/<path-to-support-tools>/ratools/ra_functions.sh
#
# Instructions:
# 1.  RA Audit: ra-audit @<docroot>.<environment>
# -c <ticket number> to generate update commands
# -p <dc/mc/ac/ace> to specify hosting platform
# 2.  Unless otherwise specified, commands can be run from docroot level of repo.
# 3.  Initialize Repo and Branch:
# ra-init-repo @<docroot>.<environment> <source_tag> <branch_name>
# ra-init-repo @<docroot>.<environment> <branch_name> (This will pull the source_tag from the environment)
# example: ra-init-repo @radash.prod master acqUpd-20140307-23456
# 4.  Update functions:
# Quick check of site distribution, version and install profile: dvpcheck @<docroot>.<environment>
# Core Update:
#   ra-cupdate <distribution> <source version> <target version> <ticket number>
#   Requires installation of patches (see: https://github.com/acquiacat/Drupal-Core-Git-Patches)
#   example: ra-cupdate drupal 7.24 7.26 23456
# Automatic Module Update:
#   ra-auto-mupdate <module> <source version> <target version> <ticket number>
#   add --security to mark as a security update
#   Diff will be run against source_version with option to stop update
#   example: ra-auto-mupdate ctools 7.x-1.2 7.x-1.4 23456 --security
# Module Update:
#   ra-mupdate <module> <source version> <target version> <ticket number>
#   Must be run from within containing module folder
#   add --security to mark as a security update
#   example: ra-mupdate ctools 7.x-1.2 7.x-1.4 23456 --security
# Add New Module:
#   ra-mupdate-add <module> <version> <ticket number>
#   example: ra-mupdate-add ctools 7.x-1.4 23456
# Revert Module:
#   ra-mupdate-rev <module> <source version> <target version> <ticket number>
#   Must be run from within containing module folder
#   example: ra-mupdate-rev ctools 7.x-1.4 7.x-1.2 23456
# Fix settings.php files for the Search Apocalypse:
#   ra-searchpocolypse <ticket number>
#   example: ra-searchpocolypse 12345
# 5. RA environment related functions:
#  Copy domains to the RA environment:
#    ra-copy-domains @<docroot>.<environment> <optional sed command>
#    This command will copy all domains to RA with the prefix 'ra.'
#    If you would prefer a different naming scheme, add a sed command.
#    example: ra-copy-domains @<docroot>.<environment>
#    example: ra-copy-domains @<docroot>.<environment> s/site.com/dev-ra.site.com/
#  Download the stage_file_proxy module on the RA environment:
#    ra-download-file-proxy @<docroot>
#    example: ra-download-file-proxy @radash
#  Enable and configure the stage_file_proxy module on the RA environment:
#    ra-enable-file-proxy @<docroot>
#    example: ra-enable-file-proxy @radash
#  Remove the stage_file_proxy module on the RA environment:
#    ra-remove-file-proxy @<docroot>
#    example: ra-remove-file-proxy @radash
#
############################################################################################

# Current date and build of tools. increment build number by one. format: "build zzzz (yyyy-mm-dd)"
# DON'T FORGET TO UPDATE THIS WHEN PUSHING TO MASTER!!
RATOOLS_VERSION="Build 0006 (2014-05-27)"

# Output date and build of current toolset
alias ra-version='echo $RATOOLS_VERSION'

# Help
alias ra-help='ratools-help'
function ratools-help {
echo ""
echo "Remote Administration Scripts Help:"
echo ""
echo "1.  RA Audit: ra-audit @<docroot>.<environment>"
echo "  -c <ticket number> to generate update commands"
echo "  -p <dc/mc/ac/ace> to specify hosting platform"
echo "2.  Unless otherwise specified, commands can be run from docroot level of repo."
echo "3.  Initialize Repo and Branch:"
echo "  ra-init-repo @<docroot>.<environment> <source_tag> <branch_name>"
echo "  ra-init-repo @<docroot>.<environment> <branch_name> (This will pull the source_tag from the environment)"
echo "  example: ra-init-repo @radash.prod master acqUpd-20140307-23456"
echo "4.  Update functions:"
echo "  Quick check of site distribution, version and install profile: dvpcheck @<docroot>.<environment>"
echo "  Core Update:"
echo "    ra-cupdate <distribution> <source version> <target version> <ticket number>"
echo "    Requires installation of patches (see: https://github.com/acquiacat/Drupal-Core-Git-Patches)"
echo "    example: ra-cupdate drupal 7.24 7.26 23456"
echo "  Automatic Module Update:"
echo "    ra-auto-mupdate <module> <source version> <target version> <ticket number>"
echo "    add --security to mark as a security update"
echo "    Diff will be run against source_version with option to stop update"
echo "    example: ra-auto-mupdate ctools 7.x-1.2 7.x-1.4 23456 --security"
echo "  Module Update:"
echo "    ra-mupdate <module> <source version> <target version> <ticket number>"
echo "    Must be run from within containing module folder"
echo "    add --security to mark as a security update"
echo "    example: ra-mupdate ctools 7.x-1.2 7.x-1.4 23456 --security"
echo "  Add New Module:"
echo "    ra-mupdate-add <module> <version> <ticket number>"
echo "    example: ra-mupdate-add ctools 7.x-1.4 23456"
echo "  Revert Module:"
echo "    ra-mupdate-rev <module> <source version> <target version> <ticket number>"
echo "    Must be run from within containing module folder"
echo "    example: ra-mupdate-rev ctools 7.x-1.4 7.x-1.2 23456"
echo "  Fix settings.php files for the Search Apocalypse: "
echo "    ra-searchpocolypse <ticket number>"
echo "    example: ra-searchpocolypse 12345"
echo "5. RA environment related functions: "
echo "  Copy domains to the RA environment: "
echo "    ra-copy-domains @<docroot>.<environment> <optional sed command>"
echo "    This command will copy all domains to RA with the prefix 'ra.'"
echo "    If you would prefer a different naming scheme, add a sed command."
echo "    example: ra-copy-domains @<docroot>.<environment>"
echo "    example: ra-copy-domains @<docroot>.<environment> s/site.com/dev-ra.site.com/"
echo "  Download the stage_file_proxy module on the RA environment: "
echo "    ra-download-file-proxy @<docroot>"
echo "    example: ra-download-file-proxy @radash"
echo "  Enable and configure the stage_file_proxy module on the RA environment: "
echo "    ra-enable-file-proxy @<docroot>"
echo "    example: ra-enable-file-proxy @radash"
echo "  Remove the stage_file_proxy module on the RA environment: "
echo "    ra-remove-file-proxy @<docroot>"
echo "    example: ra-remove-file-proxy @radash"
echo ""
}

# Quick check of site distribution, version and install profile (dvpcheck @<docroot>.<environment>)
function dvpcheck { aht $1 drush5 php-eval 'echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . " " . VERSION . "\n";'; aht $1 drush5 vget install_profile; }

# RA Update Audit (ra-audit @<docroot>.<environment> (add -c <ticket number> to generate update commands, -p <dc/mc/ac/ace> to specify hosting platform))
function ra-audit {
######################################################
# define proactive updates here (seperate with pipes):
RA_PROACTIVE_UPDATES="acquia_connector|acquia_search|mollom|apachesolr|apachesolr_multisitesearch|search_api_acquia|search_api|entity"
RA_UNSUPPORTED_EXCEPTIONS="acquia_connector|mollom"
######################################################
local OPTIND
DOCROOT=$1
shift
while getopts ":p:c:" opt; do
  case $opt in
    p)
      DOCROOT="'--$OPTARG $DOCROOT'"
      echo -e "\033[1;33;148m[ Hosting Platform Specified ]\033[39m"; tput sgr0
    echo "Using platform option \"--$OPTARG\""
    echo
      ;;
    c)
      local RA_AUDIT_UPDCMD="true"
      #RA_AUDIT_VCS=`echo $OPTARG | cut -f2 -d"=" | cut -f1 -d","`
      #RA_AUDIT_TICKNUM=`echo $OPTARG | cut -f2 -d"=" | cut -f2 -d","`
      RA_AUDIT_TICKNUM=$OPTARG
      #if [ $RA_AUDIT_VCS != "git" ] && [ $RA_AUDIT_VCS != "svn" ]
      #  then echo "ERROR: invalid VCS specified (must be git/svn): exiting" && exit
      #fi
      echo -e "\033[1;33;148m[ Update Command Builder Enabled ]\033[39m"; tput sgr0
    #echo "Version Control Type: $RA_AUDIT_VCS"
    echo "Ticket Number: $RA_AUDIT_TICKNUM"
    echo
      ;;
  esac
done
echo -e "\033[1;33;148m[ Distribution, Version and Install Profile Check ]\033[39m"; tput sgr0
aht $DOCROOT drush5 php-eval 'echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . " " . VERSION . "\n";'
aht $DOCROOT drush5 vget install_profile
echo
echo -e "\033[1;33;148m[ Drush Status (default site) ]\033[39m"; tput sgr0
aht $DOCROOT drush5 status
echo
echo -e "\033[1;33;148m[ Current Deployed Code ]\033[39m"; tput sgr0
echo -n "dev:   "; aht `echo $DOCROOT | cut -f2 -d "'" | cut -f1 -d "."`.dev repo
echo -n "stage:   "; aht `echo $DOCROOT | cut -f2 -d "'" | cut -f1 -d "."`.test repo
echo -n "ra:   "; aht `echo $DOCROOT | cut -f2 -d "'" | cut -f1 -d "."`.ra repo
echo -n "prod:   "; aht `echo $DOCROOT | cut -f2 -d "'" | cut -f1 -d "."`.prod repo
echo
echo -e "\033[1;33;148m[ Multisite Check ]\033[39m"; tput sgr0
aht $DOCROOT sites | grep -v \>
echo
echo -e "\033[1;33;148m[ Checking for Update Warnings/Errors ]\033[39m"; tput sgr0
audit=""
for site in `aht $DOCROOT sites | grep -v \>`; do
  echo $site
  current_audit=`aht $DOCROOT drush5 upc --pipe --uri=$site`
  audit+="$current_audit"
  audit+=$'\n'
  echo "$current_audit" | if egrep 'warning|error'; then :; else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0; fi; echo;
done
echo -e "\033[1;33;148m[ Available Drupal Core Updates ]\033[39m"; tput sgr0
if echo "$audit" | grep -q -w drupal
  then echo "$audit" | grep -w drupal | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
echo
echo -e "\033[1;33;148m[ Available Security Updates ]\033[39m"; tput sgr0
if echo "$audit" | grep SECURITY-UPDATE-available | grep -v -w -q drupal
  then echo "$audit" | grep SECURITY-UPDATE-available | grep -v -w drupal | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
if [[ $RA_AUDIT_UPDCMD == "true" ]]; then
echo "=========="
#grep SECURITY-UPDATE-available /tmp/ra-audit-updates.tmp | grep -v -w drupal | sort | uniq | sed -e "s/^/$RA_AUDIT_VCS-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM --security/"
echo "$audit" | grep SECURITY-UPDATE-available | grep -v -w drupal | sort | uniq | sed -e "s/^/ra-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM --security/"
fi
echo
echo -e "\033[1;33;148m[ Available Proactive Updates ]\033[39m"; tput sgr0
if ( echo "$audit" | egrep -w $RA_PROACTIVE_UPDATES | egrep -q -v 'Installed-version-not-supported|SECURITY-UPDATE-available' ) || ( echo "$audit" | egrep -w $RA_UNSUPPORTED_EXCEPTIONS | egrep -q 'Installed-version-not-supported' | sort | uniq ); then 
  echo "$audit" | egrep -w $RA_PROACTIVE_UPDATES | egrep -v 'Installed-version-not-supported|SECURITY-UPDATE-available' | sort | uniq
  echo "$audit" | egrep -w $RA_UNSUPPORTED_EXCEPTIONS | egrep 'Installed-version-not-supported' | sort | uniq
else
  echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
if [[ $RA_AUDIT_UPDCMD == "true" ]]; then
echo "=========="
#egrep -w $RA_PROACTIVE_UPDATES /tmp/ra-audit-updates.tmp | egrep -v 'Installed-version-not-supported|SECURITY-UPDATE-available' | sort | uniq | sed -e "s/^/$RA_AUDIT_VCS-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM/"
echo "$audit" | egrep -w $RA_PROACTIVE_UPDATES | egrep -v 'Installed-version-not-supported|SECURITY-UPDATE-available' | sort | uniq | sed -e "s/^/ra-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM/"
echo "$audit" | egrep -w $RA_UNSUPPORTED_EXCEPTIONS | egrep 'Installed-version-not-supported' | sort | uniq | sed -e "s/^/ra-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM/"
fi
echo
echo -e "\033[1;33;148m[ Available Development Updates ]\033[39m"; tput sgr0
if echo "$audit" | egrep '\-dev|\-unstable|\-alpha|\-beta|\-rc' | egrep -q -v -w "'$RA_PROACTIVE_UPDATES|Installed-version-not-supported|SECURITY-UPDATE-available'"
  then echo "$audit" | egrep '\-dev|\-unstable|\-alpha|\-beta|\-rc' | egrep -v -w "'$RA_PROACTIVE_UPDATES|Installed-version-not-supported|SECURITY-UPDATE-available'" | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
if [[ $RA_AUDIT_UPDCMD == "true" ]]; then
echo "=========="
#egrep '\-dev|\-unstable|\-alpha|\-beta|\-rc' /tmp/ra-audit-updates.tmp | egrep -v -w "'$RA_PROACTIVE_UPDATES|Installed-version-not-supported|SECURITY-UPDATE-available'" | sort | uniq | sed -e "s/^/$RA_AUDIT_VCS-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM/"
echo "$audit" | egrep '\-dev|\-unstable|\-alpha|\-beta|\-rc' | egrep -v -w "'$RA_PROACTIVE_UPDATES|Installed-version-not-supported|SECURITY-UPDATE-available'" | sort | uniq | sed -e "s/^/ra-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM/"
fi
echo
echo -e "\033[1;33;148m[ All Available Updates ]\033[39m"; tput sgr0
if echo "$audit" | egrep -q 'Update-available|SECURITY-UPDATE-available'
  then echo "$audit" | egrep 'Update-available|SECURITY-UPDATE-available' | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
echo
echo -e "\033[1;33;148m[ Unsupported/Out-of-Scope Updates (do not perform) ]\033[39m"; tput sgr0
if echo "$audit" | egrep 'Installed-version-not-supported' | egrep -qv $RA_UNSUPPORTED_EXCEPTIONS
  then echo "$audit" | egrep 'Installed-version-not-supported' | egrep -v $RA_UNSUPPORTED_EXCEPTIONS | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
echo
}

# Module Cache Check (module-cache-check <module> <version>)
# Excludes dev modules as they will always be wrong and fail for diff checking
function module-cache-check {
if [ -d ~/Sites/releases/modules/$1/$2 ]
  then echo "module $1-$2 found in cache"
elif echo $2 | grep -q "\-dev"
  then echo "module $1-$2 is dev, not downloading"
else
  echo "module $1-$2 not found in cache; downloading..."
  mkdir -p ~/Sites/releases/modules/$1/$2
  curl "http://ftp.drupal.org/files/projects/$1-$2.tar.gz" | tar xz -C ~/Sites/releases/modules/$1/$2
  if [ -z `ls ~/Sites/releases/modules/$1/$2` ]
    then rm -rf ~/Sites/releases/modules/$1/$2; echo "ERROR: failed to download $1-$2!"
    else echo "$1-$2 downloaded on `date`" >> ~/Sites/releases/modules/cache.log
  fi
fi
}

# Git/SVN agnostic function shortcuts
function ra-searchpocolypse { if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" != "true" ]; then svn-searchpocolypse $@; else git-searchpocolypse $@; fi }
function ra-cupdate { if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" != "true" ]; then svn-cupdate $@; else git-cupdate $@; fi }
function ra-auto-mupdate { if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" != "true" ]; then svn-auto-mupdate $@; else git-auto-mupdate $@; fi }
function ra-mupdate { if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" != "true" ]; then svn-mupdate $@; else git-mupdate $@; fi }
function ra-mupdate-add { if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" != "true" ]; then svn-mupdate-add $@; else git-mupdate-add $@; fi }
function ra-mupdate-rev { if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" != "true" ]; then svn-mupdate-rev $@; else git-mupdate-rev $@; fi }
function ra-init-repo {
  if [[ $1 == --* ]]; then
    site="$1 $2"
  else
  site=$1
  fi
  if (yes 1 | aht $site | grep -q Please); then
  echo "The site $site exists on more than one Acquia instance. Please use a --mc or --dc flag to select the correct instance for this site. "
    echo "Example: ra-init-repo --mc $site source_tag target_branch"
    return
  fi
  if [[ "$(aht $site repo)" = *git* ]]; then git-init-repo $@; else svn-init-repo $@; fi
}

function git-searchpocolypse {
  if [ -z "$1" ]; then
    echo "Missing ticket number." && return
  fi
  if [ -z `find . -name settings.php -exec grep 'search.acquia.com' {} \;` ]; then
    echo "No instances of search.acquia.com found in settings.php files." && return
  fi
  find . -name settings.php -exec sed -i '' 's/search.acquia.com/useast1-c5.acquia-search.com/g' {} \;
  git --no-pager diff
  read -p "Would you like to commit the changes above? (y/n): " -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add -A
    git commit -m "$RA_INITIALS@acq: Changes instances of search.acquia.com to useast1-c5.acquia-search.com in all settings.php files. Ticket #$1."
  else
    git reset --hard
  fi

}

function svn-searchpocolypse {
  if [ -z "$1" ]; then
    echo "Missing ticket number." && return
  fi
  if [ -z `find . -name settings.php -exec grep 'search.acquia.com' {} \;` ]; then
    echo "No instances of search.acquia.com found in settings.php files." && return
  fi
  find . -name settings.php -exec sed -i '' 's/search.acquia.com/useast1-c5.acquia-search.com/g' {} \;
  svn diff
  read -p "Would you like to commit the changes above? (y/n): " -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    svn commit -m "$RA_INITIALS@acq: Changes instances of search.acquia.com to useast1-c5.acquia-search.com in all settings.php files. Ticket #$1."
  else
    svn revert -R .
  fi
}

# SVN, Get Repository (get-repo-svn <docroot-name> <repository-url)
function get-repo-svn { cd ~/Sites/clients; mkdir $1; cd $1; svn checkout --username $SVN_USERNAME --password $SVN_PASSWORD $2; }

# SVN, Initialize Repository
# Usage: svn-init-repo @<docroot>.<environment> <source_tag> <target_branch>
# svn-init-repo @<docroot>.<environment> <target_branch>
function svn-init-repo {
    if [ -z "$SVN_USERNAME" ]; then
echo "Need to set SVN_USERNAME" && return
fi
if [ -z "$SVN_PASSWORD" ]; then
echo "Need to set SVN_PASSWORD" && return
fi
if [ $# -lt 2 ]
      then echo "Missing docroot" && return
fi
    #support for the --mc and --dc type flags in aht
    if [[ $1 == --* ]]; then
site="$1 $2"
      shift
else
site=$1
    fi
    #split $1 into three distinct variables (@site.env => @site, site, and env)
    base=${1%.*}
    docroot=${base#@*}
    acqenv=${1#*.}
    if [ -d ./$docroot ]; then
echo "Error: Directory $docroot already exists"
        return
fi
repo="$(aht $site repo)"
    if [[ $repo =~ "live development" ]]; then
repo=$(echo "$repo" | grep svn)
    elif [[ $repo =~ "Could not find sitegroup or environment" ]]; then
echo "Could not find sitegroup or environment." && return;
    fi
url=$(echo $repo | tr -d '\r')
    baseurl=$(echo "$url" | sed "s/$docroot\/.*/$docroot/")
    if [ $# -eq 2 ]; then
source_url=$url
      target_branch=$2
    else
source_url=$baseurl/$2
      target_branch=$3
    fi
source_tag=$(echo "$source_url" | sed "s/.*$docroot\///")
    mkdir $docroot && cd $docroot
    svn checkout --username=$SVN_USERNAME --password=$SVN_PASSWORD $baseurl/trunk
    while true; do
echo "\"svn copy $source_url $baseurl/branches/$target_branch -m \"$RA_INITIALS@acq: Branch from $source_tag to implement updates.\"\""
        read -p "OK to create/commit branch $target_branch from $source_tag using above command? (y/n) " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) return;;
            * ) echo "invalid response, try again";;
        esac
done
svn copy $source_url $baseurl/branches/$target_branch -m "$RA_INITIALS@acq: Branch from $source_tag to implement updates."
    echo "RECORD REVISION NUMBER IN VCS"
    cd trunk
    svn switch ^/branches/$target_branch
}

# SVN, Core Update (svn-cupdate <distribution> <source version> <target version> <ticket number>)
function svn-cupdate {
echo -e "\033[1;33;148m[ checking input and patchfile ]\033[39m"
if [ -z "$1" ]
  then echo -e "\033[0;31;148mmissing distribution: exiting\033[39m" && return
  else echo -e "\033[0;32;148mdistribution: $1\033[39m"
fi
if [ -z "$2" ]
  then echo -e "\033[0;31;148mmissing source version: exiting\033[39m" && return
  else echo -e "\033[0;32;148msource version: $2\033[39m"
fi
if [ -z "$3" ]
  then echo -e "\033[0;31;148mmissing target version: exiting\033[39m" && return
  else echo -e "\033[0;32;148mtarget version:  $3\033[39m"
fi
if [ -z "$4" ]
  then echo -e "\033[0;31;148mmissing ticket number: exiting\033[39m" && return
  else echo -e "\033[0;32;148mticket number:  $4\033[39m"
fi
if ls  ~/Sites/releases/version-patches/$1 | grep -q $1-$2_to_$3.patch
  then echo -e "\033[0;32;148msuitable patch found: ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch\033[39m"
  else echo -e "\033[0;31;148mno suitable patch found (tried to find ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch): exiting\033[39m" && return
fi
tput sgr0
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ running patch $1-$2_to_$3 ]\033[39m"; tput sgr0
if svn info | grep URL | cut -f2 -d" " | xargs basename | grep trunk
  then while true; do
    read -p "WARNING: you are currently in trunk. Continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
    esac
  done
fi
if echo ${PWD##*/} | grep -q docroot
  then :;
  else while true; do
    read -p "WARNING: you are currently not in docroot. Continue? (y/n) " yn
      case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
      esac
    done
fi
patch -p1 < ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch;
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ checking for reject/original files ]\033[39m"; tput sgr0
while svn status --no-ignore | egrep -q '\.orig|\.rej'; do 
  svn status --no-ignore | egrep '\.rej|\.orig'
  echo -e "\033[0;31;148mERROR: original/reject files found! open a new window, resolve all issues, and remove any orig/rej files.\033[39m"; tput sgr0
  echo "to change into repository and find all reject/original files: cd `pwd` && svn status --no-ignore | egrep '.orig|.rej'"
  echo "to remove all reject/original files: svn status --no-ignore | egrep '.orig|.rej' | awk '{print \$2}' | xargs rm"
  echo "cd `pwd`; svn status --no-ignore | egrep '\.orig|\.rej'" | pbcopy
  echo
  read -p "Press return to retry, or ctrl-c to stop...";
  echo
done
echo -e "\033[0;32;148mno original/reject files found!\033[39m"; tput sgr0
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ removing version numbers ]\033[39m"; tput sgr0
FILETYPE='*.info'
 INCLUDEONLY='modules themes profiles/minimal profiles/standard profiles/testing'
 files=( $(find $INCLUDEONLY -name "$FILETYPE") )
for file in "${files[@]}"; do
  sed -i '' '/; Information added by drupal.org packaging script on [0-9]*-[0-9]*-[0-9]*/d' $file
  sed -i '' '/version = "[0-9]*.[0-9]*"/d' $file
  sed -i '' '/project = "drupal"/d' $file
  sed -i '' '/datestamp = "[0-9]*"/d' $file
  echo 'Checking' $file
done
echo 'Checked' ${#files[@]} 'files and removed drupal.org packaging data'
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ adding changes to svn ]\033[39m"; tput sgr0
svn status | grep '\?' | awk '{print $2}' | xargs svn add
svn status | grep '\!' | awk '{print $2}' | xargs svn rm
svn status --no-ignore
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ commiting changes ]\033[39m"; tput sgr0
echo "currently on svn branch `svn info | grep URL | cut -f2 -d" "`"
while true; do
    read -p "commit \"$RA_INITIALS@Acq: Update from $1 $2 to $3. Ticket #$4.\" now? (y/n) " yn
    case $yn in
        [Yy]* ) svn commit -m "$RA_INITIALS@Acq: Update from $1 $2 to $3. Ticket #$4."; echo -e "\033[0;32;148mchanges commited\033[39m"; break;;
        [Nn]* ) echo -e "\033[0;31;148mchanges not commited\033[39m"; break;;
        * ) echo "invalid response, try again";;
    esac
done
}

# SVN, Automatic Module Update (svn-auto-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))
function svn-auto-mupdate {
if [ -z "$1" ]; then echo "ERROR: missing module name; exiting" && return; fi
if [ -z "$2" ]; then echo "ERROR: missing source version; exiting" && return; fi
if [ -z "$3" ]; then echo "ERROR: missing target version; exiting" && return; fi
if [ -z "$4" ]; then echo "ERROR: missing ticket number; exiting" && return; fi
if svn info | grep URL | cut -f2 -d" " | xargs basename | grep -w trunk
  then while true; do
    read -p "WARNING: you are currently in trunk. Continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
    esac
  done
fi
homepath=`pwd`
if echo $2 | grep -q "\-dev"
  then echo -e "\033[0;31;148m"ERROR: source version $2 is a dev version. use svn-mupdate to perform this update manually."\033[39m"; tput sgr0 && return
fi
module-cache-check $1 $2
module-cache-check $1 $3
if [ $1 = "acquia_connector" ]; then modname=acquia_agent
  elif [ $1 = "google_analytics" ]; then modname=googleanalytics
  elif [ $1 = "features_extra" ]; then modname=fe_block
  elif [ $1 = "vote_up_down" ]; then modname=vud
  elif [ $1 = "user_relationships" ]; then modname=user_relationship_blocks
  elif [ $1 = "ubercart" ]; then modname=uc_cart
  else modname=$1
fi
for modinfopath in `find . -name $modname.info`
  do
    if [ $modname = acquia_agent ]; then modpath=`dirname $(dirname $(dirname $modinfopath))`
      elif [ $modname = user_relationship ]; then modpath=`dirname $(dirname $(dirname $modinfopath))`
      elif [ $modname = uc_cart ]; then modpath=`dirname $(dirname $(dirname $modinfopath))`
      else modpath=`dirname $(dirname $modinfopath)`
    fi
    if grep "version = \"$2\"" $modinfopath > /dev/null
      then while true; do read -p "Update $1-$2 at $modpath to $1-$3? (y/n) " yn
          case $yn in
              [Yy]* ) cd $modpath
                echo -e "\033[1;33;148m"checking to see if $1 at $modpath is modified..."\033[39m"; tput sgr0
                diff -rq $1 ~/Sites/releases/modules/$1/$2/$1
                if [ $? -ne 1 ]
                  then
                    echo -e "\033[0;32;148m"module does not appear to be modified"\033[39m"; tput sgr0
                    svn rm "$1"
                    if [ "$5" = "--security" ]
                      then svn commit -m "$RA_INITIALS@Acq: Module Security Update, cleanup, removing $1-$2 at $modpath. Ticket #$4."
                      else svn commit -m "$RA_INITIALS@Acq: Module Update, cleanup, removing $1-$2 at $modpath. Ticket #$4."
                    fi
                    #curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
                    cp -R ~/Sites/releases/modules/$1/$3/$1 .
                    svn add --force "$1"
                    if [ "$5" = "--security" ]
                      then svn commit -m "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                      else svn commit -m "$RA_INITIALS@Acq: Module Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                    fi
                else 
                  echo -e "\033[1;33;148m"WARNING: $1 at $modpath appears to be modified"\033[39m"; tput sgr0
                  while true; do read -p "update potentially modified module anyways? (y/n) " yn
                    case $yn in
                    [Yy]* ) svn rm "$1"
                    if [ "$5" = "--security" ]
                      then svn commit -m "$RA_INITIALS@Acq: Module Security Update, cleanup, removing $1-$2 at $modpath. Ticket #$4."
                      else svn commit -m "$RA_INITIALS@Acq: Module Update, cleanup, removing $1-$2 at $modpath. Ticket #$4."
                    fi
                    #curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
                    cp -R ~/Sites/releases/modules/$1/$3/$1 .
                    svn add --force "$1"
                    if [ "$5" = "--security" ]
                      then svn commit -m "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                      else svn commit -m "$RA_INITIALS@Acq: Module Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                    fi
                    break;;
                    [Nn]* ) echo "skipping $1 at $modpath"; break;;
                    * ) echo "invalid response, try again";;
                    esac
                  done
                fi
                cd $homepath
                break;; 
              [Nn]* ) break;;
              * ) echo "invalid response, try again";;
            esac
           done
      else echo -e "\033[1;33;148m"NOTICE: $1 at $modpath is not version $2\; skipping"\033[39m"; tput sgr0
    fi
  done
}

# SVN, Module Update (svn-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))
function svn-mupdate {
if [ -z "$1" ]; then echo "ERROR: missing module name; exiting" && return; fi
if [ -z "$2" ]; then echo "ERROR: missing source version; exiting" && return; fi
if [ -z "$3" ]; then echo "ERROR: missing target version; exiting" && return; fi
if [ -z "$4" ]; then echo "ERROR: missing ticket number; exiting" && return; fi
if ls | grep -w $1; then echo "found $1"; else echo "$1 not found: exiting" && return; fi
if svn info | grep URL | cut -f2 -d" " | xargs basename | grep -w trunk
  then while true; do
    read -p "WARNING: you are currently in trunk. Continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
    esac
  done
fi
svn rm "$1"
if [ "$5" = "--security" ]
  then svn commit -m "$RA_INITIALS@Acq: Module Security Update, cleanup, removing $1-$2. Ticket #$4."
  else svn commit -m "$RA_INITIALS@Acq: Module Update, cleanup, removing $1-$2. Ticket #$4."
fi
curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
svn add --force "$1"
if [ "$5" = "--security" ]
  then svn commit -m "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 from $2. Ticket #$4."
  else svn commit -m "$RA_INITIALS@Acq: Module Update, updating $1-$3 from $2. Ticket #$4."
fi
}

# SVN, Add New Module (svn-mupdate-add <module> <version> <ticket number>)
function svn-mupdate-add {
if [ -z "$1" ]; then echo "ERROR: missing module name; exiting" && return; fi
if [ -z "$2" ]; then echo "ERROR: missing version; exiting" && return; fi
if [ -z "$3" ]; then echo "ERROR: missing ticket number; exiting" && return; fi
if ls | grep -w $1; then echo "$1 already exists: exiting" && return; fi
if svn info | grep URL | cut -f2 -d" " | xargs basename | grep -w trunk
  then while true; do
    read -p "WARNING: you are currently in trunk. Continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
    esac
  done
fi
curl "http://ftp.drupal.org/files/projects/$1-$2.tar.gz" | tar xz
svn add --force "$1"
svn commit -m "$RA_INITIALS@Acq: Module Install, adding $1-$2. Ticket #$3."
}

# SVN, Revert Module (svn-mupdate-rev <module> <source version> <target version> <ticket number>)
function svn-mupdate-rev {
if [ -z "$1" ]; then echo "ERROR: missing module name; exiting" && return; fi
if [ -z "$2" ]; then echo "ERROR: missing source version; exiting" && return; fi
if [ -z "$3" ]; then echo "ERROR: missing target version; exiting" && return; fi
if [ -z "$4" ]; then echo "ERROR: missing ticket number; exiting" && return; fi
if ls | grep -w $1; then echo "found $1"; else echo "$1 not found: exiting" && return; fi
if svn info | grep URL | cut -f2 -d" " | xargs basename | grep -w trunk
  then while true; do
    read -p "WARNING: you are currently in trunk. Continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
    esac
  done
fi
svn rm "$1"
svn commit -m "$RA_INITIALS@Acq: Module Revert, cleanup, removing $1-$2 module. Ticket #$4."
curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
svn add --force "$1"
svn commit -m "$RA_INITIALS@Acq: Module Revert, reverting to $1-$3 from $2. Ticket #$4."
}

# Git, Get Repository (get-repo-git <docroot-name> <repository-url)
function get-repo-git { cd ~/Sites/clients; mkdir $1; cd $1; git clone $2; }

# Git, Initialize Repository 
# Usage: git-init-repo @<docroot>.<environment> <source_tag> <target_branch>
# git-init-repo @<docroot>.<environment> <target_branch>
function git-init-repo {
    if [ $# -lt 2 ]
      then echo "Missing docroot" && return
fi
    #support for the --mc and --dc type flags in aht
    if [[ $1 == --* ]]; then
site="$1 $2"
      shift
else
site=$1
    fi
    #split $1 into three distinct variables (@site.env => @site, site, and env)
    base=${1%.*}
    docroot=${base#@*}
    acqenv=${1#*.}
    if [ -d ./$docroot ]; then
echo "Error: Directory $docroot already exists" && return;
    fi
mkdir $docroot && cd $docroot
    repo="$(aht $site repo)"
    if [[ $repo =~ "live development" ]]; then
repo=$(echo "$repo" | grep svn)
    elif [[ $repo =~ "Could not find sitegroup or environment" ]]; then
echo "Could not find sitegroup or environment." && return;
    fi
if [ $# -eq 2 ]; then
source_tag=$(echo ${repo#* } | tr -d '\040\011\012\015')
        target_branch=$2
    else
source_tag=$2
        target_branch=$3
    fi
git clone ${repo% *}
    cd $docroot
    git pull --all
    git checkout $source_tag
    git checkout -b $target_branch
}

# Git, Core Update (git-cupdate <distribution> <source version> <target version> <ticket number>)
function git-cupdate {
echo -e "\033[1;33;148m[ checking input and patchfile ]\033[39m"
if [ -z "$1" ]
  then echo -e "\033[0;31;148mmissing distribution: exiting\033[39m" && return
  else echo -e "\033[0;32;148mdistribution: $1\033[39m"
fi
if [ -z "$2" ]
  then echo -e "\033[0;31;148mmissing source version: exiting\033[39m" && return
  else echo -e "\033[0;32;148msource version: $2\033[39m"
fi
if [ -z "$3" ]
  then echo -e "\033[0;31;148mmissing target version: exiting\033[39m" && return
  else echo -e "\033[0;32;148mtarget version:  $3\033[39m"
fi
if [ -z "$4" ]
  then echo -e "\033[0;31;148mmissing ticket number: exiting\033[39m" && return
  else echo -e "\033[0;32;148mticket number:  $4\033[39m"
fi
if ls  ~/Sites/releases/version-patches/$1 | grep -q $1-$2_to_$3.patch
  then echo -e "\033[0;32;148msuitable patch found: ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch\033[39m"
  else echo -e "\033[0;31;148mno suitable patch found (tried to find ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch): exiting\033[39m" && return
fi
tput sgr0
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ running patch $1-$2_to_$3 ]\033[39m"; tput sgr0
if git status | grep branch | grep -w master
  then while true; do
    read -p "WARNING: you are currently in master. Continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
    esac
  done
fi
if echo ${PWD##*/} | grep -q docroot
  then :;
  else while true; do
    read -p "WARNING: you are currently not in docroot. Continue? (y/n) " yn
      case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
      esac
    done
fi
patch -p1 < ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch;
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ checking for reject/original files ]\033[39m"; tput sgr0
while git status | egrep -q '\.orig|\.rej'; do 
  git status | egrep '\.rej|\.orig'
  echo -e "\033[0;31;148mERROR: original/reject files found! open a new window, resolve all issues, and remove any orig/rej files.\033[39m"; tput sgr0
  echo "to change into repository and locate all reject/original files: cd `pwd` && git status | egrep '.orig|.rej'"
  echo "to remove all reject/original files: git status | egrep '.orig|.rej' | awk '{print \$2}' | xargs rm"
  echo "cd `pwd`; git status | egrep '\.orig|\.rej'" | pbcopy
  echo
  read -p "Press return to retry, or ctrl-c to stop...";
  echo
done
echo -e "\033[0;32;148mno original/reject files found!\033[39m"; tput sgr0
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ removing version numbers ]\033[39m"; tput sgr0
FILETYPE='*.info'
 INCLUDEONLY='modules themes profiles/minimal profiles/standard profiles/testing'
 files=( $(find $INCLUDEONLY -name "$FILETYPE") )
for file in "${files[@]}"; do
  sed -i '' '/; Information added by drupal.org packaging script on [0-9]*-[0-9]*-[0-9]*/d' $file
  sed -i '' '/version = "[0-9]*.[0-9]*"/d' $file
  sed -i '' '/project = "drupal"/d' $file
  sed -i '' '/datestamp = "[0-9]*"/d' $file
  echo 'Checking' $file
done
echo 'Checked' ${#files[@]} 'files and removed drupal.org packaging data'
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ adding changes to git ]\033[39m"; tput sgr0
git add -A
git status
read -p "Press return to continue, or ctrl-c to stop..."
echo
echo -e "\033[1;33;148m[ commiting changes ]\033[39m"; tput sgr0
echo "`git status | grep branch`"
while true; do
    read -p "commit \"$RA_INITIALS@Acq: Update from $1 $2 to $3. Ticket #$4.\" now? (y/n) " yn
    case $yn in
        [Yy]* ) git commit -m "$RA_INITIALS@Acq: Update from $1 $2 to $3. Ticket #$4."; echo -e "\033[0;32;148mchanges commited\033[39m"; break;;
        [Nn]* ) echo -e "\033[0;31;148mchanges not commited\033[39m"; break;;
        * ) echo "invalid response, try again";;
    esac
done
}

# Git, Automatic Module Update (git-auto-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))
function git-auto-mupdate {
if [ -z "$1" ]; then echo "ERROR: missing module name; exiting" && return; fi
if [ -z "$2" ]; then echo "ERROR: missing source version; exiting" && return; fi
if [ -z "$3" ]; then echo "ERROR: missing target version; exiting" && return; fi
if [ -z "$4" ]; then echo "ERROR: missing ticket number; exiting" && return; fi
if git status | grep branch | cut -f4 -d" " | grep -w master
  then while true; do
    read -p "WARNING: you are currently in master. Continue? (y/n) " yn
    case $yn in
          [Yy]* ) break;;
          [Nn]* ) return;;
          * ) echo "invalid response, try again";;
      esac
    done
fi
homepath=`pwd`
if echo $2 | grep -q "\-dev"
  then echo -e "\033[0;31;148m"ERROR: source version $2 is a dev version. use git-mupdate to perform this update manually."\033[39m"; tput sgr0 && return
fi
module-cache-check $1 $2
module-cache-check $1 $3
if [ $1 = "acquia_connector" ]; then modname=acquia_agent
  elif [ $1 = "google_analytics" ]; then modname=googleanalytics
  elif [ $1 = "features_extra" ]; then modname=fe_block
  elif [ $1 = "vote_up_down" ]; then modname=vud
  elif [ $1 = "user_relationships" ]; then modname=user_relationship_blocks
  elif [ $1 = "ubercart" ]; then modname=uc_cart
  else modname=$1
fi
for modinfopath in `find . -name $modname.info`
  do
    if [ $modname = acquia_agent ]; then modpath=`dirname $(dirname $(dirname $modinfopath))`
      elif [ $modname = user_relationship ]; then modpath=`dirname $(dirname $(dirname $modinfopath))`
      elif [ $modname = uc_cart ]; then modpath=`dirname $(dirname $(dirname $modinfopath))`
      else modpath=`dirname $(dirname $modinfopath)`
    fi
    if grep "version = \"$2\"" $modinfopath > /dev/null
      then while true; do read -p "Update $1-$2 at $modpath to $1-$3? (y/n) " yn
          case $yn in
              [Yy]* ) cd $modpath
                echo -e "\033[1;33;148m"checking to see if $1 at $modpath is modified..."\033[39m"; tput sgr0
                diff -rq $1 ~/Sites/releases/modules/$1/$2/$1
                if [ $? -ne 1 ]
                  then
                    echo -e "\033[0;32;148m"module does not appear to be modified"\033[39m"; tput sgr0
                    git rm -rf "$1"
                    #keep below line for legacy purposes
                    #curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
                    cp -R ~/Sites/releases/modules/$1/$3/$1 .
                    git add "$1"
                    if [ "$5" = "--security" ]
                      then git commit -am "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                      else git commit -am "$RA_INITIALS@Acq: Module Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                    fi
                else 
                  echo -e "\033[1;33;148m"WARNING: $1 at $modpath appears to be modified"\033[39m"; tput sgr0
                  while true; do read -p "update potentially modified module anyways? (y/n) " yn
                    case $yn in
                    [Yy]* ) git rm -rf "$1"
                    cp -R ~/Sites/releases/modules/$1/$3/$1 .
                    git add "$1"
                    if [ "$5" = "--security" ]
                      then git commit -am "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                      else git commit -am "$RA_INITIALS@Acq: Module Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                    fi
                    break;;
                    [Nn]* ) echo "skipping $1 at $modpath"; break;;
                    * ) echo "invalid response, try again";;
                    esac
                  done
                fi
                cd $homepath
                break;;
              [Nn]* ) break;;
              * ) echo "invalid response, try again";;
            esac
           done
      else echo -e "\033[1;33;148m"NOTICE: $1 at $modpath is not version $2\; skipping"\033[39m"; tput sgr0
    fi
  done
}

# Git, Module Update (git-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))
function git-mupdate {
if [ -z "$1" ]; then echo "ERROR: missing module name; exiting" && return; fi
if [ -z "$2" ]; then echo "ERROR: missing source version; exiting" && return; fi
if [ -z "$3" ]; then echo "ERROR: missing target version; exiting" && return; fi
if [ -z "$4" ]; then echo "ERROR: missing ticket number; exiting" && return; fi
if ls | grep -w $1; then echo "found $1"; else echo "$1 not found: exiting" && return; fi
if git status | grep branch | cut -f4 -d" " | grep -w master
  then while true; do
    read -p "WARNING: you are currently in master. Continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
    esac
  done
fi
git rm -rf "$1"
curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
git add "$1"
if [ "$5" = "--security" ]
  then git commit -am "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 from $2. Ticket #$4."
  else git commit -am "$RA_INITIALS@Acq: Module Update, updating $1-$3 from $2. Ticket #$4."
fi
}

# Git, Add New Module (git-mupdate-add <module> <version> <ticket number>)
function git-mupdate-add {
if [ -z "$1" ]; then echo "ERROR: missing module name; exiting" && return; fi
if [ -z "$2" ]; then echo "ERROR: missing version; exiting" && return; fi
if [ -z "$3" ]; then echo "ERROR: missing ticket number; exiting" && return; fi
if ls | grep -w $1; then echo "$1 already exists: exiting" && return; fi
if git status | grep branch | cut -f4 -d" " | grep -w master
  then while true; do
    read -p "WARNING: you are currently in master. Continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
    esac
  done
fi
curl "http://ftp.drupal.org/files/projects/$1-$2.tar.gz" | tar xz
git add "$1"
git commit -am "$RA_INITIALS@Acq: Module Install, adding $1-$2. Ticket #$3."
}

# Git, Revert Module (git-mupdate-rev <module> <source version> <target version> <ticket number>)
function git-mupdate-rev {
if [ -z "$1" ]; then echo "ERROR: missing module name; exiting" && return; fi
if [ -z "$2" ]; then echo "ERROR: missing source version; exiting" && return; fi
if [ -z "$3" ]; then echo "ERROR: missing target version; exiting" && return; fi
if [ -z "$4" ]; then echo "ERROR: missing ticket number; exiting" && return; fi
if ls | grep -w $1; then echo "found $1"; else echo "$1 not found: exiting" && return; fi
if git status | grep branch | cut -f4 -d" " | grep -w master
  then while true; do
    read -p "WARNING: you are currently in master. Continue? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) return;;
        * ) echo "invalid response, try again";;
    esac
  done
fi
git rm -rf "$1"
curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
git add "$1"
git commit -am "$RA_INITIALS@Acq: Module Revert, reverting to $1-$3 from $2. Ticket #$4."
}

# Disables securepages on the given docroot/environment for all multisites.
function ra-disable-securepages {
  if [ -z "$1" ]; then
    echo "# Usage: ra-disable-securepages @docroot.env"
    return
  fi
  if [[ `aht $1` =~ "Could not find sitegroup" ]]; then
    echo "Could not find sitegroup or environment."
    return
  fi

  # A loop of all sites is used instead of drush @sites, due to issues with that alias when
  #  using aht.
  for site in `aht $1 sites | grep -v \>`; do
     aht $1 drush dis securepages -y -l "${site//[[:space:]]/}"
  done
}

# Downloads the stage_file_proxy module as root on the RA environment.
function ra-download-file-proxy {
  if [ -z "$1" ]; then
    echo "# Usage: ra-download-file-proxy @docroot"
    return
  fi
  server_command=`aht $1.ra`
  if [[ "$server_command" =~ "Could not find sitegroup" ]]; then
    echo "Could not find sitegroup or environment."
    return
  fi
  server=$(echo "$server_command" | grep active-db | sed -e 's/^ //' -e 's/\ .*//')
  docroot=$(echo "$1" | sed 's/@//')
  echo "About to download stage_file_proxy on $server for $docroot.ra..."
  read -p "Press enter to continue or CTRL+c to quit "
  ssh $server sudo drush dl stage_file_proxy --root=/var/www/html/$docroot.ra/docroot
}

# Removes the stage_file_proxy module the RA environment.
function ra-remove-file-proxy {
  if [ -z "$1" ]; then
    echo "# Usage: ra-remove-file-proxy @docroot"
    return
  fi
  server_command=`aht $1.ra`
  if [[ "$server_command" =~ "Could not find sitegroup" ]]; then
    echo "Could not find sitegroup or environment."
    return
  fi
  echo "About to remove the stage_file_proxy on $1.ra (using aht redeploy --force)..."
  read -p "Press enter to continue or CTRL+c to quit "
  aht $1.ra redeploy --force
}

# Enables and configures stage_file_proxy on the RA environment.
function ra-enable-file-proxy {
  if [ -z "$1" ]; then
    echo "# Usage: ra-enable-file-proxy @docroot"
    echo "# Requires site to be in live-development"
    return
  fi
  if [[ `aht $1.prod` =~ "Could not find sitegroup" ]]; then
    echo "Could not find sitegroup or environment."
    return
  fi

  sites=()
  domains=$(aht $1.prod domains | sed -e 's/[[:space:]]//' -e '/^$/d' | tr -d '\r')
  for domain in $(echo "$domains"); do
    conf_path=$(aht $1.prod drush ev 'print conf_path();' -l $domain)
    # either this isn't a working site, or we've already made an entry for this multisite
    if [[ "$conf_path" =~ "error" ||  "${sites[@]}" =~ "$conf_path" || "$conf_path" =~ "warning" ]]; then
      continue
    fi
    sites+=($conf_path)
    echo "Setting up stage_file_proxy for $conf_path multisite..."
    aht $1.ra drush vset stage_file_proxy_origin "http://$domain" -l $domain
    aht $1.ra drush vset stage_file_proxy_origin_dir "$conf_path/files" -l $domain
    aht $1.ra drush vset stage_file_proxy_use_imagecache_root TRUE -l $domain
    aht $1.ra drush en stage_file_proxy -y -l $domain
    echo ""
  done

  # Point default at the default Prod Acquia site. This is done because passing a bogus domain to
  #  Drush will just point to the default site, so we may have ended up with a bogus file proxy
  #  after the loop execution.
  domain=$(echo "$domains" | tail -1)
  aht $1.ra drush vset stage_file_proxy_origin "http://$domain" -l default
  aht $1.ra drush vset stage_file_proxy_origin_dir "sites/default/files" -l default
  aht $1.ra drush vset stage_file_proxy_use_imagecache_root TRUE -l default
  aht $1.ra drush en stage_file_proxy -y -l default
}

# Transfer all databases from one environment to another, or a range of databases
function ra-transfer-databases {
  if [ -z "$3" ]; then
    echo "# Usage: ra-transfer-databases @docroot sourceenv targetenv"
    echo "#  You can also supply a range of databases like so:"
    echo "#   ra-transfer-databases @docroot sourceenv targetenv <start>,<end>"
    echo "#  You can also add the --watch flag at the end of the command to watch for task completion."
    return
  fi

  if [ "$3" == "prod" ]; then
    echo "You cannot copy databases to Prod using this command. Use migrate-to for this."
    return
  fi

  if [[ `aht $1.$2` =~ "Could not find sitegroup" ]]; then
    echo "Could not find sitegroup or environment $1.$2"
    return
  elif [[ `aht $1.$3` =~ "Could not find sitegroup" ]]; then
    echo "Could not find sitegroup or environment $1.$3"
    return
  fi

  databases=$(aht $1.$2 dbs | grep -v '\[' | sed -e 's/[[:space:]]//' -e '/^$/d' -e 's/\ .*//')
  total=$(echo "$databases" | wc -l | sed 's/[[:space:]]*//')
  if [ -n "$4" ] && [ "$4" != "--watch" ]; then
    echo "About to copy $4 of $total databases from $2 to $3:"
    databases=$(echo "$databases" | sed -n "$4p")
  else
    echo "About to copy $total databases from $2 to $3:"
  fi
  echo "$databases"
  read -p "Press enter to continue or CTRL+c to quit..."
  for database in $(echo "$databases"); do
    aht $1.$2 dbs transfer $3 --database=$database
  done

  if [ "$5" == "--watch" ] || [ "$4" == "--watch" ]; then
    while :; do clear; aht $1.$3 tasks --limit=30; sleep 10; done
  else
    aht $1.$3 tasks
    echo "Run aht $1.$3 tasks to see when databases are finished copying."
  fi
}

# Create prefixed copies of an environment's domains onto RA environment
function ra-copy-domains {
  if [ -z "$1" ]; then
    echo "# Usage: ra-copy-domains @site.env <optional sed replacement>"
    return
  fi
  if [ -z "$2" ]; then 
    expression="s/^/ra./"
  else
    expression="$2"
  fi
  source_env=$1
  target_env=$(echo $1 | sed 's/\..*/.ra/')
  domains=$(aht $source_env domains | sed -e 's/[[:space:]]//' -e '/^$/d' | tr -d '\r' | grep -v '.acquia-sites.com')
  new_domains=""
  for domain in $(echo "$domains"); do
    new_domains+=$(echo $domain | sed $expression)
    new_domains+=$'\n'
  done
  echo "Current domains:"
  aht $target_env domains | sed -e 's/[[:space:]]//' -e '/^$/d' | tr -d '\r'
  echo
  echo "New domains:"
  echo "$new_domains"
  echo "About to add the above domains to $target_env"
  read -p "Press enter to continue or CTRL+c to quit..."
  for domain in $(echo "$new_domains"); do
    aht $target_env domains add $domain
  done
}
