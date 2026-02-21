# frozen_string_literal: true

require "bundler/setup"

# Stub OJS module for testing without the real gem
module OJS
  class Client
    attr_reader :url

    def initialize(url, timeout: 30, headers: {}, transport: nil)
      @url = url
      @timeout = timeout
      @headers = headers
    end

    def enqueue(type, args = nil, **options)
      OpenStruct.new(id: "test-job-id", type: type, args: args, **options)
    end

    def enqueue_batch(jobs)
      jobs.map do |spec|
        OpenStruct.new(id: "batch-#{spec[:type]}", type: spec[:type], args: spec[:args])
      end
    end
  end

  class Error < StandardError
    attr_reader :code, :retryable

    def initialize(message = nil, code: nil, retryable: false, **_kwargs)
      @code = code
      @retryable = retryable
      super(message)
    end

    def retryable?
      @retryable
    end
  end

  class ConnectionError < Error
    def initialize(message = "Connection failed", **kwargs)
      super(message, retryable: true, **kwargs)
    end
  end

  class TimeoutError < Error
    def initialize(message = "Request timed out", **kwargs)
      super(message, code: "timeout", retryable: true, **kwargs)
    end
  end

  class ValidationError < Error
    def initialize(message = "Validation failed", **kwargs)
      super(message, code: "invalid_request", retryable: false, **kwargs)
    end
  end

  class ConflictError < Error
    def initialize(message = "Conflict", **kwargs)
      super(message, code: "duplicate", retryable: false, **kwargs)
    end
  end
end

# Minimal Rails stubs for unit testing
require "ostruct"

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

  module Concern
    def self.extended(base); end

    def included(base = nil, &block)
      if block
        @_included_block = block
      elsif base
        @_included_block&.call
      end
      super(base) if base
    end

    def class_methods(&block); end
  end
end

module ActiveJob
  class Base
    attr_accessor :job_id, :queue_name, :arguments, :priority, :provider_job_id,
                  :executions, :locale

    def initialize
      @job_id = "test-#{SecureRandom.hex(4)}"
      @queue_name = "default"
      @arguments = []
      @priority = nil
      @executions = 0
      @locale = "en"
    end

    def self.name
      super
    end
  end

  module QueueAdapters; end
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
    OJS::Rails.reset!
    OJS::Rails.client = OJS::Client.new("http://localhost:8080")
  end
end

