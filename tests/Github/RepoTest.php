<?php

namespace Acquia\Support\ToolsWrapper\Tests\Github;

use Acquia\Support\ToolsWrapper\Github\Repo;

class RepoTest extends \PHPUnit_Framework_TestCase
{
    const TEST_REPO = 'test/test-repo';

    /**
     * @covers \Acquia\Support\ToolsWrapper\Github\Repo
     */
    public function testRepoTest()
    {
        $testTime = time();

        $apiClient = $this->getMock('Acquia\Support\ToolsWrapper\Github\GithubApiInterface');

        // Stub GithubApiInterface::getIssues method
        $apiClient->expects($this->once())
            ->method('getIssues')
            ->with(self::TEST_REPO)
            ->will($this->returnValue(['issue' => 'issue data']));

        // Stub GithubApiInterface::getCommits method
        $apiClient->expects($this->once())
            ->method('getCommits')
            ->with(self::TEST_REPO)
            ->will($this->returnValue([
                (object)[
                    'commit' => (object) [
                        'committer' => (object) [
                            'date' => strftime("%c", $testTime)
                        ]
                    ]
                ]
            ]));

        // Make a repo from test data.
        $repo = new Repo(self::TEST_REPO, $apiClient);

        // Verify name is set
        $this->assertEquals(self::TEST_REPO, $repo->getName());

        // Verify Github issues passed through.
        $issues = $repo->getOpenIssues();
        $this->assertArrayHasKey('issue', $issues);
        $this->assertEquals('issue data', $issues['issue']);

        // Verify Last Commit Date retrieved.
        $date = $repo->getLastCommitDate();
        $this->assertEquals($testTime, $date->getTimestamp());
    }
}
