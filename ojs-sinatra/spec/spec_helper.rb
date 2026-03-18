# frozen_string_literal: true

require "bundler/setup"
require "sinatra/base"
require "rack/test"
require "ojs-sinatra"

# Override OJS::Client with a test stub after the real gem is loaded
module OJS
  class Client
    attr_reader :url

    def initialize(url, timeout: 30, headers: {}, transport: nil)
      @url = url
    end

    def enqueue(type, args = nil, **options)
      { type: type, args: args }.merge(options)
    end

    def enqueue_batch(jobs)
      jobs.map { |job| { type: job[:type], args: job[:args], queue: job[:queue] || "default" } }
    end

    def cancel(job_id)
      { id: job_id, state: "cancelled" }
    end

    def get_job(job_id)
      { id: job_id, state: "active", type: "test.job" }
    end
  end
end

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
