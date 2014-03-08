RA Scans
===================

Scripts which utilize AH Tools to scan Acquia hosted clients for both core and module information.

USAGE
-----------
Run the script from the command line.

Sources:
Most files below either use one of two source files: sources_sites.csv or source_sites_wmg.csv.  These are simple data files with the following format:

docroot env multisite UUID
docroot env multisite UUID

Where:
docroot = acquia sitename (etr, etrsvclrng)
env = acqui environment (prod, test or dev)
multisite = name of multisite folder (default, americorpsconnect.org, nationalserviceresources.org)
UUID = subscription UUID in CCI.  This is not required.

These source files are created by a query against a myql DB (see mysql-ordered: Get Current Sites list).

Results:
Each script writes its output as comma delimitted data into the results file of a corresponding name.  This data is mean to be imported into a mysql database (see rascans_structure.mysql).

Core Scans
-----------
* core.sh: runs 'drush status drupal-version --pipe' against source_sites.csv.
* core_wmg.sh: runs 'ssh sudo -u warnermusic drush status drupal-version --pipe' against source_sites_wmg.csv.

Module Scans
-----------
Modules scans only work on sites that have the Update Module enabled.  The --uri parameter allows multisites to be individuall scanned.

* upc.sh: runs 'drush upc --pipe' against source_sites.csv.
* upc_wmg.sh: runs 'ssh sudo -u warnermusic  drush upc --pipe' against source_sites_wmg.csv.
* upc_sec.sh: runs 'drush upc --pipe  --security-only' against source_sites.csv.
* modcheck.sh: runs 'drush pmi update | grep Status' against source_sites.csv.  This scan checks for specific modules.  The module must be changed directly in the function ('update' to 'views' or 'acquia_connector')

Mysql
-----------
Currently, all results can be imported into a mysql DB which allows queries to be run on collected data.
* rascans_structure.mysql: creates empty DB.
* mysql-ordered.sql: ordered list of queries to create weekly RA reports.
