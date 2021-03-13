# frozen_string_literal: true

require "github/scanner/version"
require 'github/scanner/ql'

module GitHub
module Scanner

  class Error < StandardError; end

  RepoQuery = QL.parse <<-GRAPHQL
    query ($repoEndCursor: String, $repoFirst: Int=10, $filePath: String="Jenkinsfile") {
      result: organization(login: "fac") {
        repositories(first: $repoFirst, after: $repoEndCursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
          totalCount
          nodes {
              name
              nameWithOwner
              isArchived
              defaultBranch: defaultBranchRef {
              target {
                  ... on Commit {
                  authoredDate
                  author {
                      name
                      email
                  }
                  oid
                  file(path: $filePath) {
                      name
                      path
                      type
                      object {
                      ... on Blob {
                          id
                          text
                      }
                    }
                  }
                }
              }
              name
            }
          }
        }
      }
    }
  GRAPHQL

  def self.new(...)
    Scan.new(...)
  end

  class Scan
    def repo_query(**vars)
      QL.query(RepoQuery, variables: vars)
    end

    def repositories(variables={})
      Enumerator.new do |yielder|
        repos = QL.with_pagination(
          RepoQuery, :repositories, 'repoEndCursor', variables)
        repos.each do |repo|
          yielder << repo
        end
      end
    end

    alias :repos :repositories
  end

end # Scanner
end # GitHub
