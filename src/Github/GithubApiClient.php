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
     */
    public function apiRequest($uri)
    {
        $repoInfo = json_decode(
            file_get_contents(
                $uri,
                false,
                $this->streamContext
            )
        );

        return $repoInfo;
    }
}
