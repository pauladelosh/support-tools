############################################################################################
# remote admin bash functions
#
# written by Matt Lavoie
# based on original scripts by George Cassie and Maria McDowell
#
# add the two following lines to ~/.bash_profile to include the scripts. MAKE SURE TO CHANGE "XYZ" TO YOUR INITIALS!!!
# RA_INITIALS="XYZ"
# source ~/<path-to-support-tools>/ratools/ra_functions.sh
#
# Instructions:
# 1.  cd to docroot for core/automatic-module updates, or the folder where the module lives for other module updates.
# 2.  Pick your function name and enter variables as required:
#       Check site distribution, version and install profile (dvpcheck @<docroot>.<environment>)
#       RA Audit (ra-audit @<docroot>.<environment> (add --updcmd=<git|svn>,<ticket number> to generate update commands))
#       SVN, Core Update (svn-cupdate <distribution> <source version> <target version> <ticket number>)
#       SVN, Automatic Module Update (svn-auto-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))
#       SVN, Module Update (svn-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))
#       SVN, Add New Module (svn-mupdate-add <module> <version> <ticket number>)
#       SVN, Revert Module (svn-mupdate-rev <module> <source version> <target version> <ticket number>)
#       Git, Core Update (git-cupdate <distribution> <source version> <target version> <ticket number>)
#       Git, Automatic Module Update (git-auto-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))
#       Git, Module Update (git-mupdate <module> <source-version> <target version> <ticket number> (add --security to mark as a security update))
#       Git, Add New Module (git-mupdate-add <module> <version> <ticket number>)
#       Git, Revert Module (git-mupdate-rev <module> <source version> <target version> <ticket number>)
# 3.  Example: cd to docroot/sites/all/modules/, git-mupdate-sec ctools 7.x-2.1 7.x-2.3 15066-3333
#
############################################################################################

# Help
alias ra-help='ratools-help'
function ratools-help {
echo ""
echo "Remote Administration Scripts Help:"
echo ""
echo "1. cd to docroot for core/automatic-module updates, or the folder where the module lives for other module updates."
echo "2. pick your function name and enter variables as required:"
echo "      Check site distribution, version and install profile (dvpcheck @<docroot>.<environment>)"
echo "      RA Update Audit (ra-audit @<docroot>.<environment> (add --updcmd=<git|svn>,<ticket number> to generate update commands))"
echo "      SVN, Core Update (svn-cupdate <distribution> <source version> <target version> <ticket number>)"
echo "      SVN, Automatic Module Update (svn-auto-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))"
echo "      SVN, Module Update (svn-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))"
echo "      SVN, Add New Module (svn-mupdate-add <module> <version> <ticket number>)"
echo "      SVN, Revert Module (svn-mupdate-rev <module> <source version> <target version> <ticket number>)"
echo "      Git, Core Update (git-cupdate <distribution> <source version> <target version> <ticket number>)"
echo "      Git, Automatic Module Update (git-auto-mupdate <module> <source version> <target version> <ticket number> (add --security to mark as a security update))"
echo "      Git, Module Update (git-mupdate <module> <source-version> <target version> <ticket number> (add --security to mark as a security update))"
echo "      Git, Add New Module (git-mupdate-add <module> <version> <ticket number>)"
echo "      Git, Revert Module (git-mupdate-rev <module> <source version> <target version> <ticket number>)"
echo "3. example: cd to docroot/sites/all/modules/, git-mupdate-sec ctools 7.x-2.1 7.x-2.3 15066-33333"
echo ""
}

# Check site distribution, version and install profile (dvpcheck @<docroot>.<environment>)
function dvpcheck { aht $1 drush5 php-eval 'echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . " " . VERSION . "\n";'; aht $1 drush5 vget install_profile; }

# RA Update Audit (ra-audit @<docroot>.<environment> (add --updcmd=<git|svn>,<ticket number> to generate update commands))
function ra-audit {
######################################################
# define proactive updates here (seperate with pipes):
RA_PROACTIVE_UPDATES="acquia_connector|acquia_search|mollom|apachesolr|apachesolr_multisitesearch|search_api_acquia|search_api|entity"
######################################################
if [[ "$2" == --updcmd=* ]]; then
  RA_AUDIT_VCS=`echo $2 | cut -f2 -d"=" | cut -f1 -d","`
  RA_AUDIT_TICKNUM=`echo $2 | cut -f2 -d"=" | cut -f2 -d","`
  if [ $RA_AUDIT_VCS != "git" ] && [ $RA_AUDIT_VCS != "svn" ]
    then echo "ERROR: invalid VCS specified (must be git/svn): exiting" && return
  fi
  echo -e "\033[1;33;148m[ Update Command Builder Enabled ]\033[39m"; tput sgr0
  echo "Version Control Type: $RA_AUDIT_VCS"
  echo "Ticket Number: $RA_AUDIT_TICKNUM"
  echo
fi
echo -e "\033[1;33;148m[ Distribution, Version and Install Profile Check ]\033[39m"; tput sgr0
aht $1 drush5 php-eval 'echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . " " . VERSION . "\n";'
aht $1 drush5 vget install_profile
echo
echo -e "\033[1;33;148m[ Drush Status (default site) ]\033[39m"; tput sgr0
aht $1 drush5 status
echo
echo -e "\033[1;33;148m[ Current Deployed Code ]\033[39m"; tput sgr0
echo -n "dev:   "; aht `echo $1 | cut -f1 -d "."`.dev repo
echo -n "stage:   "; aht `echo $1 | cut -f1 -d "."`.test repo
echo -n "prod:   "; aht `echo $1 | cut -f1 -d "."`.prod repo
echo
echo -e "\033[1;33;148m[ Multisite Check ]\033[39m"; tput sgr0
aht $1 sites | grep -v \>
echo
echo -e "\033[1;33;148m[ Checking for Update Warnings/Errors ]\033[39m"; tput sgr0
rm -f /tmp/ra-audit-updates.tmp
for site in `aht $1 sites | grep -v \>`; do echo $site; aht $1 drush5 upc --pipe --uri=$site | tee -a /tmp/ra-audit-updates.tmp | if egrep 'warning|error'; then :; else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0; fi; echo; done
echo -e "\033[1;33;148m[ Available Drupal Core Updates ]\033[39m"; tput sgr0
if grep -q -w drupal /tmp/ra-audit-updates.tmp
  then grep -w drupal /tmp/ra-audit-updates.tmp | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
echo
echo -e "\033[1;33;148m[ Available Security Updates ]\033[39m"; tput sgr0
if grep SECURITY-UPDATE-available /tmp/ra-audit-updates.tmp | grep -v -w -q drupal  
  then grep SECURITY-UPDATE-available /tmp/ra-audit-updates.tmp | grep -v -w drupal | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
if [[ "$2" == --updcmd=* ]]; then
echo "=========="
grep SECURITY-UPDATE-available /tmp/ra-audit-updates.tmp | grep -v -w drupal | sort | uniq | sed -e "s/^/$RA_AUDIT_VCS-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM --security/"
fi
echo
echo -e "\033[1;33;148m[ Available Proactive Updates ]\033[39m"; tput sgr0
if egrep -w $RA_PROACTIVE_UPDATES /tmp/ra-audit-updates.tmp | egrep -q -v 'Installed-version-not-supported|SECURITY-UPDATE-available'
  then egrep -w $RA_PROACTIVE_UPDATES /tmp/ra-audit-updates.tmp | egrep -v 'Installed-version-not-supported|SECURITY-UPDATE-available' | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
if [[ "$2" == --updcmd=* ]]; then
echo "=========="
egrep -w $RA_PROACTIVE_UPDATES /tmp/ra-audit-updates.tmp | egrep -v 'Installed-version-not-supported|SECURITY-UPDATE-available' | sort | uniq | sed -e "s/^/$RA_AUDIT_VCS-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM/"
fi
echo
echo -e "\033[1;33;148m[ Available Development Updates ]\033[39m"; tput sgr0
if egrep '\-dev|\-unstable|\-alpha|\-beta|\-rc' /tmp/ra-audit-updates.tmp | egrep -q -v -w "'$RA_PROACTIVE_UPDATES|Installed-version-not-supported|SECURITY-UPDATE-available'"
  then egrep '\-dev|\-unstable|\-alpha|\-beta|\-rc' /tmp/ra-audit-updates.tmp | egrep -v -w "'$RA_PROACTIVE_UPDATES|Installed-version-not-supported|SECURITY-UPDATE-available'" | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
if [[ "$2" == --updcmd=* ]]; then
echo "=========="
egrep '\-dev|\-unstable|\-alpha|\-beta|\-rc' /tmp/ra-audit-updates.tmp | egrep -v -w "'$RA_PROACTIVE_UPDATES|Installed-version-not-supported|SECURITY-UPDATE-available'" | sort | uniq | sed -e "s/^/$RA_AUDIT_VCS-auto-mupdate /" -e "s/[^\ ]*$/$RA_AUDIT_TICKNUM/"
fi
echo
echo -e "\033[1;33;148m[ All Available Updates ]\033[39m"; tput sgr0
if egrep -q 'Update-available|SECURITY-UPDATE-available' /tmp/ra-audit-updates.tmp
  then egrep 'Update-available|SECURITY-UPDATE-available' /tmp/ra-audit-updates.tmp | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
echo
echo -e "\033[1;33;148m[ Unsupported/Out-of-Scope Updates (do not perform) ]\033[39m"; tput sgr0
if grep -q 'Installed-version-not-supported' /tmp/ra-audit-updates.tmp
  then grep 'Installed-version-not-supported' /tmp/ra-audit-updates.tmp | sort | uniq
  else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0;
fi
echo
rm -f /tmp/ra-audit-updates.tmp
}

# Module Cache Check (module-cache-check <module> <version>)
# Need to exclude dev modules. They are not unique versions and thus will never be updated.
function module-cache-check {
if [ -d ~/Sites/releases/modules/$1/$2 ]
  then
    echo "module $1-$2 found in cache"
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
  else echo -e "\033[0;32;148msource version:  $3\033[39m"
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
if echo ${PWD##*/} | grep docroot
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
while svn status --no-ignore | egrep -q '.orig|.rej'; do 
  svn status --no-ignore | egrep '.rej|.orig'
  echo -e "\033[0;31;148mERROR: original/reject files found! open a new window, resolve all issues, and remove any orig/rej files.\033[39m"; tput sgr0
  echo "to change into repository: cd `pwd`"
  echo "to locate all reject/original files: svn status --no-ignore | egrep '.orig|.rej'"
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
echo "currently on svn branch `svn info | grep URL | cut -f2 -d" " | xargs basename`"
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
#module-cache-check $1 $2
#module-cache-check $1 $3
if [ $1 = "acquia_connector" ]; then modname=acquia_agent
  elif [ $1 = "google_analytics" ]; then modname=googleanalytics
  elif [ $1 = "features_extra" ]; then modname=fe_block
  else modname=$1
fi
for modinfopath in `find . -name $modname.info`
  do
    if [ $modname = acquia_agent ]
      then modpath=`dirname $(dirname $(dirname $modinfopath))`
      else modpath=`dirname $(dirname $modinfopath)`
    fi
    if grep "version = \"$2\"" $modinfopath > /dev/null
      then while true; do read -p "Update $1-$2 at $modpath to $1-$3? (y/n) " yn
          case $yn in
              [Yy]* ) cd $modpath
                #diff $1 ~/Sites/releases/modules/$1/$2/$1
                #if [ $? -ne 1 ]
                  #then
                    svn rm "$1"
                    if [ "$5" = "--security" ]
                      then svn commit -m "$RA_INITIALS@Acq: Module Security Update, cleanup, removing $1-$2 at $modpath. Ticket #$4."
                      else svn commit -m "$RA_INITIALS@Acq: Module Update, cleanup, removing $1-$2 at $modpath. Ticket #$4."
                    fi
                    curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
                    #cp -R ~/Sites/releases/modules/$1/$3/$1 .
                    svn add --force "$1"
                    if [ "$5" = "--security" ]
                      then svn commit -m "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                      else svn commit -m "$RA_INITIALS@Acq: Module Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                    fi
                  #else echo "WARNING: $1 at $modpath is modified; skipping"
                #fi
                cd $homepath
                break;;
              [Nn]* ) break;;
              * ) echo "invalid response, try again";;
            esac
           done
      else echo "WARNING: $1 at $modpath is not version $2; skipping"
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
  then svn commit -m "$RA_INITIALS@Acq: Module Security Update, cleanup, removing $1-$2 at $modpath. Ticket #$4."
  else svn commit -m "$RA_INITIALS@Acq: Module Update, cleanup, removing $1-$2 at $modpath. Ticket #$4."
fi
curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
svn add --force "$1"
if [ "$5" = "--security" ]
  then svn commit -m "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 at $modpath from $2. Ticket #$4."
  else svn commit -m "$RA_INITIALS@Acq: Module Update, updating $1-$3 at $modpath from $2. Ticket #$4."
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
  else echo -e "\033[0;32;148msource version:  $3\033[39m"
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
if echo ${PWD##*/} | grep docroot
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
while git status | egrep -q '.orig|.rej'; do 
  git status | egrep '.rej|.orig'
  echo -e "\033[0;31;148mERROR: original/reject files found! open a new window, resolve all issues, and remove any orig/rej files.\033[39m"; tput sgr0
  echo "to change into repository: cd `pwd`"
  echo "to locate all reject/original files: git status| egrep '.orig|.rej'"
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
echo "currently on git branch `git status | grep branch | cut -f4 -d" "`"
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
#module-cache-check $1 $2
#module-cache-check $1 $3
if [ $1 = "acquia_connector" ]; then modname=acquia_agent
  elif [ $1 = "google_analytics" ]; then modname=googleanalytics
  elif [ $1 = "features_extra" ]; then modname=fe_block
  else modname=$1
fi
for modinfopath in `find . -name $modname.info`
  do
    if [ $modname = acquia_agent ]
      then modpath=`dirname $(dirname $(dirname $modinfopath))`
      else modpath=`dirname $(dirname $modinfopath)`
    fi
    if grep "version = \"$2\"" $modinfopath > /dev/null
      then while true; do read -p "Update $1-$2 at $modpath to $1-$3? (y/n) " yn
          case $yn in
              [Yy]* ) cd $modpath
                #diff $1 ~/Sites/releases/modules/$1/$2/$1
                #if [ $? -ne 1 ]
                  #then
                    git rm -rf "$1"
                    curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
                    #cp -R ~/Sites/releases/modules/$1/$3/$1 .
                    git add "$1"
                    if [ "$5" = "--security" ]
                      then git commit -am "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                      else git commit -am "$RA_INITIALS@Acq: Module Update, updating $1-$3 at $modpath from $2. Ticket #$4."
                    fi
                  #else echo "WARNING: $1 at $modpath is modified; skipping"
                #fi
                cd $homepath
                break;;
              [Nn]* ) break;;
              * ) echo "invalid response, try again";;
            esac
           done
      else echo "WARNING: $1 at $modpath is not version $2; skipping"
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
  then git commit -am "$RA_INITIALS@Acq: Module Security Update, updating $1-$3 at $modpath from $2. Ticket #$4."
  else git commit -am "$RA_INITIALS@Acq: Module Update, updating $1-$3 at $modpath from $2. Ticket #$4."
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

# SVN, Initialize Repository
# Usage: svn-init-repo @<docroot>.<environment> <source_tag> <target_branch>
#        svn-init-repo @<docroot>.<environment> <target_branch> 
function svn-init-repo {
    if [ $# -lt 2 ]
      then echo "Missing docroot" && return
    fi
    #split $1 into three distinct variables (@site.env => @site, site, and env)
    base=${1%.*}
    docroot=${base#@*}
    acqenv=${1#*.}
    if [ -d ./$docroot ]; then
        echo "Error: Directory $docroot already exists"
        return
    fi
    repo="$(aht $1 repo)"
    if [[ $repo =~ "live development" ]]; then
        repo=$(echo "$repo" | grep svn)
    elif [[ $repo =~ "Could not find sitegroup or environment" ]]; then
        echo "Could not find sitegroup or environment." && return;
    fi
    url=$(echo $repo | tr -d '\r')
    baseurl=$(echo "$url" | sed "s/$docroot\/.*/$docroot/")
    source_tag=$(echo "$url" | sed "s/.*$docroot\///")
    if [ $# -eq 2 ]; then
      source_url=$url
      target_branch=$2
    else
      source_url=$baseurl/$2
      target_branch=$3
    fi
    mkdir $docroot && cd $docroot
    svn checkout --username=$SVN_USERNAME $baseurl/trunk
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

# GIT, Initialize Repository 
# Usage: git-init-repo @<docroot>.<environment> <source_tag> <target_branch>
#        git-init-repo @<docroot>.<environment> <target_branch> 
function git-init-repo {
    if [ $# -lt 2 ]
      then echo "Missing docroot" && return
    fi
    #split $1 into three distinct variables (@site.env => @site, site, and env)
    base=${1%.*}
    docroot=${base#@*}
    acqenv=${1#*.}
    if [ -d ./$docroot ]; then
        echo "Error: Directory $docroot already exists"
        return
    fi
    mkdir $docroot && cd $docroot
    repo="$(aht $1 repo)"
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