# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
  add_filter '/sig/'
  enable_coverage :branch
  minimum_coverage line: 90, branch: 90
end

require 'jp_address_complement'
require_relative 'support/database_helper'
require_relative 'support/fake_postal_code_repository'

DatabaseHelper.setup

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed

  config.before(:each, :db) do
    DatabaseHelper.clean
  end
end
