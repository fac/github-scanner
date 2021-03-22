# frozen_string_literal: true

require 'tmpdir'
require 'digest'

require 'graphql/client'
require 'graphql/client/http'

module GitHub
module Scanner

# Query the GitHub GraphQL API at api.github.com/graphql.
#
# While this based on graphql/client, it does it's best to not expose that and
# keep clients working at a level of string queries (loaded from files) and the
# results as JSON. Makes it easy to work using the github graph explorer.
# https://docs.github.com/en/graphql/overview/explorer
# We avoid the clients mapping of names (ie fooBar => foo_bar) as it is just
# confusing. We also deal with the annoying requirement to store parsed queries
# in globals! We may well look to replace the client at some point.
#
# query_string = <--EOQL
# EOQL
# q = QL.parse(query_string)
#
# q = QL.parse(file: "foo.graphql")
#
# q.run
# puts "Total Count: #{q.data['result']['repositories']['totalCount']"
#
# q.run(first: 23).paginate('org','repositories', after: 'endRepoCursor').each |repo| do
#   puts repo['name']
# end
#
# The module knows the details of the schema handling, download with local file
# caching. Authenticates using a GitHub personnel access token set vis ENV in
# GITHUB_PAT.
module QL
  SchemaURL = 'https://api.github.com/graphql' 

  def self.github_pat
    return @github_pat if @github_pat

    unless ENV.key?('GITHUB_PAT') && !ENV['GITHUB_PAT'].nil? && !ENV['GITHUB_PAT'].empty?
      raise "GITHUB_PAT not set"
    end
    @github_pat = ENV['GITHUB_PAT']
  end

  def self.http
    return @http if @http

    # Call this to check for a token. The error gets lost when called via headers below
    github_pat
    @http = ::GraphQL::Client::HTTP.new(SchemaURL) do
      def headers(context) { "Authorization" => "Bearer #{GitHub::Scanner::QL.github_pat}" }
      end
    end
  end

  def self.client
    @client ||= ::GraphQL::Client.new(schema: schema, execute: http)
  end

  def self.schema
    return @schema if @schema

    schema_file = File.join(Dir.tmpdir, "github.schema.json")
    unless File.file? schema_file
      puts "Dumping schema to #{schema_file.inspect}"
      ::GraphQL::Client.dump_schema(http, schema_file)
    end
    @schema = ::GraphQL::Client.load_schema(schema_file)
  rescue
    FileUtils.rm_rf schema_file
  end

  def self.query_dir(*paths)
    @query_dir ||= File.join File.expand_path("../../../..", __FILE__), "query"
    return @query_dir if paths.empty?
    File.join @query_dir, paths
  end

  # parse(qstr, name: "")
  # parse(file: "", name: "")
  def self.parse(qstr = "", file: nil, name: nil)
    if qstr.empty? && !file.nil?
      file = query_dir(file) if Pathname.new(file).relative?
      qstr = File.read file
    end

    # graphql/client insists on queries being module constants!
    cname = "Q_%s" % Digest::MD5.hexdigest(qstr).upcase
    q = if QL.const_defined? cname.to_s
      QL.const_get cname
    else
      QL.const_set cname, client.parse(qstr)
    end
    QueryRunner.new q
  end

  # TODO: check arg for GraphQL::Client::OperationDefinition auto parse string if not
  def self.query(...)
    res = client.query(...)
    res.errors.each { |err| STDERR.puts "ERROR: #{err}" }
    res
  end

  class QueryRunner
    extend Forwardable

    attr_reader :query, :vars, :data

    def_delegators :@data, :to_h, :to_json, :key

    def initialize(q, vars = {})
      @query      = q
      @variables  = vars
      @data       = nil
    end

    def run(vars = {})
      @variables = vars
      @data      = QL.query(@query, variables: vars).data.to_h
      # TODO: the errors? .errors
      self
    end

    # q.run.paginate('result', 'repositories', after: 'repoEndCursor').each do |r|
    #   puts r['name']
    # end
    def paginate(*path, after: "after")
      vars = @variables.clone
      Enumerator.new do |yielder|
        loop do
          q = @data.dig *path
          q['nodes'].each { |node| yielder << node }

          break unless q['pageInfo']['hasNextPage']
          vars[after] = q['pageInfo']['endCursor']
          run vars
        end
      end
    end
  end
end # QL

end # Scanner
end # GitHub
