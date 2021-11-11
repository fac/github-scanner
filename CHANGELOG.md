# Changelog

## [Unreleased]

- Add: Apache 2.0 license

## [0.5.3] - 2021-05-24

- Fix: Pathname used before requiring it

## [0.5.1] - 2021-04-16

- Add: github actions driven gem release using fac ruby actions

## [0.5.0] - 2021-03-27

* Add `--help` instead of just failing on no action.
* Add `--limit` option and fix option aliases.
* Add `--line-numbers` option for cat
* Add `--json` an option to any action
* Add handling of orgs other than fac via `--org=ORG` or setting `GITHUB_ORG` env var
* Update error logging from command line - prefix `gh-repo-scan: FAIL: msg` and send to STDERR. 
* Update totals action shows active/archived split
* Change the default tty output to be more like `ag`.
* When not a tty use the full prefix line with no headers, so it is nice for filters. 
* README updated. Add Synopsis, Authors, See Also sections.
* Remove json action
* Skipping version v0.4.0 due to confusing commit messages claiming version 0.4.0 while actually landing 0.3.0!
