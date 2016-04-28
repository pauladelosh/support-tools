<?php

namespace Acquia\Support\ToolsWrapper\Github;

class Repo implements RepoInterface
{
    /**
     * @var GithubApiClient $apiClient
     */
    private $apiClient;

    /**
     * @var string $repoName
     */
    private $repoName;

    public function __construct($repoName, $apiClient)
    {
        $this->repoName = $repoName;
        $this->apiClient = $apiClient;
    }

    /**
     * {@inheritdoc}
     */
    public function getName()
    {
        return $this->repoName;
    }

    /**
     * {@inheritdoc}
     */
    public function getLastCommitDate()
    {
        $repoInfo = $this->apiClient->getCommits($this->repoName);
        return new \DateTime($repoInfo[0]->commit->committer->date);
    }

    /**
     * {@inheritdoc}
     */
    public function getOpenIssues()
    {
        static $repoIssues = [];
        if (!isset($repoIssues[$this->repoName])) {
            $repoIssues[$this->repoName] = $this->apiClient->getIssues($this->repoName);
        }
        return $repoIssues[$this->repoName];
    }
}
