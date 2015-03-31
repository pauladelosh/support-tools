RA Tools
===================
A collection of Remote Administration tools currently in use.  Generally in flux.  Lots of flux.

Installation
--------------------
1.  Install Core Patches repo: ```git clone git@github.com:acquiacat/Drupal-Core-Git-Patches.git```  Note the path for 'RA_PATCHES' below.
2.  Add the lines below to your .bash_profile
3.  Change "XYZ" to your initials
4.  Change the path to your local checkout of this repository
```
RA_INITIALS="XYZ"
SVN_USERNAME="acquia_ahsupport_username"
SVN_PASSWORD="verysecureopspassword123"
RA_PATCHES= "/<full-path-to-drupal/patch/files" # No trailing backslash!  No relative paths!
source ~/{path-to-support-tools}/ratools/ra_functions.sh
```

Note that with every update to the ra_functions.sh file, you will need to source .bash_profile in any terminal window currently open.

Core/Module Update Functions
--------------------
These are functions which allow for the rapid installation/updating of core and modules. They are located in the ra_functions.sh file.

To see what commands are available, and how to use them, just type "ra-help".

Instructions:
1. The repo to be updated must be checked out locally.
2. Core updates and ra-auto-module updates may be run from the docroot level.
3. Dev, module additions need to be run from within modules folder.
4. Enter function name and enter variables as required

Functions: 
Check site distribution and version (dvcheck @<docroot>.<environment>)
* RA Audit (ra-audit @<docroot>.<environment>)
* SVN, Core Update (svn-cupdate <distribution> <source version> <target version> <ticket number>)
* SVN, Module Security Update (svn-mupdate-sec <module> <source version> <target version> <ticket number>)
* SVN, Module Update (svn-mupdate <module> <source version> <target version> <ticket number>)
* SVN, Add New Module (svn-mupdate-add <module> <version> <ticket number>)
* SVN, Revert Module (svn-mupdate-rev <module> <source version> <target version> <ticket number>)
* Git, Core Update (git-cupdate <distribution> <source version> <target version> <ticket number>)
* Git, Module Security Update (git-mupdate-sec <module> <source version> <target version> <ticket number>)
* Git, Module Update (git-mupdate <module> <source-version> <target version> <ticket number>)
* Git, Add New Module (git-mupdate-add <module> <version> <ticket number>)
* Git, Revert Module (git-mupdate-rev <module> <source version> <target version> <ticket number>)

Example: cd to docroot/sites/all/modules/, git-mupdate-sec ctools 7.x-2.1 7.x-2.3 15066-3333

RA Scans
--------------------
Scripts and data files primarily for reporting, scanning Acquia hosted site cores and modules.
