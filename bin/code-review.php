#!/usr/bin/env php
<?php

date_default_timezone_set('UTC');

require __DIR__.'/../vendor/autoload.php';

$application = new \Acquia\Support\ToolsWrapper\SoloApplication(
    new \Acquia\Support\ToolsWrapper\Command\CodeReviewCommand('code-review')
);
$application->run();
