#!/usr/bin/env php
<?php
// Remove ourselves from arg list
array_shift($argv);

// Split the arg into docroot and env
list($docroot, $env) = explode('.', array_shift($argv));

$docroot = trim($docroot, '@');

if (empty($docroot)) {
  exit(0);
}

$cmd = "aht @{$docroot}.{$env} --json";

$json = exec($cmd);
$response = json_decode($json);

foreach ($response as $myst => $envs) {
  foreach ($envs as $zones) {
    foreach ($zones as $servers) {
      foreach ($servers as $hostname => $serverdata) {
        $type = $serverdata->type[0]; 
        switch ($type) {
          case 'bal':
            $bals[] = $hostname;
            break;
          case 'web': 
            $webs[] = $hostname;
            break;
          case 'db':
            $dbs[] = $hostname;
            break;
          }
        
      }
    }
  }
}

$filepath = __DIR__ . '/templates/loadTestDashboard.applescript';

ob_start();
include($filepath);
$output = ob_get_clean();

$output_filepath = __DIR__ . '/applescript.applescript';
file_put_contents($output_filepath, $output);

$cmd = "osascript {$output_filepath}";
exec($cmd);

?>
