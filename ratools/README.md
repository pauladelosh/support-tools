RA Tools
===================
A collection of Remote Administration tools currently in use.  Generally in flux.  Lots of flux.

Core/Module Update Functions
--------------------
These are functions which allow for the rapid installation/updating of core and modules. They are located in the ra_functions.sh file. To take advantage of these scripts, add the two following lines to your .bash_profile. Make sure to change "XYZ" to your initials and change the path to your support tools repo:

RA_INITIALS="XYZ" <br>
source ~/{path-to-support-tools}/ratools/ra_functions.sh

To see what commands are available, and how to use them, just type "ra-help".

Instructions:
1.  cd to docroot for core updates, or the folder where the module lives for module updates.
2.  Enter function name and enter variables as required:
      Check site distribution and version (dvcheck @<docroot>.<environment>)"
      RA Audit (ra-audit @<docroot>.<environment>)"
      SVN, Core Update (svn-cupdate <distribution> <source version> <target version> <ticket number>)
      SVN, Module Security Update (svn-mupdate-sec <module> <source version> <target version> <ticket number>)
      SVN, Module Update (svn-mupdate <module> <source version> <target version> <ticket number>)
      SVN, Add New Module (svn-mupdate-add <module> <version> <ticket number>)
      SVN, Revert Module (svn-mupdate-rev <module> <source version> <target version> <ticket number>)
      Git, Core Update (git-cupdate <distribution> <source version> <target version> <ticket number>)
      Git, Module Security Update (git-mupdate-sec <module> <source version> <target version> <ticket number>)
      Git, Module Update (git-mupdate <module> <source-version> <target version> <ticket number>)
      Git, Add New Module (git-mupdate-add <module> <version> <ticket number>)
      Git, Revert Module (git-mupdate-rev <module> <source version> <target version> <ticket number>)
3.  Example: cd to docroot/sites/all/modules/, git-mupdate-sec ctools 7.x-2.1 7.x-2.3 15066-3333

RA Scans
--------------------
Scripts and data files primarily for reporting, scanning Acquia hosted site cores and modules.
