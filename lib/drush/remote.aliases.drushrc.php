<?php

// Site jonathan, environment prod
$aliases['jonathan.prod'] = array(
  'root' => '/var/www/prod/docroot',
  'uri' => 'conference.prod.un-nefer.net',
  'remote-host' => 'jonathan-web',
  'remote-user' => 'acquia',
  'ssh-options' => "-F {$_SERVER['HOME']}/.ssh/ra_config"
);

// Site jonathan, environment test
$aliases['jonathan.test'] = array(
  'root' => '/var/www/test/docroot',
  'uri' => 'conference.test.un-nefer.net',
  'remote-host' => 'jonathan-web',
  'remote-user' => 'acquia',
  'ssh-options' => "-F {$_SERVER['HOME']}/.ssh/ra_config"
);

// Site jonathan, environment dev
$aliases['jonathan.dev'] = array(
  'root' => '/var/www/dev/docroot',
  'uri' => 'conference.dev.un-nefer.net',
  'remote-host' => 'jonathan-web',
  'remote-user' => 'acquia',
  'ssh-options' => "-F {$_SERVER['HOME']}/.ssh/ra_config"
);

