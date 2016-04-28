<?php

namespace Acquia\Support\ToolsWrapper;

use Symfony\Component\Console\Application;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;

final class SoloApplication extends Application
{
    /** @var Command $command The command to run. */
    private $command;

    public function __construct(Command $command)
    {
        $this->command = $command;
        parent::__construct();
    }

    /**
     * Gets the name of the command based on input.
     *
     * @param InputInterface $input The input interface
     *
     * @return string The command name
     * 
     * @SuppressWarnings(PHPMD.UnusedFormalParameter)
     */
    protected function getCommandName(InputInterface $input)
    {
        // This should return the name of your command.
        return $this->command->getName();
    }

    /**
     * Gets the default commands that should always be available.
     *
     * @return array An array of default Command instances
     */
    protected function getDefaultCommands()
    {
        // Keep the core default commands to have the HelpCommand
        // which is used when using the --help option
        $defaultCommands = parent::getDefaultCommands();

        $defaultCommands[] = $this->command;

        return $defaultCommands;
    }

    /**
     * Overridden so that the application doesn't expect the command
     * name to be the first argument.
     */
    public function getDefinition()
    {
        $inputDefinition = parent::getDefinition();
        // clear out the normal first argument, which is the command name
        $inputDefinition->setArguments();

        return $inputDefinition;
    }
}
