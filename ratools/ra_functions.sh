############################################################################################
# remote admin bash functions
#
# based on George Cassie's script for updating modules
# modified by MGM for additional variables
# rewritten, cleaned up and core update scripts added by Matt Lavoie
#
# add the two following lines to ~/.bash_profile to include the scripts. MAKE SURE TO CHANGE "XYZ" TO YOUR INITIALS!!!
# RA_INITIALS="XYZ"
# source ~/<path-to-support-tools>/ratools/ra_functions.sh
#
# Instructions:
# 1.  cd to docroot for core updates, or the folder where the module lives for module updates.
# 2.  Pick your function name and enter variables as required:
#       Check site distribution and version (dvcheck @<docroot>.<environment>)"
#       RA Audit (ra-audit @<docroot>.<environment>)"
#       SVN, Core Update (svn-cupdate <distribution> <source version> <target version> <ticket number>)
#       SVN, Module Security Update (svn-mupdate-sec <module> <source version> <target version> <ticket number>)
#       SVN, Module Update (svn-mupdate <module> <source version> <target version> <ticket number>)
#       SVN, Add New Module (svn-mupdate-add <module> <version> <ticket number>)
#       SVN, Revert Module (svn-mupdate-rev <module> <source version> <target version> <ticket number>)
#       Git, Core Update (git-cupdate <distribution> <source version> <target version> <ticket number>)
#       Git, Module Security Update (git-mupdate-sec <module> <source version> <target version> <ticket number>)
#       Git, Module Update (git-mupdate <module> <source-version> <target version> <ticket number>)
#       Git, Add New Module (git-mupdate-add <module> <version> <ticket number>)
#       Git, Revert Module (git-mupdate-rev <module> <source version> <target version> <ticket number>)
# 3.  Example: cd to docroot/sites/all/modules/, git-mupdate-sec ctools 7.x-2.1 7.x-2.3 15066-3333
#
############################################################################################

# Help
function ra-help {
echo ""
echo "Remote Administration Scripts Help:"
echo ""
echo "1. cd to docroot for core updates, or the folder where the module lives for module updates:"
echo "2. pick your function name and enter variables as required:"
echo "      Check site distribution and version (dvcheck @<docroot>.<environment>)"
echo "      RA Update Audit (ra-audit @<docroot>.<environment> --raw (optional, shows common output on update checks))"
echo "      SVN, Core Update (svn-cupdate <distribution> <source version> <target version> <ticket number>)"
echo "      SVN, Module Security Update (svn-mupdate-sec <module> <source version> <target version> <ticket number>)"
echo "      SVN, Module Update (svn-mupdate <module> <source version> <target version> <ticket number>)"
echo "      SVN, Add New Module (svn-mupdate-add <module> <version> <ticket number>)"
echo "      SVN, Revert Module (svn-mupdate-rev <module> <source version> <target version> <ticket number>)"
echo "      Git, Core Update (git-cupdate <distribution> <source version> <target version> <ticket number>)"
echo "      Git, Module Security Update (git-mupdate-sec <module> <source version> <target version> <ticket number>)"
echo "      Git, Module Update (git-mupdate <module> <source-version> <target version> <ticket number>)"
echo "      Git, Add New Module (git-mupdate-add <module> <version> <ticket number>)"
echo "      Git, Revert Module (git-mupdate-rev <module> <source version> <target version> <ticket number>)"
echo "3. example: cd to docroot/sites/all/modules/, git-mupdate-sec ctools 7.x-2.1 7.x-2.3 15066-33333"
echo ""
}

# Check site distribution and version (dvcheck @<docroot>.<environment>)
function dvcheck { aht $1 drush php-eval 'echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . " " . VERSION . "\n";'; }

# RA Update Audit (ra-audit @<docroot>.<environment> --raw (optional, shows common output on update checks))
function ra-audit {
echo -e "\033[1;33;148m[ Distribution/Version and Profile Check ]\033[39m"
tput sgr0
aht $1 drush5 php-eval 'echo (function_exists("drupal_page_cache_header_external") ? "Pressflow" : "Drupal") . " " . VERSION . "\n";'
aht $1 drush5 vget install_profile
echo
echo -e "\033[1;33;148m[ Drush Status ]\033[39m"
tput sgr0
aht $1 drush5 status
echo
echo -e "\033[1;33;148m[ Current Deployed Code ]\033[39m"
tput sgr0
echo -n "dev:   "; aht `echo $1 | cut -f1 -d "."`.dev repo
echo -n "stage:   "; aht `echo $1 | cut -f1 -d "."`.test repo
echo -n "prod:   "; aht `echo $1 | cut -f1 -d "."`.prod repo
echo
echo -e "\033[1;33;148m[ Multisite Check ]\033[39m"
tput sgr0
aht $1 sites | grep -v \>
echo
echo -e "\033[1;33;148m[ Checking for Update Warnings/Errors ]\033[39m"
tput sgr0
rm -f ~/updates.tmp
for site in `aht $1 sites | grep -v \>`; do echo $site; aht $1 drush5 upc --pipe --uri=$site | tee -a ~/updates.tmp | if egrep 'warning|error'; then :; else echo -e "\033[0;32;148mnone\033[39m"; tput sgr0; fi; echo; done
############################################################################################
# define proactive updates here (seperate with pipes):
RA_PROACTIVE_UPDATES="acquia_connector|acquia_search|mollom|apachesolr|apachesolr_multisitesearch|search_api_acquia|search-api|entity"
############################################################################################
echo -e "\033[1;33;148m[ Available Drupal Core Updates ]\033[39m"
tput sgr0
egrep -w drupal ~/updates.tmp | sort | uniq
echo
echo -e "\033[1;33;148m[ Available Security Updates ]\033[39m"
tput sgr0
grep SECURITY-UPDATE-available ~/updates.tmp | sort | uniq
echo
echo -e "\033[1;33;148m[ Available Proactive Updates ]\033[39m"
tput sgr0
egrep -w $RA_PROACTIVE_UPDATES ~/updates.tmp | egrep -v 'Installed-version-not-supported|SECURITY-UPDATE-available' | sort | uniq
echo
echo -e "\033[1;33;148m[ Available Development Updates ]\033[39m"
tput sgr0
egrep '\-dev|\-unstable|\-alpha|\-beta|\-rc' ~/updates.tmp | egrep -v -w "'$RA_PROACTIVE_UPDATES|Installed-version-not-supported|SECURITY-UPDATE-available'" | sort | uniq
echo
echo -e "\033[1;33;148m[ All Available Updates ]\033[39m"
tput sgr0
egrep 'Update-available|SECURITY-UPDATE-available|Installed-version-not-supported' ~/updates.tmp | sort | uniq
echo
rm -f ~/updates.tmp
}

# Module Cache Check (module-cache-check <module> <version>)
# You can run this by hand if needed
# At some point, implement $RA_MODULE_CACHE_PATH
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
# check if we have all variables
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
# detection code to see if a valid patch exists (also helps sanitize the inputs further)
if ls  ~/Sites/releases/version-patches/$1 | grep -q $1-$2_to_$3.patch
  then echo -e "\033[0;32;148msuitable patch found: ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch\033[39m"
  else echo -e "\033[0;31;148mno suitable patch found (tried to find ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch): exiting\033[39m" && return
fi
tput sgr0
read -p "Press return to continue, or ctrl-c to stop..."
# run the patch, but check if we are in trunk or a docroot first
echo
echo -e "\033[1;33;148m[ running patch $1-$2_to_$3 ]\033[39m"
tput sgr0
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
# find and print out rej/orig files, then exit if any are found
echo
echo -e "\033[1;33;148m[ checking for reject/original files ]\033[39m"
tput sgr0
svn status --no-ignore | grep rej
svn status --no-ignore | grep orig
if svn status --no-ignore | grep -q rej
  then echo -e "\033[0;31;148mreject files found: exiting.\033[39m" && return
  else echo -e "\033[0;32;148mno reject files found\033[39m"
fi
if svn status --no-ignore | grep -q orig
  then echo -e "\033[0;31;148moriginal files found\033[39m" && return
  else echo -e "\033[0;32;148mno original files found\033[39m"
fi
tput sgr0
read -p "Press return to continue, or ctrl-c to stop..."
# remove version numbers
echo
echo -e "\033[1;33;148m[ removing version numbers ]\033[39m"
tput sgr0
~/Sites/releases/version-patches/scripts/rmv-versionnums-dpl.sh
read -p "Press return to continue, or ctrl-c to stop..."
# add changes to svn
echo
echo -e "\033[1;33;148m[ adding changes to svn ]\033[39m"
tput sgr0
svn status | grep '\?' | awk '{print $2}' | xargs svn add
svn status | grep '\!' | awk '{print $2}' | xargs svn rm
svn status --no-ignore
read -p "Press return to continue, or ctrl-c to stop..."
# commit
echo
echo -e "\033[1;33;148m[ commiting changes ]\033[39m"
tput sgr0
while true; do
    read -p "commit \"$RA_INITIALS@Acquia, Ticket #$4: Update from $1 $2 to $3.\" now? (y/n) " yn
    case $yn in
        [Yy]* ) svn commit -m "$RA_INITIALS@Acquia, Ticket #$4: Update from $1 $2 to $3."; echo -e "\033[0;32;148mchanges commited\033[39m"; break;;
        [Nn]* ) echo -e "\033[0;31;148mchanges not commited\033[39m"; break;;
        * ) echo "invalid response, try again";;
    esac
done
}

# SVN, Automatic Module Update (svn-auto-mupdate <module> <source version> <target version> <ticket number> --security (optional, marks as security update))
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
module-cache-check $1 $2
module-cache-check $1 $3
for modinfopath in `find . -name $1.info`
  do modpath=`dirname $(dirname $modinfopath)`
    if grep "version = \"$2\"" $modinfopath > /dev/null
      then while true; do read -p "Patch $1-$2 at $modpath to $1-$3? (y/n) " yn
          case $yn in
              [Yy]* ) cd $modpath
                diff $1 ~/Sites/releases/modules/$1/$2/$1
                if [ $? -ne 1 ]
                  then
                    svn rm "$1"
                    if [ "$5" = "--security" ]
                      then svn commit -m "$RA_INITIALS@Acquia, Ticket #$4: Module Security Update, cleanup, removing $1-$2 at $modpath."
                      else svn commit -m "$RA_INITIALS@Acquia, Ticket #$4: Module Update, cleanup, removing $1-$2 at $modpath."
                    fi
                    #curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
                    cp -R ~/Sites/releases/modules/$1/$3/$1 .
                    svn add --force "$1"
                    if [ "$5" = "--security" ]
                      then svn commit -m "$RA_INITIALS@Acquia, Ticket #$4: Module Security Update, updating $1-$3 at $modpath from $2."
                      else svn commit -m "$RA_INITIALS@Acquia, Ticket #$4: Module Update, updating $1-$3 at $modpath from $2."
                    fi
                  else echo "WARNING: $1 at $modpath is modified; skipping"
                fi
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

# SVN, Module Update (svn-mupdate <module> <source version> <target version> <ticket number>)
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
svn commit -m "$RA_INITIALS@Acquia, Ticket #$4: Module Update, cleanup, removing $1-$2 module."
curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
svn add --force "$1"
svn commit -m "$RA_INITIALS@Acquia, Ticket #$4: Module Update, updating $1-$3 from $2."
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
svn commit -m "$RA_INITIALS@Acquia, Ticket #$3: Module Install, adding $1-$2."
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
svn commit -m "$RA_INITIALS@Acquia, Ticket #$4: Module Revert, cleanup, removing $1-$2 module."
curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
svn add --force "$1"
svn commit -m "$RA_INITIALS@Acquia, Ticket #$4: Module Revert, reverting to $1-$3 from $2."
}

# Git, Core Update (git-cupdate <distribution> <source version> <target version> <ticket number>)
function git-cupdate {
# check if we have all variables
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
# detection code to see if a valid patch exists (also helps sanitize the inputs further)
if ls  ~/Sites/releases/version-patches/$1 | grep -q $1-$2_to_$3.patch
  then echo -e "\033[0;32;148msuitable patch found: ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch\033[39m"
  else echo -e "\033[0;31;148mno suitable patch found (tried to find ~/Sites/releases/version-patches/$1/$1-$2_to_$3.patch): exiting\033[39m" && return
fi
tput sgr0
read -p "Press return to continue, or ctrl-c to stop..."
# run the patch, but check if we are in master or a docroot first
echo
echo -e "\033[1;33;148m[ running patch $1-$2_to_$3 ]\033[39m"
tput sgr0
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
# find and print out rej/orig files, then exit if any are found
echo
echo -e "\033[1;33;148m[ checking for reject/original files ]\033[39m"
tput sgr0
git status | grep rej
git status | grep orig
if git status | grep -q rej
  then echo -e "\033[0;31;148mreject files found: exiting.\033[39m" && return
  else echo -e "\033[0;32;148mno reject files found\033[39m"
fi
if git status | grep -q orig
  then echo -e "\033[0;31;148moriginal files found\033[39m" && return
  else echo -e "\033[0;32;148mno original files found\033[39m"
fi
tput sgr0
read -p "Press return to continue, or ctrl-c to stop..."
# remove version numbers
echo
echo -e "\033[1;33;148m[ removing version numbers ]\033[39m"
tput sgr0
~/Sites/releases/version-patches/scripts/rmv-versionnums-dpl.sh
read -p "Press return to continue, or ctrl-c to stop..."
# add changes to git
echo
echo -e "\033[1;33;148m[ adding changes to git ]\033[39m"
tput sgr0
git add -A
git status
read -p "Press return to continue, or ctrl-c to stop..."
# commit
echo
echo -e "\033[1;33;148m[ commiting changes ]\033[39m"
tput sgr0
while true; do
    read -p "commit \"$RA_INITIALS@Acquia, Ticket #$4: Update from $1 $2 to $3.\" now? (y/n) " yn
    case $yn in
        [Yy]* ) git commit -m "$RA_INITIALS@Acquia, Ticket #$4: Update from $1 $2 to $3."; echo -e "\033[0;32;148mchanges commited\033[39m"; break;;
        [Nn]* ) echo -e "\033[0;31;148mchanges not commited\033[39m"; break;;
        * ) echo "invalid response, try again";;
    esac
done
}

# Git, Automatic Module Update (git-auto-mupdate <module> <source version> <target version> <ticket number> --security (optional, marks as security update))
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
module-cache-check $1 $2
module-cache-check $1 $3
for modinfopath in `find . -name $1.info`
  do modpath=`dirname $(dirname $modinfopath)`
    if grep "version = \"$2\"" $modinfopath > /dev/null
      then while true; do read -p "Patch $1-$2 at $modpath to $1-$3? (y/n) " yn
          case $yn in
              [Yy]* ) cd $modpath
                diff $1 ~/Sites/releases/modules/$1/$2/$1
                if [ $? -ne 1 ]
                  then
                    git rm -rf "$1"
                    #curl "http://ftp.drupal.org/files/projects/$1-$3.tar.gz" | tar xz
                    cp -R ~/Sites/releases/modules/$1/$3/$1 .
                    git add "$1"
                    if [ "$5" = "--security" ]
                      then git commit -am "$RA_INITIALS@Acquia, Ticket #$4: Module Security Update, updating $1-$3 at $modpath from $2."
                      else git commit -am "$RA_INITIALS@Acquia, Ticket #$4: Module Update, updating $1-$3 at $modpath from $2."
                    fi
                  else echo "WARNING: $1 at $modpath is modified; skipping"
                fi
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

# Git, Module Update (git-mupdate <module> <source version> <target version> <ticket number>)
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
git commit -am "$RA_INITIALS@Acquia, Ticket #$4: Module Update, updating $1-$3 from $2."
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
git commit -am "$RA_INITIALS@Acquia, Ticket #$3: Module Install, adding $1-$2."
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
git commit -am "$RA_INITIALS@Acquia, Ticket #$4: Module Revert, reverting to $1-$3 from $2."
}