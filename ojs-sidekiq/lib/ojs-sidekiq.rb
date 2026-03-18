# frozen_string_literal: true

require "ojs"
require "ojs/sidekiq/adapter"
require "ojs/sidekiq/migration"
require "ojs/sidekiq/compat"
require "ojs/sidekiq/worker"
require "ojs/sidekiq/event_bridge"

module OJS
  module Sidekiq
    class Error < StandardError; end

    class << self
      attr_accessor :client

      # @return [OJS::Sidekiq::Worker, nil] the configured worker instance
      attr_accessor :worker

      # @return [OJS::Sidekiq::EventBridge, nil] the configured event bridge
      attr_accessor :event_bridge

      # Yields self for configuration.
      #
      # @yield [OJS::Sidekiq] the module for configuration
      def configure
        yield self if block_given?
      end

      # Creates and configures a worker instance.
      #
      # @param queues [Array<String>] queue names to poll
      # @param concurrency [Integer] number of worker threads
      # @param poll_interval [Numeric] seconds between poll cycles
      # @param shutdown_timeout [Numeric] max seconds to wait on stop
      # @return [OJS::Sidekiq::Worker]
      # @raise [OJS::Sidekiq::Error] if client is not configured
      def setup_worker(queues: ["default"], concurrency: 5, poll_interval: 2, shutdown_timeout: 25)
        raise Error, "OJS client not configured" unless client

        self.worker = Worker.new(
          client: client,
          queues: queues,
          concurrency: concurrency,
          poll_interval: poll_interval,
          shutdown_timeout: shutdown_timeout
        )
      end
    end
  end
end
