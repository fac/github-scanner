# frozen_string_literal: true

require_relative "lib/github/scanner/version"

Gem::Specification.new do |spec|
  spec.name    = "github-scanner"
  spec.version = GitHub::Scanner::VERSION
  spec.authors = ["Mark Pitchless"]
  spec.email   = ["markpitchless@gmail.com"]

  spec.summary       = "Fast scanning of GitHub repos and their files."
  # spec.description   = "TODO: Write a longer description or delete this line."
  spec.homepage      = "https://github.com/fac/github-scanner"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/fac"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fac/github-scanner"
  spec.metadata["changelog_uri"]   = "https://github.com/orgs/fac/packages?repo_name=github-scanner"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime deps
  spec.add_dependency "slop",           "~> 4.8"
  spec.add_dependency "graphql-client", "~> 0.16.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
