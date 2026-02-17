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

# Minimal Rails stubs for unit testing
module ActiveSupport
  class OrderedOptions < Hash
    def method_missing(name, *args)
      if name.to_s.end_with?("=")
        self[name.to_s.chomp("=").to_sym] = args.first
      else
        self[name.to_sym]
      end
    end

    def respond_to_missing?(*)
      true
    end
  end
end

require "ojs-rails"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus
  config.order = :random

  config.before do
    OJS::Rails.client = OJS::Client.new("http://localhost:8080")
  end
end
