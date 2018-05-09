<?php

namespace Acquia\Support\ToolsWrapper\Tests\Github;

use Acquia\Support\ToolsWrapper\Github\PullRequest;

/**
 * @coversDefaultClass \Acquia\Support\ToolsWrapper\Github\PullRequest
 */
class PullRequestTest extends \PHPUnit_Framework_TestCase
{
    /**
     * @covers ::getReviews
     */
    public function testGetReviews()
    {
        $apiClient = $this->createMock('Acquia\Support\ToolsWrapper\Github\GithubApiClient');
        $apiClient->expects($this->once())
            ->method('apiRequest')
            ->with('https://api.github.com/repos/foo/bar/pulls/1234/reviews')
            ->will($this->returnValue(['baz']));
        $pullRequest = new PullRequest('foo/bar', 1234, $apiClient);
        $this->assertEquals($pullRequest->getReviews(), ['baz']);
    }

    /**
     * @covers ::getComments
     */
    public function testGetComments()
    {
        $apiClient = $this->createMock('Acquia\Support\ToolsWrapper\Github\GithubApiClient');
        $apiClient->expects($this->once())
            ->method('apiRequest')
            ->with('https://api.github.com/repos/foo/bar/pulls/1234/comments')
            ->will($this->returnValue(['baz']));
        $pullRequest = new PullRequest('foo/bar', 1234, $apiClient);
        $this->assertEquals($pullRequest->getComments(), ['baz']);
    }

    /**
     * @covers ::getRequestedReviewers
     */
    public function testGetRequestedReviewers()
    {
        $apiClient = $this->createMock('Acquia\Support\ToolsWrapper\Github\GithubApiClient');
        $apiClient->expects($this->once())
            ->method('apiRequest')
            ->with('https://api.github.com/repos/foo/bar/pulls/1234/requested_reviewers')
            ->will($this->returnValue(['baz']));
        $pullRequest = new PullRequest('foo/bar', 1234, $apiClient);
        $this->assertEquals($pullRequest->getRequestedReviewers(), ['baz']);
    }
}
