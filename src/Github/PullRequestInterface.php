<?php

namespace Acquia\Support\ToolsWrapper\Github;

interface PullRequestInterface
{
    /**
     * Returns a list of reviews on a pull request.
     *
     * @see https://developer.github.com/v3/pulls/reviews/#list-reviews-on-a-pull-request
     *
     * @return array
     */
    public function getReviews();

    /**
     * Returns a list of comments on a pull request.
     *
     * @see https://developer.github.com/v3/pulls/comments/#list-comments-on-a-pull-request
     *
     * @return array
     */
    public function getComments();

    /**
     * Returns a list of review requests.
     *
     * @see https://developer.github.com/v3/pulls/review_requests/#list-review-requests
     *
     * @return array
     */
    public function getRequestedReviewers();
}
