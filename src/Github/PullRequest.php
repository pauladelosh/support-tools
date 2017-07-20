<?php

namespace Acquia\Support\ToolsWrapper\Github;

class PullRequest implements PullRequestInterface
{
    /**
     * @var GithubApiClient $apiClient
     */
    private $apiClient;

    /**
     * @var int $pullNumber
     */
    private $pullNumber;

    /**
     * @var string $repoName
     */
    private $repoName;

    public function __construct($repoName, $pullNumber, $apiClient)
    {
        $this->repoName = $repoName;
        $this->pullNumber = $pullNumber;
        $this->apiClient = $apiClient;
    }

    /**
     * {@inheritdoc}
     */
    public function getReviews()
    {
        return $this->apiClient->apiRequest(
            "https://api.github.com/repos/{$this->repoName}/pulls/{$this->pullNumber}/reviews"
        );
    }

    /**
     * {@inheritdoc}
     */
    public function getComments()
    {
        return $this->apiClient->apiRequest(
            "https://api.github.com/repos/{$this->repoName}/pulls/{$this->pullNumber}/comments"
        );
    }

    /**
     * {@inheritdoc}
     */
    public function getRequestedReviewers()
    {
        return $this->apiClient->apiRequest(
            "https://api.github.com/repos/{$this->repoName}/pulls/{$this->pullNumber}/requested_reviewers"
        );
    }
}
