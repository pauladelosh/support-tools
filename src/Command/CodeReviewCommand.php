<?php

namespace Acquia\Support\ToolsWrapper\Command;

use Acquia\Support\ToolsWrapper\Github\GithubApiClient;
use Acquia\Support\ToolsWrapper\Github\Repo;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Question\Question;
use Symfony\Component\Yaml\Parser;

class CodeReviewCommand extends Command
{
    private $config = [];

    private $githubAuthContext;

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
    }

    /**
     * {@inheritdoc}
     */
    protected function initialize(InputInterface $input, OutputInterface $output)
    {
        parent::initialize($input, $output);

        ini_set('user_agent', "code-review");

        $this->setGithubAuthContext(
            $this->getGithubUsername($input, $output),
            $this->getGithubToken($input, $output)
        );

        $this->loadConfig();
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
            $question = new Question('What is your Github token?');
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
        $repos = $this->getRepos();

        $this->displayPullRequests($repos, $output);

        if ($input->getOption('show-outdated')) {
            $this->displayOutdatedRepos($repos, $output);
        }

        if ($input->getOption('show-issues')) {
            $this->displayOutstandingIssues($repos, $output);
        }
    }

    /**
     * Displays open pull requests.
     *
     * @param array $repos
     */
    protected function displayPullRequests(array $repos, OutputInterface $output)
    {
        foreach ($repos as $repo) {
            $hasPrs = false;
            $issues = $repo->getOpenIssues();
            foreach ($issues as $issue) {
                if (!isset($issue->pull_request)) {
                    continue;
                }
                if (!$hasPrs) {
                    $output->writeln(sprintf("<info>%s:</info>", $repo->getName()));
                    $hasPrs = true;
                }
                $output->writeln(
                    sprintf(
                        "<comment>% 4s - %s</comment>",
                        $issue->number,
                        $issue->title
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
                $output->writeln(
                    sprintf(
                        "       %s\n",
                        $issue->pull_request->html_url
                    )
                );

                //print_r($issue);
            }
        }
    }

    /**
     * Displays outdated repos.
     *
     * @param array $repos
     * @param OutputInterface $output
     */
    protected function displayOutdatedRepos(array $repos, OutputInterface $output)
    {
        $outdatedRepos = [];
        $now = new \DateTime();

        foreach ($repos as $repo) {
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
     * @param array $repos
     */
    protected function displayOutstandingIssues(array $repos, OutputInterface $output)
    {
        $output->writeln('');
        foreach ($repos as $repo) {
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
        $apiClient = new GithubApiClient($this->githubAuthContext);
        $repos = [];
        foreach (array_keys($this->config['repos']) as $repoName) {
            $repos[$repoName] = new Repo($repoName, $apiClient);
        }

        return $repos;
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
