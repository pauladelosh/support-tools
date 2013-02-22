RA Tools
===================

A collection of Remote Administration tools currently in use.  Generally in flux.  Lots of flux.

Functions in .bash_profile
===================
The file 'bash_profile-mupdates' contains functions which allow for the rapid installation/update of modules.  To install:
# Copy the contents of the file into your .bash_profile.
# Change the initials "MGM" to your own for accurate commit messages.

In order to use the functions, do the following:

# cd to folder where the module lives (sites/all/modules)
# pick your function name based on VCStype-mupdate-updatetype (message varies a bit for each): [git/svn]-mupdate[-sec/add/rev/blank]
# Enter variables, in this order: module module-version# ticket#

Example: git-mupdate-sec ctools 7.x-2.3 15066-333333.  This will update the ctools module to 7.x-2.3, and add a message which includes a security note and the ticket number 15066-333333.

RA Scans
--------------------
Scripts and data files primarily for reporting, scanning Acquia hosted site cores and modules.
