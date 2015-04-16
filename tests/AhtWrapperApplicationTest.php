<?php

namespace Acquia\Support\Tests;

use \Acquia\Support\ToolsWrapper\AhtWrapperApplication;
use Symfony\Component\Console\Output\NullOutput;

class AhtWrapperApplicationTest extends \PHPUnit_Framework_TestCase
{
    private $argv = ['/path/to/Support-Tools/bin/aht'];

    protected function setUp()
    {
        // Clear any environmental vars
        putenv('AHT_BASTION=');
        putenv('AH_SSH_CONFIG=');
        putenv('AHSTAGES=');
        putenv('AHTPATH=');
    }

    protected function ahtWrapperFactory($executionObserver)
    {
        $aht = new AhtWrapperApplication($executionObserver, new NullOutput());
        return $aht;
    }

    public function testBasic()
    {
        $executionObserver = $this->getMockBuilder('\Acquia\Support\ToolsWrapper\AhtWrapperExecutionContextInterface')
            ->setMethods(['passthru','exec'])
            ->getMock();

        $executionObserver->expects($this->any())
            ->method('exec')
            ->will($this->returnValue(0));

        $executionObserver->expects($this->once())
            ->method('passthru')
            ->with(
                $this->equalTo(
                    'ssh -tq bastion /vol/ebs1/ahsupport/support_bin/ahtools --client-tools-version=dev '
                )
            );

        $this->ahtWrapperFactory($executionObserver)->runAht($this->argv);
    }

    public function testAhtBastionEnv()
    {
        $executionObserver = $this->getMockBuilder('\Acquia\Support\ToolsWrapper\AhtWrapperExecutionContextInterface')
            ->setMethods(['passthru','exec'])
            ->getMock();

        $executionObserver->expects($this->any())
            ->method('exec')
            ->will($this->returnValue(0));

        $executionObserver->expects($this->exactly(2))
            ->method('passthru')
            ->withConsecutive(
                $this->equalTo(
                    'ssh -tq srv-123 /vol/ebs1/ahsupport/support_bin/ahtools --client-tools-version=dev '
                ),
                $this->equalTo(
                    'ssh -tq srv-123.dev.internal.acquia.com /vol/ebs1/ahsupport/support_bin/ahtools --client-tools-version=dev '
                )
            );

        // short hostname
        putenv('AHT_BASTION=srv-123');
        $this->ahtWrapperFactory($executionObserver)->runAht($this->argv);

        // fully qualified host name
        putenv('AHT_BASTION=srv-123.dev.internal.acquia.com');
        $this->ahtWrapperFactory($executionObserver)->runAht($this->argv);
    }

    /**
     * @backupStaticAttributes enabled
     */
    public function testAhtSshConfigEnv()
    {
        $path = "{$_SERVER['HOME']}/.ssh/ah_config";

        $executionObserver = $this->getMockBuilder('\Acquia\Support\ToolsWrapper\AhtWrapperExecutionContextInterface')
            ->setMethods(['passthru','exec'])
            ->getMock();

        $executionObserver->expects($this->any())
            ->method('exec')
            ->will($this->returnValue(0));

        $executionObserver->expects($this->once())
            ->method('passthru')
            ->with(
                $this->equalTo(
                    "ssh -tq -F {$path} bastion /vol/ebs1/ahsupport/support_bin/ahtools --client-ssh-config={$path} --client-tools-version=dev "
                )
            );

        putenv("AH_SSH_CONFIG={$path}");
        $this->ahtWrapperFactory($executionObserver)->runAht($this->argv);
    }

    public function testAhtRealmEnv()
    {
        $executionObserver = $this->getMockBuilder('\Acquia\Support\ToolsWrapper\AhtWrapperExecutionContextInterface')
            ->setMethods(['passthru','exec'])
            ->getMock();

        $executionObserver->expects($this->any())
            ->method('exec')
            ->will($this->returnValue(0));

        $executionObserver->expects($this->exactly(2))
            ->method('passthru')
            ->withConsecutive(
                $this->equalTo(
                    "ssh -tq bastion /vol/ebs1/ahsupport/support_bin/ahtools --stages=foo,bar --client-tools-version=dev "
                ),
                $this->equalTo(
                    "ssh -tq bastion /vol/ebs1/ahsupport/support_bin/ahtools --client-tools-version=dev --stages=baz"
                )
            );

        // default stages set
        putenv("AHSTAGES=foo,bar");
        $this->ahtWrapperFactory($executionObserver)->runAht($this->argv);

        // default stages plus user-requested stages
        putenv("AHSTAGES=foo,bar");
        $this->ahtWrapperFactory($executionObserver)->runAht(array_merge($this->argv, ['--stages=baz']));
    }

    public function testAhtPathEnv()
    {
        $executionObserver = $this->getMockBuilder('\Acquia\Support\ToolsWrapper\AhtWrapperExecutionContextInterface')
            ->setMethods(['passthru','exec'])
            ->getMock();

        $executionObserver->expects($this->any())
            ->method('exec')
            ->will($this->returnValue(0));

        $executionObserver->expects($this->exactly(2))
            ->method('passthru')
            ->withConsecutive(
                $this->equalTo(
                    'ssh -tq bastion /vol/ebs1/ahsupport/support_bin_test/ahtools --client-tools-version=dev '
                ),
                $this->equalTo(
                    'ssh -tq bastion /vol/ebs1/ahsupport/foo/ahtools --client-tools-version=dev '
                )
            );

        // keyword "test" should pick support_bin_test
        putenv("AHTPATH=test");
        $this->ahtWrapperFactory($executionObserver)->runAht($this->argv);

        // otherwise just a drop-in replacement for folder name
        putenv("AHTPATH=foo");
        $this->ahtWrapperFactory($executionObserver)->runAht($this->argv);
    }
}
