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
# q = QL.parse(file: "repo.graphql")
#
# puts "Total: %s" % q.run.data['result']['repositories']['totalCount']
#
# q.paginate('org', 'repos', org: "fac").each |repo| do
#   puts repo['name']
# end
#
# The module knows the details of the schema handling, download with local file
# caching. Authenticates using a GitHub personnel access token set via ENV in
# GITHUB_PAT. Will raise an error if this is not set when trying to connect.
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

  # Parse a query string or file containing graphql against the GitHub schema.
  # Returns a QL::Query instance you can use to run the query and get data.
  #
  # q = parse(qstr)
  # q = parse(file: "", name: "")
  #
  # If the file path is relative, loads queries from the query directory in the
  # GitHub::Scanner distrib.
  def self.parse(qstr = "", file: nil)
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
    Query.new q
  end

  # Run parsed queries. This is lower level call direct to the client, normally
  # you should run queries via the Query object.
  # TODO: check arg for GraphQL::Client::OperationDefinition auto parse string if not
  def self.query(...)
    client.query(...)
  end

  # Query instances are parsed graphql queries, with methods to run and paginate.
  #
  # Holds a set of defaults for the query variables, that are merged with the
  # variables passed to run or paginate.
  #
  # The Query class is does not hold any state from running, returning a Result
  # object or Enumerator for paging.
  class Query
    attr_reader :query, :variables

    def initialize(q, vars = {})
      @query      = q
      @variables  = vars
    end

    # Run the query and return the Result.
    def run(vars = {})
      Result.new QL.query(@query, variables: @variables.clone.merge(vars))
    end

    # Paginate through a paged result. That is, a node list from a query with
    # pageInfo, with minimum hasNextPage and endCursor fields selected.
    #
    # The after: arg sets the name of the query variable that sets the after
    # param on query you are paging. e.g.
    #
    # Any other keyword args are used as query parameters. You can also pass a
    # hash explicitly in variables:. Keyword args are merged into variables if
    # both are present.
    #
    # query ($org: String="", $reposFirst: Int = 50, $reposAfter: String) {
    #   org: organization(login: $org) {
    #     repos: repositories(first: $reposFirst, after: $reposAfter) {
    #       pageInfo {
    #         hasNextPage
    #         endCursor
    #       }
    #
    # q.run.paginate('org', 'repos', after: 'reposAfter', org: "fac").each do |r|
    #   puts r['name']
    # end
    #
    # If you don't set the after variable, paginate will guess by postfixing
    # the last part of the path with "After". e.g.
    #
    # q.run.paginate('org', 'repos', org: "fac").each do |r|  # after: reposAfter
    #
    def paginate(*path, after: "", variables: {}, **kwvars)
      after = "#{path[-1]}After" if after.empty?
      vars  = @variables.clone.merge(variables).merge(kwvars)
      Enumerator.new do |yielder|
        loop do
          res = run vars
          q   = res.data.dig(*path) or break
          # TODO: throw here? raise "No pageInfo found for path: #{path.join('.')} data:#{res.to_json}"
          # This exception is a pita to debug/catch. Can't do it in run, needs to be at run call site.

          q['nodes'].each { |node| yielder.yield node, res }

          break unless q['pageInfo']['hasNextPage']
          vars[after] = q['pageInfo']['endCursor']
        end
      end
    end
  end

  # Result encapsulates the result from running a query and provides access to
  # the data (while hiding the graphql/client from users).
  class Result
    extend Forwardable

    attr_reader :data, :errors

    def_delegators :@data, :to_h, :to_json, :key

    def initialize(res)
      @result = res
      @data   = res.data.to_h
      # We get the std message, path, locations keys plus GH add extra type key.
      @errors = @result.to_h['errors'] if @result.to_h.key? 'errors'
    end
  end
end # QL

end # Scanner
end # GitHub
