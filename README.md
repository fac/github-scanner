# GitHub::Scanner

A command line power tool for fast scanning of GH repos and their git trees, via the graphQL API.

## Installation

You need to be on **ruby 2.7+** Install locally:

```bash
gem install github-scanner --source "https://rubygems.pkg.github.com/fac"
```

To use the lib in your own code add this line to your application's Gemfile:

```ruby
source "https://rubygems.pkg.github.com/fac" do
  gem 'github-scanner'
end
```

And then execute:
```bash
bundle install
```

## Usage

You need a GitHub Personal Access Token (PAT) with perms to read all the orgs and repos you want to scan. Set that in the env as `GITHUB_PAT`.

```bash
export GITHUB_PATH=xxx
```

### Getting Help

```
> gh-repo-scan
No action given
usage: gh-repo-scan [ls|list|cat|total|json] [OPTIONS]
    --archived                  Include archived repos in the search
    --all                       Include all repos, don't filter by archive or path existing
    --text-context, -C          Lines of files context to show
    --repo-divider              Show repo divider line in cat
    --repo-prefix               Prefix lines with repo name in cat
    --path                      File path in the repo to scan
    --grep                      File contents match this regex
    --grep-exclude              File contents do not match this regex
    --long, -lLong list format  
    --count                     Show count on repo matches and total at the end
    --task-list                 Markdown task list format list
    --version                   print the version
```

### `list` `ls` - List repositories

Running `gh-repo-scan ls` (or `list`), lists repos and matched files. Use the options to change the filter. Note, by default archived repos are ignored.

List all repos with a Gemfile on the default branch:

```
> ./gh-repo-scan ls --path=Gemfile
fac/freeagent        
fac/banksy
...
```

All repos with a Jenkinsfile that runs the gem build pipeline, with extra info and counts:
```
> ./gh-repo-scan ls --path=Jenkinsfile --grep='freeagentGem' --long --count
 1 fac/freeagent-api-view  Jenkinsfile 4252468f3 2021-01-15T16:33:25Z David Pilling
 ...
 26 fac/nulldb            Jenkinsfile a4d529688 2021-02-24T14:00:12Z James Bell
 26 repos
```

### `cat` - Cat repository file contents

The `cat` command is for catting (dumping to STDOUT) the contents of files in the git tree of the repo (on the defualt branch).

e.g. say, I wanted to review all those gem builds listed above:

```bash
cat -C42 --path=Jenkinsfile --grep='freeagentGem' | less
```

The Gemfile is grabbed from each repo and the contents output with lines prefixed with the repo name and with a divider between repos. Both are optional. -C is the amount to cat of the file, context like grep. e.g. lets review the README headers:

```
> ./gh-repo-scan cat -C6 --path=README.md
==> fac/banksy README.md@35c0d7e4e36c0e9e71f4396f2c56da689ab50004 <==============================
fac/banksy: # banksy
fac/banksy: 
fac/banksy: **Important:** Yodlee has only allowed the IP addresses of the FreeAgent office. See [this section](#connecting-remotely) for connecting to Banksy remotely.
fac/banksy: 
fac/banksy: ## Quick Start
fac/banksy: 
==> fac/dev-dashboard README.md@37cf015158c0d5ca3c4d5c15ea0f905eebd00d3d <==============================
fac/dev-dashboard: # Dev Dashboard [![Code Climate](https://codeclimate.com/repos/52ea5e9b6956802b3e002c97/badges/31fa4a64a5cd2927e8d7/gpa.svg)](https://codeclimate.com/repos/52ea5e9b6956802b3e002c97/feed)
fac/dev-dashboard: 
fac/dev-dashboard: ## Usage
fac/dev-dashboard: 
fac/dev-dashboard: Ensure you have `pkg-config` installed by running `brew install pkg-config`
fac/dev-dashboard: 
...
```

This prefixed out is also handy for piping into grep and friends. e.g. to (somewhat randomly) find all the repos we use a ruby table gem in:
```
> ./gh-repo-scan cat -C1000 --path=Gemfile | grep table
fac/freeagent: gem "terminal-table"
fac/api-service: gem 'terminal-table'
fac/jenkins-aws-images: gem 'table_print'
fac/nestor: gem 'tty-table', '~> 0.10.0'
fac/trello-archiver: gem 'terminal-table'
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake` to run all the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fac/github-scanner. Find those responsible and willing to help in `#dev-platform`.
