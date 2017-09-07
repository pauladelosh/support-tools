<?php

namespace Acquia\Support\ToolsWrapper\Github;

class GithubApiClient implements GithubApiInterface
{
    private $streamContext;

    /**
     * Setup GithubApiClient
     *
     * @param array $streamContext
     */
    public function __construct($streamContext = [])
    {
        $this->streamContext = $streamContext;
    }

    /**
     * {@inheritdoc}
     */
    public function getCommits($repoName)
    {
        return $this->apiRequest("https://api.github.com/repos/{$repoName}/commits");
    }

    /**
     * {@inheritdoc}
     */
    public function getIssues($repoName)
    {
        return $this->apiRequest("https://api.github.com/repos/{$repoName}/issues");
    }

    /**
     * Makes a GET request to the Github API
     *
     * @param string $uri
     *
     * @return array
     *
     * @throws \RuntimeException
     */
    public function apiRequest($uri)
    {
        $repoInfo = @file_get_contents(
            $uri,
            false,
            $this->streamContext
        );

        if (empty($repoInfo)) {
            throw new \RuntimeException(implode("\n", $http_response_header));
        }

        return json_decode($repoInfo);
    }
}
