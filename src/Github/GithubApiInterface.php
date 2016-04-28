<?php

namespace Acquia\Support\ToolsWrapper\Github;

interface GithubApiInterface
{
    /**
     * Return latest commits for a repo.
     *
     * @param string $repoName
     *
     * @return array
     */
    public function getCommits($repoName);

    /**
     * Returns issues for a repo.
     *
     * @param string $repoName
     *
     * @return array
     */
    public function getIssues($repoName);
}
