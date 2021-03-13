# frozen_string_literal: true

require_relative "../test_helper"

class GitHub::ScannerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::GitHub::Scanner::VERSION
  end

  # TODO: more tests
end
