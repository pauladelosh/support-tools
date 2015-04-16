<?php

namespace Acquia\Support\ToolsWrapper;

interface AhtWrapperExecutionContextInterface
{
    public function passthru($command, &$returnCode);

    public function exec($command, &$output, &$error, &$returnCode);
}
