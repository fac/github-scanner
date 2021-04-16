#!/usr/bin/env bash

export GITHUB_ORG=fac

# Hide use of bundler from the tests
gh-repo-scan() {
  bundle exec gh-repo-scan "$@"
}
