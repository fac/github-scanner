# frozen_string_literal: true

require 'tmpdir'

require 'graphql/client'
require 'graphql/client/http'

module GitHub
module Scanner

# Query the GitHub GraphQL API at api.github.com/graphql.
#
# query_string = <--EOQL
# EOQL
# q   = QL.parse(query_string)
#
# res = QL.query(q, {})
# puts "Total Count: #{res.data.result.repositories.total_count}"
#
# QL.with_pagination(:repositories, 'endRepoCursor', {}).each |repo| do
#   puts repo.name
# end
#
# The module knows the details of the schema handling, download with local file
# caching. Authenticates using a GitHub personnel access token.
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

  def self.parse(...)
    client.parse(...)
  end

  def self.query(...)
    client.query(...)
  end

  def self.with_pagination(query, page_on_field, after_var, variables={})
    Enumerator.new do |yielder|
      response = query(query, variables: variables).data.result
      response.send(page_on_field).nodes.each { |node| yielder << node }

      page_info = response.send(page_on_field).page_info
      while page_info.has_next_page != false
        cursor = page_info.end_cursor
        variables[after_var] = cursor
        response = query(query, variables: variables).data.result
        response.send(page_on_field).nodes.each { |node| yielder << node }
        page_info = response.send(page_on_field).page_info
      end
    end
  end
end # QL

end # Scanner
end # GitHub
