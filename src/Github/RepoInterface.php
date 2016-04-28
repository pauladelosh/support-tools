<?php

namespace Acquia\Support\ToolsWrapper\Github;

interface RepoInterface
{
    /**
     * Get the name of the repo (vendor/repo-name).
     *
     * @return string
     */
    public function getName();

    /**
     * Get the date of the most recent update to the repo.
     *
     * @return \DateTime
     */
    public function getLastCommitDate();

    /**
     * Gets a list of open issues.
     *
     * return array
     */
    public function getOpenIssues();
}
