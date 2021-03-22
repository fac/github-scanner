# frozen_string_literal: true

require "github/scanner/version"
require 'github/scanner/ql'

module GitHub
module Scanner

  class Error < StandardError; end

  def self.scan(name)
    case name
    when :repo;      Scan.new()
    when :repo_file; Scan.new(query_file: "repo-file.graphql")
    else
      raise Error("Unknown scan: #{name}")
    end
  end

  def self.total_repos
    q = GitHub::Scanner::QL.parse file: "repo-names.graphql"
    q.run(repoFirst: 1).data.dig 'org', 'repos', 'totalCount'
  end

  class Scan
    attr_accessor :all, :archived

    attr_reader :scanned, :matched

    def initialize(query_file: "repo.graphql", all: false, archived: false)
      @filters  = []
      @all      = all
      @archived = archived
      add_filter { |r| @all || r['isArchived'] == @archived }

      @query = QL.parse file: query_file
    end

    def run(vars={})
      @scanned = 0
      @matched = 0

      Enumerator.new do |yielder|
        repos = @query.run(vars).paginate('result', 'repositories', after: 'repoEndCursor')
        repos.each do |repo|
          @scanned += 1
          next unless repo_filter(repo)
          @matched += 1
          yielder << repo
        rescue => err
          STDERR.puts "ERROR: #{err}"
          STDERR.puts JSON.pretty_generate(repo)
          raise err
        end
      end
    end

    def add_filter(&filt)
      @filters.push filt
    end

    def repo_filter(repo)
      @filters.each { |f| return false unless f.call(repo) }
      true
    end

    def inflate(res)
      # Inflate up to a hash repo.name:"", file.path:""
    end
  end

end # Scanner
end # GitHub
