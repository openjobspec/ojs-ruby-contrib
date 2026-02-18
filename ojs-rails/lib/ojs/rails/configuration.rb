# frozen_string_literal: true

module OJS
  module Rails
    # Configuration DSL for OJS Rails integration.
    #
    #   OJS::Rails.configure do |config|
    #     config.url = "http://localhost:8080"
    #     config.queue_prefix = Rails.env
    #     config.default_queue = "default"
    #     config.retry_policy = { max_attempts: 5, backoff: :exponential }
    #   end
    #
    class Configuration
      # @return [String] OJS server URL
      attr_accessor :url

      # @return [String, nil] prefix prepended to all queue names (e.g. "production")
      attr_accessor :queue_prefix

      # @return [String] default queue name when none is specified
      attr_accessor :default_queue

      # @return [Hash] default retry policy applied to all jobs
      attr_accessor :retry_policy

      # @return [Integer] HTTP request timeout in seconds
      attr_accessor :timeout

      # @return [Hash] additional HTTP headers sent with every request
      attr_accessor :headers

      # @return [Hash<Integer, Integer>] maps ActiveJob integer priorities to OJS priorities
      attr_accessor :priority_map

      def initialize
        @url = ENV.fetch("OJS_URL", "http://localhost:8080")
        @queue_prefix = nil
        @default_queue = "default"
        @retry_policy = {}
        @timeout = 30
        @headers = {}
        @priority_map = default_priority_map
      end

      # Resolve a queue name, applying the prefix if configured.
      #
      # @param name [String] raw queue name
      # @return [String] resolved queue name
      def resolve_queue(name)
        base = (name.nil? || name.to_s.empty?) ? @default_queue : name.to_s
        @queue_prefix ? "#{@queue_prefix}_#{base}" : base
      end

      # Map an ActiveJob priority to an OJS priority.
      #
      # ActiveJob priorities are integers where lower = higher priority.
      # OJS priorities follow the spec where higher = higher priority.
      #
      # @param active_job_priority [Integer, nil] ActiveJob priority value
      # @return [Integer, nil] OJS priority value
      def resolve_priority(active_job_priority)
        return nil if active_job_priority.nil?

        @priority_map.fetch(active_job_priority, active_job_priority)
      end

      # Build an OJS::Client from this configuration.
      #
      # @return [OJS::Client]
      def build_client
        OJS::Client.new(@url, timeout: @timeout, headers: @headers)
      end

      private

      # Default mapping: ActiveJob 0 (highest) → OJS 10, 5 → 0, 10 → -10.
      def default_priority_map
        {
          0 => 10,   # urgent
          1 => 8,
          2 => 6,
          3 => 4,
          4 => 2,
          5 => 0,    # normal
          6 => -2,
          7 => -4,
          8 => -6,
          9 => -8,
          10 => -10, # low
        }
      end
    end
  end
end
