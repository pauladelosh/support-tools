<?php

namespace Acquia\Support\ToolsWrapper\Command;

use Acquia\Support\ToolsWrapper\Github\GithubApiClient;
use Acquia\Support\ToolsWrapper\Github\PullRequest;
use Acquia\Support\ToolsWrapper\Github\Repo;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Question\Question;
use Symfony\Component\Yaml\Parser;

class CodeReviewCommand extends Command
{
    /**
     * @var GithubApiClient $apiClient
     */
    private $apiClient;

    private $config = [];

    private $githubAuthContext;

    /**
     * @var string
     */
    private $githubUserName;

    /**
     * @var Repo[]
     */
    private $repos;

    /**
     * {@inheritdoc}
     */
    protected function configure()
    {
        parent::configure();
        $this->addOption(
            'show-outdated',
            null,
            InputOption::VALUE_NONE,
            'Also show repos which have not been updated in a while.'
        );
        $this->addOption(
            'show-issues',
            null,
            InputOption::VALUE_NONE,
            'Also show repos which have Github issues filed against them.'
        );
        $this->addOption(
            'recent',
            null,
            InputOption::VALUE_OPTIONAL,
            'Filter out issues that have not been updated in the last two weeks. '
                . 'Can optionally take a value parsable by strtotime().'
        );
        $this->addOption(
            'pending',
            null,
            InputOption::VALUE_NONE,
            'Filter out issues that you have approved.'
        );
    }

    /**
     * {@inheritdoc}
     */
    protected function initialize(InputInterface $input, OutputInterface $output)
    {
        parent::initialize($input, $output);

        ini_set('user_agent', "code-review");

        $this->githubUserName = $this->getGithubUsername($input, $output);

        $this->setGithubAuthContext(
            $this->githubUserName,
            $this->getGithubToken($input, $output)
        );
        $this->apiClient = new GithubApiClient($this->githubAuthContext);

        $this->loadConfig();

        // If empty --recent option is provided, default to last 2 weeks.
        if ($input->getParameterOption('--recent') !== false) {
            if (empty($input->getOption('recent'))) {
                $input->setOption('recent', '-2 weeks');
            }
            elseif (strtotime($input->getOption('recent')) === false) {
                throw new \InvalidArgumentException(
                    'The value of the --recent option must be parsable by strtotime().'
                );
            }
        }
    }

    /**
     * Sets the stream context options to use when connecting to Github.
     *
     * @param string $user The Github username
     * @param string $token The Github user authentication token
     */
    private function setGithubAuthContext($user, $token)
    {
        $contextOptions = [
            'http' => [
                'header'  => "Authorization: Basic " . base64_encode("{$user}:{$token}"),
            ],
        ];
        $this->githubAuthContext = stream_context_create($contextOptions);
    }

    /**
     * Loads command configuration from file.
     */
    private function loadConfig()
    {
        $configFilename = __DIR__ . '/../../lib/code-review.yml.dist';
        if (file_exists(__DIR__ . '/../../lib/code-review.yml')) {
            $configFilename = __DIR__ . '/../../lib/code-review.yml';
        }

        $parser = new Parser();
        $this->config = $parser->parse(file_get_contents($configFilename));
    }

    /**
     * Get the Github user's username.
     *
     * Try to load this from the user's gitconfig; otherwise ask them for it.
     *
     * @param InputInterface $input
     * @param OutputInterface $output
     *
     * @return string
     */
    private function getGithubUsername(InputInterface $input, OutputInterface $output)
    {
        $user = exec('git config github.user');
        if (!$user) {
            $helper = $this->getHelper('question');
            $question = new Question('What is your Github username? ');
            $question->setValidator(
                function ($name) {
                    if (!preg_match('#^[a-zA-Z0-9]([a-zA-Z0-9-]+[a-zA-Z0-9])?$#', $name)) {
                        throw new \InvalidArgumentException(
                            sprintf(
                                "%s, %s",
                                "Login may only contain alphanumeric characters or single hyphens",
                                "and cannot begin or end with a hyphen"
                            )
                        );
                    };
                    return $name;
                }
            );
            $user = $helper->ask($input, $output, $question);
            exec(sprintf('git config --global github.user %s', $user));
        }
        return $user;
    }

    /**
     * Get the Github user's authentication token.
     *
     * Try to load the token from a config file; otherwise ask them for it.
     *
     * @param InputInterface $input
     * @param OutputInterface $output
     *
     * @return string
     */
    private function getGithubToken(InputInterface $input, OutputInterface $output)
    {
        $token = null;
        $tokenDir =  getenv('HOME') . '/.config'; // Same dir as hub gem token.
        $tokenFile = $tokenDir . '/code-review';

        if (file_exists($tokenFile)) {
            $token = trim(file_get_contents($tokenFile));
        }

        if (!$token) {
            $helper = $this->getHelper('question');
            $question = new Question('What is your Github token? ');
            $token = $helper->ask($input, $output, $question);
            @mkdir($tokenDir);
            file_put_contents($tokenFile, $token);
        }
        return $token;
    }

    /**
     * {@inheritdoc}
     */
    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $this->repos = $this->getRepos();

        $this->displayPullRequests(
            $output,
            strtotime($input->getOption('recent')),
            $input->getOption('pending')
        );

        if ($input->getOption('show-outdated')) {
            $this->displayOutdatedRepos($output);
        }

        if ($input->getOption('show-issues')) {
            $this->displayOutstandingIssues($output);
        }
    }

    /**
     * Displays open pull requests.
     *
     * @param OutputInterface $output
     * @param int|null $recent
     * @param bool $pending
     */
    protected function displayPullRequests(OutputInterface $output, $recent = null, $pending = null)
    {
        /** @var Repo $repo */
        foreach ($this->repos as $repo) {
            $hasPrs = false;
            $issues = $repo->getOpenIssues();
            foreach ($issues as $issue) {
                if (!isset($issue->pull_request)) {
                    continue;
                }
                if ($recent && strtotime($issue->updated_at) < $recent) {
                    continue;
                }
                $reviews = $this->getPullRequestReviews($repo->getName(), $issue->number);
                if ($pending && $this->approvedByMe($reviews)) {
                    continue;
                }
                if (!$hasPrs) {
                    $output->writeln(sprintf("<info>%s:</info>", $repo->getName()));
                    $hasPrs = true;
                }
                $output->writeln(
                    sprintf(
                        "<comment>% 4s - %s</comment> (%s)",
                        $issue->number,
                        $issue->title,
                        $issue->user->login
                    )
                );
                $labels = '';
                foreach ($issue->labels as $label) {
                    $style = [];
                    foreach ($this->getLabelStyleProperties($label->color) as $key => $value) {
                        $style[] = sprintf('%s=%s', $key, $value);
                    }
                    $labels .= sprintf("<%s> %s </> ", implode($style, ';'), $label->name);
                }
                if (!empty($labels)) {
                    $output->writeln(
                        sprintf(
                            "       Labels: %s",
                            $labels
                        )
                    );
                }

                // Display a list of reviews and statuses.
                if ($reviews) {
                    // The author of the issue should not be listed as a reviewer.
                    unset($reviews[$issue->user->id]);
                    if ($reviews = $this->formatPullRequestReviews($reviews)) {
                        $output->writeln(
                            sprintf(
                                "       Reviewers: %s",
                                $reviews
                            )
                        );
                    }
                }

                $output->writeln(
                    sprintf(
                        "       %s\n",
                        $issue->pull_request->html_url
                    )
                );
            }
        }
    }

    /**
     * Determine if a pull request has been approved by me.
     *
     * @param array $reviews
     *
     * @return bool
     */
    protected function approvedByMe(array $reviews)
    {
        foreach ($reviews as $review) {
            if ($review['login'] == $this->githubUserName && $review['state'] == 'APPROVED') {
                return true;
            }
        }

        return false;
    }

    /**
     * Displays outdated repos.
     *
     * @param OutputInterface $output
     */
    protected function displayOutdatedRepos(OutputInterface $output)
    {
        $outdatedRepos = [];
        $now = new \DateTime();

        foreach ($this->repos as $repo) {
            $last = $repo->getLastCommitDate();
            $interval = $now->diff($last);
            if ($interval->days > 30) {
                if (!isset($outdatedRepos[$interval->days])) {
                    $outdatedRepos[$interval->days] = [];
                }
                $outdatedRepos[$interval->days][] = $repo;
            }
        }

        ksort($outdatedRepos);
        foreach ($outdatedRepos as $daysSinceLastUpdate => $outdatedRepoGroup) {
            foreach ($outdatedRepoGroup as $repo) {
                $output->writeln(
                    sprintf(
                        "<comment>Outdated: %s hasn't been updated in %d days</comment>",
                        $repo->getName(),
                        $daysSinceLastUpdate
                    )
                );
            }
        }
    }

    /**
     * Displays repos with Github issues.
     *
     * @param OutputInterface $output
     */
    protected function displayOutstandingIssues(OutputInterface $output)
    {
        $output->writeln('');
        foreach ($this->repos as $repo) {
            $issues = $repo->getOpenIssues();
            foreach ($issues as $issue) {
                if (!isset($issue->pull_request)) {
                    $output->writeln(
                        sprintf(
                            "<comment>Issue: %s has an issue %s</comment>",
                            $repo->getName(),
                            $issue->html_url
                        )
                    );
                }
            }
        }
    }

    /**
     * @return array
     */
    protected function getRepos()
    {
        $repos = [];
        foreach (array_keys($this->config['repos']) as $repoName) {
            $repos[$repoName] = new Repo($repoName, $this->apiClient);
        }

        return $repos;
    }

    /**
     * Return an array containing the most recent review status for each
     * user who has provided feedback for the PR. Note that comments that
     * are added after a review are ignored.
     *
     * @param string $repoName
     * @param int $pullNumber
     *
     * @return array
     */
    protected function getPullRequestReviews($repoName, $pullNumber)
    {
        $reviewStatus = [];
        $state = [
            'REQUESTED' => 0,
            'COMMENTED' => 1,
            'APPROVED' => 2,
            'CHANGES_REQUESTED' => 2,
            'DISMISSED' => 2,
        ];

        // First get a list of the requested reviewers.
        $pullRequest = new PullRequest($repoName, $pullNumber, $this->apiClient);
        foreach ($pullRequest->getRequestedReviewers() as $reviewer) {
            $reviewStatus[$reviewer->id] = [
                'login' => $reviewer->login,
                'state' => 'REQUESTED',
                'submitted_at' => null,
            ];
        }

        // Next set the current review status for all unique reviewers.
        foreach ($pullRequest->getReviews() as $review) {
            $newUser = (!isset($reviewStatus[$review->user->id]));
            if ($newUser || ($review->submitted_at > $reviewStatus[$review->user->id]['submitted_at'])) {
                if ($newUser || ($state[$review->state] >= $state[$reviewStatus[$review->user->id]['state']])) {
                    $reviewStatus[$review->user->id] = [
                        'login' => $review->user->login,
                        'state' => $review->state,
                        'submitted_at' => $review->submitted_at,
                    ];
                }
            }
        }

        return $reviewStatus;
    }

    /**
     * Return a formatted string of pull request reviewers and corresponding
     * status icons.
     *
     * @param array $reviews
     *   An array of reviews for a pull request.
     *
     * @return string
     */
    protected function formatPullRequestReviews(array $reviews)
    {
        return implode(' ', array_map(function ($review) {
            switch ($review['state']) {
                case ('COMMENTED'):
                    return "{$review['login']} 💬  ";

                case ('CHANGES_REQUESTED'):
                    return "{$review['login']} <fg=red>✘</>  ";

                case ('APPROVED'):
                    return "{$review['login']} <fg=green>✔</>  ";

                default:
                    return "{$review['login']} <fg=yellow>●</>  ";
            }
        }, $reviews));
    }

    /**
     * Return an array of style properties (foreground and background colors)
     * to apply to console output. The provided hex value is matched to the
     * available Symfony console default colors based on RGB values.
     *
     * @param string $hexColor The hex value for the label color.
     *
     * @return array The style properties.
     */
    private function getLabelStyleProperties($hexColor)
    {
        $consoleStyle = [];
        $consoleColors = [
            'black' => [0, 0, 0],
            'red' => [255, 0, 0],
            'green' => [0, 255, 0],
            'yellow' => [255, 255, 0],
            'blue' => [92, 92, 255],
            'magenta' => [255, 0, 255],
            'cyan' => [0, 255, 255],
            'white' => [255, 255, 255],
        ];

        // Convert hex color value to RGB.
        list($r, $g, $b) = array_map('hexdec', str_split($hexColor, 2));

        // Compare the "distance" of the RGB values.
        foreach ($consoleColors as $color => $rgb) {
            $distance = sqrt(pow(($r - $rgb[0]), 2) + pow(($g - $rgb[1]), 2) + pow(($b - $rgb[2]), 2));
            if (!isset($closest) || ($distance < $closest)) {
                $closest = $distance;
                $consoleStyle['bg'] = $color;
            }
        }

        // Set foreground color for better contrast.
        $consoleStyle['fg'] = (in_array($consoleStyle['bg'], ['yellow', 'green', 'white'])) ? 'black' : 'white';

        return $consoleStyle;
    }
}
