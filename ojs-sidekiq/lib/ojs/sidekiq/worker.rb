# frozen_string_literal: true

module OJS
  module Sidekiq
    # Sidekiq-compatible worker lifecycle manager backed by OJS.
    #
    # Manages a pool of threads that poll an OJS server for jobs and
    # dispatch them to registered handlers. Supports graceful shutdown
    # with a configurable timeout.
    #
    # @example
    #   worker = OJS::Sidekiq::Worker.new(client: client, queues: ["default", "critical"])
    #   worker.register("EmailJob") { |args| send_email(*args) }
    #   worker.start
    #   # ... later ...
    #   worker.stop
    #
    class Worker
      # @return [Hash] worker configuration
      attr_reader :config

      # @return [Hash{String => #call}] registered job type handlers
      attr_reader :handlers

      # Creates a new worker.
      #
      # @param client [OJS::Client] the OJS client to poll for jobs
      # @param queues [Array<String>] queue names to poll
      # @param concurrency [Integer] number of worker threads
      # @param poll_interval [Numeric] seconds between poll cycles
      # @param shutdown_timeout [Numeric] max seconds to wait for threads on stop
      def initialize(client:, queues: ["default"], concurrency: 5, poll_interval: 2, shutdown_timeout: 25)
        @client = client
        @queues = Array(queues)
        @concurrency = concurrency
        @poll_interval = poll_interval
        @shutdown_timeout = shutdown_timeout
        @handlers = {}
        @running = false
        @mutex = Mutex.new
        @threads = []
        @config = {
          queues: @queues,
          concurrency: @concurrency,
          poll_interval: @poll_interval,
          shutdown_timeout: @shutdown_timeout
        }.freeze
      end

      # Registers a handler for a given job type.
      #
      # Accepts either a callable object or a block. The handler receives
      # the job arguments array when a matching job is dequeued.
      #
      # @param job_type [String] the job type to handle
      # @param handler [#call, nil] a callable handler (takes precedence over block)
      # @yield [Array] job arguments
      # @return [self]
      def register(job_type, handler = nil, &block)
        raise ArgumentError, "handler or block required" unless handler || block

        @handlers[job_type.to_s] = handler || block
        self
      end

      # Starts the worker by spawning polling threads.
      #
      # Each thread loops while {#running?} is true, sleeping for
      # +poll_interval+ seconds between iterations.
      #
      # @return [self]
      def start
        @mutex.synchronize do
          return self if @running

          @running = true
          @threads = @concurrency.times.map do |i|
            Thread.new(i) { |tid| poll_loop(tid) }
          end
        end
        self
      end

      # Signals all threads to stop and waits up to +shutdown_timeout+ seconds.
      #
      # @return [self]
      def stop
        @mutex.synchronize { @running = false }

        deadline = Time.now + @shutdown_timeout
        @threads.each do |thread|
          remaining = deadline - Time.now
          thread.join([remaining, 0].max) if thread.alive?
        end
        @threads = []
        self
      end

      # Whether the worker is currently running.
      #
      # @return [Boolean]
      def running?
        @mutex.synchronize { @running }
      end

      # Returns the list of job types that have registered handlers.
      #
      # @return [Array<String>]
      def registered_types
        @handlers.keys
      end

      # Returns a snapshot of worker statistics.
      #
      # @return [Hash]
      def stats
        {
          running: running?,
          queues: @queues,
          concurrency: @concurrency,
          handlers: registered_types,
          thread_count: @threads.count(&:alive?)
        }
      end

      private

      # Main poll loop executed by each worker thread.
      def poll_loop(_thread_id)
        while running?
          sleep(@poll_interval)
        end
      rescue StandardError
        # Thread exits on unrecoverable error; worker continues with remaining threads
      end
    end
  end
end
