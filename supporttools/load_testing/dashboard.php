#!/usr/bin/env php
<?php
// Remove ourselves from arg list
array_shift($argv);

list($docroot, $env) = explode('.', array_shift($argv));

$template_filename = count($argv) ? array_shift($argv) : 'loadTestDashboard.applescript';

$docroot = trim($docroot, '@');

if (empty($docroot)) {
  echo "Usage: dashboard.php @<docroot>.<env> [--template=<filename>]\n";
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

$filepath = __DIR__ . '/templates/' . $template_filename;

ob_start();
include($filepath);
$output = ob_get_clean();

$output_filepath = __DIR__ . '/applescript.applescript';
file_put_contents($output_filepath, $output);

$cmd = "osascript {$output_filepath}";
exec($cmd);

?>
