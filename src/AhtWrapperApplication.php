<?php

namespace Acquia\Support\ToolsWrapper;

use Symfony\Component\Console\Application;
use Symfony\Component\Console\Formatter\OutputFormatterStyle;
use Symfony\Component\Console\Output\ConsoleOutput;
use Symfony\Component\Console\Output\ConsoleOutputInterface;
use Symfony\Component\Console\Output\OutputInterface;

final class AhtWrapperApplication extends Application
{
    /** @var AhtWrapperExecutionContextInterface $executionContext An object to handle the passthru() */
    private $executionContext = null;

    /** @var string $bastionName The name of the server to connect through */
    private $bastionName = 'bastion';

    /** @var string $bastionName The name of the server to connect through */
    private $bastionActual = 'bastion';

    /** @var string $sshConfig The name of the SSH Config to connect with */
    private $sshConfig = null;

    /** @var string $ahtRealms */
    private $ahtRealms = null;

    /** @var string $ahtPath */
    private $ahtPath = 'aht/prod';

    /** @var array $arguments The array of arguments passed to the executable which invoked this class */
    private $arguments = [];

    /** @var string $originalCommand The executable which invoked this class */
    private $originalCommand = 'aht';

    /** @var bool $doAutocomplete If true, will make an tab-completion request */
    private $doAutocomplete = false;

    /** @var bool $doCache If true, will cache the request */
    private $doCache = false;

    /** @var bool $doCacheClear If true, will clear the request cache */
    private $doCacheClear = false;

    /** @var bool $stagesSet If true, the arguments included --stages=<something> (or similar arg) */
    private $stagesSet = false;

    /** @var bool $debugMode If true, the arguments included --debug or -vvv */
    private $debugMode = false;

    /** @var OutputInterface $output The console output object */
    private $output = null;

    private $pid = 0;

    /** @var array $debugMsgQueue We queue messages until we know if debugging is needed */
    private $debugMsgQueue = [];

    private $sshOptions = null;

    private $supportToolsVersion = 'dev';

    public function __construct(AhtWrapperExecutionContextInterface $executionContext, OutputInterface $output = null)
    {
        $this->pid = getmypid();
        $this->executionContext = $executionContext;
        if (null === $output) {
            $output = new ConsoleOutput();
            $this->setupOutputFormatting($output);
        }
        $this->output = $output;
        $this->setBastionNameFromEnv('AHT_BASTION');
        $this->setSshConfigFromEnv('AH_SSH_CONFIG');
        $this->setAhtRealmsFromEnv('AHSTAGES');
        $this->setAhtPathFromEnv('AHTPATH');
        $this->getGitVersion();
        $this->getPhpVersion();
        $this->setSupportToolsVersion();
    }

    public function runAht($arguments)
    {
        try {
            $this->processArguments($arguments);
            $this->cacheHandler();
            if (($exitCode = $this->checkSshConfig()) !== 0) {
                $connections = $this->showConnectedBastions();
                $bastionInfo = '';
                if ($this->bastionName != $this->bastionActual) {
                    $bastionInfo = sprintf(
                        "\n * The name 'bastion' is currently an alias of '%s'",
                        $this->bastionActual
                    );
                }
                throw new \RuntimeException(
                    sprintf(
                        "You do not have an open connection to the server '%s'!%s\n%s\n%s\n%s",
                        $this->bastionName,
                        $bastionInfo,
                        " * AHT_BASTION=" . getenv('AHT_BASTION'),
                        " * AH_SSH_CONFIG=" . getenv('AH_SSH_CONFIG'),
                        $connections
                    )
                );
            }
            $command = $this->buildSshCommand();
            if ($this->doAutocomplete) {
                // We use exec here to strip the extra ^M off
                $this->executionContext->exec($command, $output, $error, $returnCode);
                foreach (preg_split('#[\r\n]+#', $output) as $completion) {
                    echo "{$completion}\n";
                }
            }
            if (!$this->doAutocomplete) {
                $this->executionContext->passthru($command, $returnCode);
            }
        } catch (\Exception $e) {
            if ($this->output instanceof ConsoleOutputInterface) {
                $this->renderException($e, $this->output->getErrorOutput());
            } else {
                $this->renderException($e, $this->output);
            }
            $exitCode = $e->getCode();
            if (is_numeric($exitCode)) {
                $exitCode = (int) $exitCode;
                if (0 === $exitCode) {
                    $exitCode = 1;
                }
            } else {
                $exitCode = 1;
            }
        }

        return $exitCode;
    }

    protected function setupOutputFormatting(OutputInterface $output)
    {
        $fail = new OutputFormatterStyle('red', null, ['bold']);
        $debug = new OutputFormatterStyle('yellow');

        $output->getFormatter()->setStyle('fail', $fail);
        $output->getFormatter()->setStyle('debug', $debug);

        return $output;
    }

    private function setBastionNameFromEnv($key)
    {
        $value = getenv($key);
        if (!empty($value)) {
            $this->bastionName = $value;
        }
        $this->debugMsg(sprintf('%s="%s"', $key, $this->bastionName));
    }

    private function setSshConfigFromEnv($key)
    {
        $value = getenv($key);
        if (!empty($value)) {
            $this->sshConfig = $value;
        }
        $this->debugMsg(sprintf('%s="%s"', $key, $this->sshConfig));
    }

    private function setAhtRealmsFromEnv($key)
    {
        $value = getenv($key);
        if (!empty($value)) {
            $this->ahtRealms = $value;
        }
        $this->debugMsg(sprintf('%s="%s"', $key, $this->ahtRealms));
    }

    private function setAhtPathFromEnv($key)
    {
        $value = getenv($key);
        if (!empty($value)) {
            $this->ahtPath = (strtolower($value) == 'test') ? 'aht/test' : $value;
        }
        $this->debugMsg(sprintf('%s="%s"', $key, $this->ahtPath));
    }

    private function processArguments($arguments)
    {
        $this->originalCommand = array_shift($arguments);

        $sawNonOption = false;

        foreach ($arguments as $arg_key => &$tmp_arg) {
            if ($tmp_arg[0] != '-') {
                $sawNonOption = true;
            }
            if (strstr($tmp_arg, '--stages') || in_array($tmp_arg, ['--ac', '--ace', '--dc', '--mc', '--network'])) {
                $this->stagesSet = true;
            }
            if ($tmp_arg == '--cache') {
                $this->doCache = true;
                unset($arguments[$arg_key]);
            } else if ($tmp_arg == '--cache-clear') {
                $this->doCache = true;
                $this->doCacheClear = true;
                unset($arguments[$arg_key]);
            } else if ($tmp_arg == '--autocomplete') {
                $this->doCache = true;
                $this->doAutocomplete = true;
                $arguments[$arg_key] = 'meta:tab-completion';
            } else if (preg_match('|\s|', $tmp_arg)) {
                $tmp_arg = escapeshellarg(escapeshellarg($tmp_arg));
            } else if (strpos($tmp_arg, '&') !== false) {
                // Handle valid arguments that contain ampersands (e.g. URLs).
                $tmp_arg = escapeshellarg(escapeshellarg($tmp_arg));
            }
            if (!$sawNonOption && in_array($tmp_arg, ['-vvv', '--debug'])) {
                $this->debugMode = true;
                $this->output->setVerbosity(OutputInterface::VERBOSITY_DEBUG);
                foreach ($this->debugMsgQueue as $msg) {
                    $this->debugMsg($msg, '');
                }
            }
        }

        $this->arguments = $arguments;
    }

    private function debugMsg($message, $prefix = null)
    {
        if ($prefix === null) {
            $prefix = sprintf("aht[%s]: ", 'local');
        }
        if ($this->output->isDebug()) {
            foreach (preg_split('#[\r\n]+#', $message) as $line) {
                $this->output->writeln(sprintf("<debug>%s%s</debug>", $prefix, $line));
            }
        }
        if (!$this->output->isDebug()) {
            foreach (preg_split('#[\r\n]+#', $message) as $line) {
                $this->debugMsgQueue[] = sprintf("%s%s", $prefix, $line);
            }
        }
    }

    /**
     * This might be cruft?
     */
    private function cacheHandler()
    {
        if ($this->doCache) {
            $result_dir = $_SERVER['HOME'] . '/.ah';
            @mkdir($result_dir, 0777, true);

            $key = sha1(json_encode(['aht', $this->arguments]));
            $result_file = $result_dir . '/ah_' . $key;

            if ($this->doCacheClear) {
                @unlink($result_file);
                $this->debugMsg("<info>removed cache:</info> {$result_file}");
            }

            if (file_exists($result_file) && filemtime($result_file) < (time() + 86400)) {
                $this->debugMsg("<info>returning result from cache:</info> {$result_file}");
                echo file_get_contents($result_file);
                exit;
            }
        }
    }

    private function buildSshCommand()
    {
        $combinedArgv = array_merge($this->getAhtOptions(), $this->arguments);

        $command = sprintf(
            "ssh %s %s /vol/ebs1/ahsupport/%s/ahtools --encoded-argv=%s",
            implode(' ', $this->getSshOptions()),
            $this->bastionName,
            $this->ahtPath,
            base64_encode(json_encode($combinedArgv))
        );
        $this->debugMsg("<info>wrapper command:</info> {$command}");

        return $command;
    }

    private function getSshOptions()
    {
        if ($this->sshOptions === null) {
            $this->sshOptions = ['-tq'];

            // Pass SSH Config to ssh and to AHT
            if ($this->sshConfig) {
                $this->sshOptions[] = "-F {$this->sshConfig}";
            }
        }
        return $this->sshOptions;
    }

    private function getAhtOptions()
    {
        $ahtOptions = [];

        if (!$this->stagesSet && !empty($this->ahtRealms)) {
            $ahtOptions[] = "--stages={$this->ahtRealms}";
        }

        // Pass SSH Config to ssh and to AHT
        if ($this->sshConfig) {
            $sshOptions[] = "-F {$this->sshConfig}";
            $ahtOptions[] = "--client-ssh-config={$this->sshConfig}";
        }

        // Add client-version to options
        if (preg_match('/^[a-z0-9.+-]+$/', $this->supportToolsVersion, $matches)) {
            $clientToolsVersion = $matches[0];
            if ($ppid = posix_getppid()) {
                $pscript = exec("ps -o args -p {$ppid} | tail -n1 | awk '{print $2}'");
                if ($pscript && $invoker = basename($pscript)) {
                    $clientToolsVersion  = "{$clientToolsVersion}_{$invoker}";
                }
            }
            $ahtOptions[] = "--client-tools-version={$clientToolsVersion}";
        }

        if ($this->doAutocomplete) {
            $contents = 'aht';
            if (getenv('COMP_LINE')) {
                $contents = getenv('COMP_LINE');
            } elseif (getenv('CMDLINE_CONTENTS')) {
                $contents = getenv('CMDLINE_CONTENTS');
            }
            $contents = urlencode($contents);
            $ahtOptions[] = "--cmdline-contents=\"{$contents}\"";

            $index = 4;
            if (getenv('COMP_POINT')) {
                $index = getenv('COMP_POINT');
            } elseif (getenv('CMDLINE_CURSOR_INDEX')) {
                $index = getenv('CMDLINE_CURSOR_INDEX');
            }
            $index = urlencode($index);
            $ahtOptions[] = "--cmdline-cursor-index=\"{$index}\"";
        }

        return $ahtOptions;
    }

    /**
     * Returns a string containing the client version.
     *
     * @return string
     */
    public function setSupportToolsVersion()
    {
        $repository = __DIR__ . '/../.git';
        if (file_exists($repository)) {
            $repository = realpath($repository);
            $tag_offset = "\$(git --git-dir={$repository} describe --tags --long 2>/dev/null)";
            $this->exec("echo {$tag_offset}", $version, $error, $returnCode);
        }
        if (!empty($version)) {
            $this->supportToolsVersion = $version;
        }
    }

    private function checkSshConfig()
    {
        $host = $this->bastionName;
        $this->debugMsg('Checking local control master');
        $command = sprintf('ssh %s -Ocheck -v %s', implode(' ', $this->getSshOptions()), $this->bastionName);
        $this->exec($command, $output, $error, $return);
        if (preg_match('#(bastion-\d+)\.network\.hosting\.acquia\.com#', $error, $matches)) {
            $this->bastionActual = $matches[1];
        }
        if (preg_match('#No ControlPath specified for "-O" command#', $error, $matches)) {
            throw new \RuntimeException(
                "Could not find a ControlPath for $host. This means the SSH config entry for\n$host is either missing or misconfigured."
            );
        }
/*
        // We don't want to check the ssh agents on every aht command;
        // only check if we're explicitly debugging
        if ($return === 0 && $this->debugMode) {
            $return = $this->checkLocalSshAgent();
            $return = $this->checkRemoteSshAgent(implode(' ', $this->getSshOptions()), $host);
        }
*/
        return $return;
    }

    /**
     * This wrapper for exec is solely to collect debugging output
     *
     * @param string $command
     * @param string $output
     * @param string $error
     * @param int $returnCode Return code from the command that was exec'd
     *
     * @return int Return code from the command that was exec'd
     */
    private function exec($command, &$output, &$error, &$returnCode)
    {
        $output = '';
        $error = '';
        $returnCode = 0;

        // Debugging output
        if (!empty($command)) {
            $this->debugMsg("<info>{$command}</info>", "exec: ");
            $exitCode = $this->executionContext->exec($command, $output, $error, $returnCode);
        }

        if (!empty($output)) {
            $this->debugMsg($output, "exec[stdout]: ");
        }
        if (!empty($error)) {
            $this->debugMsg($error, "exec[<fail>stderr</fail>]: ");
        }
        return $returnCode;
    }

    private function showConnectedBastions()
    {
        $connections = '';
        $this->debugMsg("Checking SSH configs for bastion definitions.");
        $this->exec(
            'for i in $(egrep -h "Host .*bastion(-[0-9]+)?$" ~/.ssh/*config* | sort -u | sed -e "s/Host //" ); do echo $i; done | sort -nk2 -t- -u',
            $output,
            $error,
            $returnCode
        );
        foreach (preg_split('#[\r\n]+#', $output) as $bastion) {
            $this->debugMsg("Checking for an active connection to $bastion.");
            $command = sprintf('ssh -F $HOME/.ssh/config -Ocheck -v %s', $bastion);
            $output = '';
            $error = '';
            $this->exec($command, $output, $error, $returnCode);
            // Explain how to route through another bastion
            if (preg_match('#(Master running .pid=\d+.)#m', $error, $matches) && preg_match('#-\d+$#', $bastion)) {
                $connections .= sprintf(
                    "\n * %s\n   %s\n   %s",
                    "It looks like you are connected to $bastion.",
                    "If you want to route aht through $bastion, then run:",
                    "  $ export AHT_BASTION=$bastion"
                );
            }
        }

        // Explain how to connect
        if ($connections === '') {
            if ($this->sshConfig) {
                $config = "-F {$this->sshConfig} ";
            }
            $bastionCmd = str_replace('-', ' ', $bastion);
            $connections .= sprintf(
                " * %s\n   %s\n   %s\n   %s\n   %s",
                "It looks like you are not connected to any bastion.",
                "Please initiate a bastion connection using one of the following methods:",
                "[1] Connect to the default bastion\n       $ bastion",
                "[2] Connect to a specific bastion\n       $ {$bastionCmd}",
                "[3] Connect with ssh directly (requires one-time passcode from wikid app)\n       $ ssh -f -N {$config}{$bastion}"
            );
        }
        return $connections;
    }

    private function getGitVersion()
    {
        $this->debugMsg("Checking local git version.");
        $this->exec("which git", $out1, $error1, $returnCode);
        $this->exec("git --version", $out2, $error2, $returnCode);
    }

    private function getPhpVersion()
    {
        $this->debugMsg('Checking local PHP version.');
        $this->exec("which php", $out1, $error1, $returnCode);
        $this->exec("php --version", $out2, $error2, $returnCode);
    }
}
