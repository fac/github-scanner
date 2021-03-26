# frozen_string_literal: true

require "github/scanner/version"
require 'github/scanner/ql'

module GitHub
module Scanner

  class Error < StandardError; end

  def self.scan(name, **kwargs)
    case name
    when :repo       then RepoScan.new(**kwargs)
    when :repo_file  then RepoScan.new("repo-file.graphql", **kwargs)
    when :repo_names then RepoScan.new("repo-names.graphql", **kwargs)
    else raise Error.new "Unknown scan: #{name}"
    end
  end

  def self.total_repos(org)
    q = GitHub::Scanner::QL.parse file: "repo-names.graphql"
    res = q.run(org: org, reposFirst: 1)
    res.data.dig('org', 'repos', 'totalCount') or raise Error.new "GitHub organisation #{org.inspect} not found!"
  end

  class RepoScan
    attr_accessor :org, :all, :archived, :limit

    attr_reader :total, :scanned, :matched

    # Init a new scanner. Optionally set the query and some common options.
    # Note that this call with silently ignore any keyword args it doesn't
    # handle. This is to make it easy to init from the command line parser.
    # e.g. Scan.new **@opts.to_h
    def initialize(query_file = "repo.graphql", org: nil, all: false, archived: false, limit: nil, **kwargs)
      @org      = org
      @all      = all
      @archived = archived
      @limit    = limit

      @filters = []
      add_filter { |r| @all || r['isArchived'] == @archived }

      load_query(query_file)
    end

    def load_query(qfile)
      @query = QL.parse file: qfile
    end

    def run(vars={})
      vars = { org: @org }.merge(vars)
      @total = Scanner.total_repos(@org) # tests org exists, raises if not

      @scanned, @matched = 0, 0
      Enumerator.new do |yielder|
        @query.paginate('org', 'repos', **vars).each do |repo|
          break if @limit && @matched >= @limit
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
      self
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
