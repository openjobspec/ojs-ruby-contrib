# frozen_string_literal: true

module OJS
  module Rails
    # Rack middleware for request-scoped job enqueueing.
    #
    # Collects jobs during a request and flushes them after the response,
    # ensuring jobs are only enqueued for successful requests.
    #
    # Add to your middleware stack:
    #   config.middleware.use OJS::Rails::Middleware
    #
    # Then enqueue jobs through the request buffer:
    #   OJS::Rails::Middleware.enqueue("email.send", [user.id])
    #
    class Middleware
      THREAD_KEY = :ojs_rails_request_buffer

      def initialize(app)
        @app = app
      end

      def call(env)
        Thread.current[THREAD_KEY] = []
        status, headers, body = @app.call(env)

        flush_buffer! if status < 500
        [status, headers, body]
      rescue StandardError => e
        clear_buffer!
        raise e
      ensure
        clear_buffer!
      end

      class << self
        # Buffer a job for enqueue after the request completes.
        #
        # @param type [String] OJS job type
        # @param args [Array] job arguments
        # @param options [Hash] additional OJS enqueue options
        def enqueue(type, args = [], **options)
          buffer = Thread.current[THREAD_KEY]
          if buffer
            buffer << { type: type, args: args, **options }
          else
            # No active request — enqueue immediately
            OJS::Rails::Enqueue.enqueue_now(type, args, **options)
          end
        end

        # Check if a request buffer is active.
        #
        # @return [Boolean]
        def buffering?
          !Thread.current[THREAD_KEY].nil?
        end

        # Return the number of buffered jobs in the current request.
        #
        # @return [Integer]
        def buffer_size
          buffer = Thread.current[THREAD_KEY]
          buffer ? buffer.size : 0
        end
      end

      private

      def flush_buffer!
        buffer = Thread.current[THREAD_KEY]
        return if buffer.nil? || buffer.empty?

        client = OJS::Rails.client
        return unless client

        if buffer.size == 1
          job = buffer.first
          client.enqueue(job[:type], job[:args], **job.except(:type, :args))
        else
          client.enqueue_batch(buffer)
        end
      end

      def clear_buffer!
        Thread.current[THREAD_KEY] = nil
      end
    end
  end
end

