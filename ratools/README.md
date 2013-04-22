RA Tools
===================
A collection of Remote Administration tools currently in use.  Generally in flux.  Lots of flux.

Core/Module Functions
--------------------
These are functions which allow for the rapid installation/updating of core and modules. They are located in the ra_functions.sh file. To take advantage of these scripts, add the two following lines to your .bash_profile. Make sure to change "XYZ" to your initials and change the path to your support tools repo:

RA_INITIALS="XYZ" <br>
source ~/{path-to-support-tools}/ratools/ra_functions.sh

To see what commands are available, and how to use them, just type "ra-help".

RA Scans
--------------------
Scripts and data files primarily for reporting, scanning Acquia hosted site cores and modules.
