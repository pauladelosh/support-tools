<?php

namespace Acquia\Support\ToolsWrapper\Github;

class GithubApiClient implements GithubApiInterface
{
    private $streamContext;

    /**
     * GithubApiClient constructor.
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
     * {@inheritdoc}
     */
    public function apiRequest($uri, $limit = 1)
    {
        $repoInfo = [];
        $repoInfo[] = @file_get_contents(
            $uri,
            false,
            $this->streamContext
        );

        if (empty($repoInfo)) {
            throw new \RuntimeException(implode("\n", $http_response_header));
        }

        $count = 0;
        if ($limit !== 1) {
            foreach ($http_response_header as $header) {
                if (strpos($header, 'page=: ') !== FALSE) {
                    preg_match('/(page=\d+)/', $header, $matches);
                    $pages = count(array_unique($matches));
                    $count = ($limit < 1) ? $pages : min($pages, $limit);
                    break;
                }
            }
        }

        if ($count) {
            for ($i = 2; $i <= $count + 1 ; $i++) {
                $repoInfo[] = @file_get_contents(
                    "{$uri}?page={$i}",
                    false,
                    $this->streamContext
                );

                if (empty($repoInfo[$i - 1])) {
                    throw new \RuntimeException(implode("\n", $http_response_header));
                }
            }
        }

        $result = [];
        foreach ($repoInfo as $page) {
            $page = json_decode($page);
            if (!is_array($page)) {
                return $page;
            }
            $result = array_merge($result, $page);
        }

        return $result;
    }
}
