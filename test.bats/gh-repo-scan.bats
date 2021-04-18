#!/usr/bin/env bats

load bats_helper

@test "Displays help with --help" {
  run gh-repo-scan --help
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == 'usage: gh-repo-scan [ls|list|cat|total] [OPTIONS]' ]
}

@test "Displays version with --version" {
  run gh-repo-scan --version
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == '0.5.2.dev1' ]
}

@test "Can scan for its own repo" {
  gh-repo-scan ls | grep github-scanner
}

@test "Using --archived excludes own repo" {
  gh-repo-scan ls --archived | grep -v github-scanner
}

@test "cat finds and echos this repo's README" {
  gh-repo-scan cat --org=fac --path=README.md -C1 | grep 'fac/github-scanner:1: # GitHub::Scanner'
}
