ahtpanic-script
===============
Sniff-out-everything script that uncovers a lot of potential problems.

Note: you should give it a --uri argument if auditing a multisite install.

Usage:
    ahtpanic.sh sitename.env
    
Examples:

    ahtpanic.sh --skipbasic eluniverso.prod  # Skips some basic checks and goes directly to the good stuff.
    ahtpanic.sh --uri=www.eluniverso.com eluniverso.prod  # Give it a URI for drush
    ahtpanic.sh --mc eluniverso.prod  # Forces managed cloud, use --dc for devcloud

Basically, calls aht lots of times, runs a few scripts and commands, and highlights
any potential problems or warnings. For example:

* large amount of uncached vs. cached requests in varnish logs
* large amount of 4xx/5xx requests vs. total requests in apache logs
* large amount of skip-spawns
* known "bad" modules, "too many" modules, duplicate module code.
* top errors, top drupal-watchdog.log messages
* too many active procs vs limits
* "too large" logs, database table sizes, variable table.
* "too high" load average
* non-pressflow D6
* low disk space, low available total server memory
* non-cached views
* recent downtime as reported by Nagios

Some screenshots (terminal output):
* http://i.imgur.com/kv0mLY0.png
* http://i.imgur.com/oKvOMSB.png
