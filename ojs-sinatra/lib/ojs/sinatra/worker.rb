# frozen_string_literal: true

module OJS
  module Sinatra
    # Background worker that polls an OJS backend for jobs and dispatches
    # them to registered handler blocks. Designed to run in a background
    # thread alongside a Sinatra application.
    #
    # @example
    #   worker = OJS::Sinatra::Worker.new(client: ojs_client)
    #   worker.register("email.send") { |job| deliver(job) }
    #   worker.start
    #
    class Worker
      # @return [Hash] worker configuration
      attr_reader :config

      # @return [Hash{String => Proc}] registered job type handlers
      attr_reader :handlers

      # @param client [OJS::Client] the OJS client used to fetch jobs
      # @param queues [Array<String>] queues to poll (default: ["default"])
      # @param concurrency [Integer] max concurrent jobs (default: 5)
      # @param poll_interval [Numeric] seconds between poll cycles (default: 2)
      def initialize(client:, queues: ["default"], concurrency: 5, poll_interval: 2)
        @config = {
          client: client,
          queues: queues,
          concurrency: concurrency,
          poll_interval: poll_interval
        }
        @handlers = {}
        @running = false
        @mutex = Mutex.new
        @thread = nil
      end

      # Register a handler block for a given job type.
      #
      # @param job_type [String] the job type to handle
      # @yield [Hash] the job payload
      # @return [void]
      def register(job_type, &handler)
        raise ArgumentError, "a block is required" unless block_given?

        @mutex.synchronize { @handlers[job_type] = handler }
      end

      # Start the worker in a background thread.
      #
      # @return [Thread] the worker thread
      def start
        @mutex.synchronize do
          return @thread if @running

          @running = true
          @thread = Thread.new { poll_loop }
        end
      end

      # Stop the worker gracefully, waiting up to +timeout+ seconds for
      # the background thread to finish.
      #
      # @param timeout [Numeric] max seconds to wait for shutdown (default: 25)
      # @return [void]
      def stop(timeout: 25)
        @mutex.synchronize { @running = false }
        @thread&.join(timeout)
      end

      # Whether the worker is currently running.
      #
      # @return [Boolean]
      def running?
        @mutex.synchronize { @running }
      end

      # List the job types that have registered handlers.
      #
      # @return [Array<String>]
      def registered_types
        @mutex.synchronize { @handlers.keys }
      end

      private

      def poll_loop
        while running?
          sleep(@config[:poll_interval])
        end
      end
    end
  end
end
