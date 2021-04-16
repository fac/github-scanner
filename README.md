# GitHub::Scanner

A command line power tool for fast scanning of GH repos and their git trees, via the graphQL API.

## Synopsis

```bash
gh-repo-scan --help

export GITHUB_PAT=xxx
gh-repo-scan [ls|cat] [OPTIONS]
```

## Options

```txt
> gh-repo-scan --help
usage: gh-repo-scan [ls|list|cat|total] [OPTIONS]
    --org           GitHub organisation to scan. Uses GITHUB_ORG env if not given
    --all           Include all repos, archived and active. Default is only active.
    --archived      Include only archived repos in the scan
    --top, --limit  Only return first limit results. Default is all of them.
    -l, --long      Long list format
    --count         Show count on repo matches and total at the end
    --json          Output the JSON returned for each repo instead of normal list output
    --task-list     Markdown task list format list
    --version       Print the version
    --help          Print usage message and option docs

File scanning. Set --path:
    --path          File path in the repo to scan
    --grep          File contents match this regex
    --grep-exclude  File contents do not match this regex
    -C, --context   Lines of files context to show in cat. Default is all.
    --file-header   Show file header above contents in cat
    --line-prefix   Prefix lines with repo name in cat
    --line-numbers  Prefix lines line line number in cat
```

## Installation

You need to be on **ruby 2.7+** Install locally:

```bash
gem install github-scanner --source "https://rubygems.pkg.github.com/fac"
```

## Usage

You need a GitHub Personal Access Token (PAT) with perms to read all the orgs and repos you want to scan. Set that in the env as `GITHUB_PAT`.

```bash
export GITHUB_PATH=xxx
```
If your going to be quering the same organisation over and over,instead of having to pass --org to all calls you can set the `GITHUB_ORG` env var. e.g.
```bash
export GITHUB_ORG=fac
```


### List repositories

Running `gh-repo-scan ls` (or `list`), lists repos and matched files. Use the options to change the filter. Note, by default archived repos are ignored.

List all repos with a Gemfile on the default branch:

```sh
gh-repo-scan ls --path=Gemfile
```

```txt
fac/freeagent        
fac/banksy
...
```

All repos with a Jenkinsfile that runs the gem build pipeline, with extra info and counts:

```sh
gh-repo-scan ls --path=Jenkinsfile --grep='freeagentGem' --long --count
```

```txt
1  fac/rchardet-omer-fork  Jenkinsfile ae916c4f0 2020-04-15T15:07:13Z Mark Pitchless
...
26 fac/nulldb              Jenkinsfile a4d529688 2021-02-24T14:00:12Z James Bell
26 repos matched, 422 scanned, 422 total

```

### Cat repository file contents

The `cat` command is for catting (dumping to STDOUT) the contents of files in the git tree of the repo (on the defualt branch).

It is useful for reviewing files, say the headers on our README.md files:

```sh
gh-repo-scan cat -C2 --path=README.md
```

```txt
github.com:fac/banksy/README.md@35c0d7e4e36c0e9e71f4396f2c56da689ab50004
1: # banksy
2: 

github.com:fac/freeagent-api-view/README.md@4252468f329445bfee53693ac301d9345c3ec8f7
1: FreeAgent API Templating
2: ========================
```

You can control the line numbering (`--line-numbers`), line prefixing (`--line-prefix`) and file header line (`--file-header`). Context, `-C` is the amount to cat of the file, context like grep.

It's other use is for piping into grep and friends. When not outputting to a tty, by default the output changes to be more pipeline friendly. e.g. to (somewhat randomly) find all the repos we use a ruby table gem in:

```sh
gh-repo-scan cat -C1000 --path=Gemfile | grep table
```

```txt
fac/freeagent:139: gem "terminal-table"
fac/jenkins-aws-images:4: gem 'table_print'
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake` to run all the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Run `bundle exec gh-repo-scan` to test your changes.

### bats test suite

The repo includes a bats (bash automated test system) test suite to do high level integration tests of the command line tool. First [install bats](https://bats-core.readthedocs.io/en/latest/installation.html) and export GITHUB_PAT with a token that can see this repo at minimum. Then you can run the tests:

```
export GITHUB_PAT=xxx
bats -r test.bats
```

### Library Use

To use the lib in your own code, add this line to your application's Gemfile:

```ruby
source "https://rubygems.pkg.github.com/fac" do
  gem 'github-scanner'
end
```

then run:

```bash
bundle install
```

now you can:

```ruby
  require 'github/scanner'

  GitHub::Scanner.scan(:repo, org: @opts[:org]).run.each do |repo|
    puts repo[:name]
  end
```

### Release

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb` and push to GitHub and get the PR merged to main. GitHub actions will then release the gem to the [fac GH package repo](https://github.com/orgs/fac/packages?repo_name=github-scanner).




## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fac/github-scanner. Find those responsible and willing to help in `#dev-platform`.

## See Also

* [Gem graphql-client](https://github.com/github/graphql-client/tree/master/lib/graphql/client) - The gem we use to do all the API heavy lifting.

* [GitHub GraphQL Intro](https://docs.github.com/en/graphql/guides/introduction-to-graphql) - If you going to work on the scanner, you will need some graphql, enough to work on github queries.
* [GitHub GraphQL Explorer](https://docs.github.com/en/graphql/overview/explorer) - Use the explorer to test queries (that is why they are in separate files!).
* [graphql.org](https://graphql.org/)
## Authors

* @dev-platform
* @markpitchless
* @dgholz
