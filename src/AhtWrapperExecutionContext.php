<?php

namespace Acquia\Support\ToolsWrapper;

final class AhtWrapperExecutionContext implements AhtWrapperExecutionContextInterface
{
    public function passthru($command, &$returnCode)
    {
        passthru($command, $returnCode);
    }

    public function exec($command, &$output, &$error, &$returnCode)
    {
        $descriptorSpec = array(
            1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
            2 => array("pipe", "w"),  // stderr is a pipe that the child will write to
        );
        $process = proc_open($command, $descriptorSpec, $pipes);
        if (is_resource($process)) {
            $output .= trim(stream_get_contents($pipes[1]));
            $error .= trim(stream_get_contents($pipes[2]));
            fclose($pipes[1]);
            fclose($pipes[2]);
            $returnCode = proc_close($process);
        } else {
            $returnCode = -1;
        }
        return $returnCode;
    }
}
