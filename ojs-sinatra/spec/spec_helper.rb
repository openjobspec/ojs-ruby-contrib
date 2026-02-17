# frozen_string_literal: true

require "bundler/setup"

# Stub OJS module for testing without the real gem
module OJS
  class Client
    attr_reader :url

    def initialize(url, timeout: 30, headers: {}, transport: nil)
      @url = url
    end

    def enqueue(type, args = nil, **options)
      { type: type, args: args }.merge(options)
    end
  end
end

require "sinatra/base"
require "rack/test"
require "ojs-sinatra"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus
  config.order = :random
end
