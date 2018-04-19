<?php

namespace Acquia\Support\ToolsWrapper\Github;

class PullRequest implements PullRequestInterface
{
    /**
     * @var \Acquia\Support\ToolsWrapper\Github\GithubApiInterface
     */
    private $apiClient;

    /**
     * @var int
     */
    private $pullNumber;

    /**
     * @var string
     */
    private $repoName;

    /**
     * PullRequest constructor.
     *
     * @param string $repoName
     * @param int $pullNumber
     * @param \Acquia\Support\ToolsWrapper\Github\GithubApiInterface $apiClient
     */
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
            "https://api.github.com/repos/{$this->repoName}/pulls/{$this->pullNumber}/reviews",
            0
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
