# frozen_string_literal: true

module OJS
  module Sidekiq
    # Compatibility layer providing top-level Sidekiq-style methods backed by OJS.
    #
    # This module can be used to provide global perform_async, perform_in,
    # and perform_at without requiring a job class.
    module Compat
      module_function

      # Enqueue a job by type name for immediate execution.
      #
      # @param type [String] the job type
      # @param args [Array] job arguments
      # @param queue [String] the queue name (default: "default")
      # @return [Hash] enqueue response
      def perform_async(type, *args, queue: "default")
        client.enqueue(type, args, queue: queue)
      end

      # Enqueue a job by type name for execution after a delay.
      #
      # @param type [String] the job type
      # @param interval [Numeric] seconds to wait
      # @param args [Array] job arguments
      # @param queue [String] the queue name (default: "default")
      # @return [Hash] enqueue response
      def perform_in(type, interval, *args, queue: "default")
        scheduled_at = (Time.now.utc + interval).iso8601
        client.enqueue(type, args, queue: queue, scheduled_at: scheduled_at)
      end

      # Enqueue a job by type name for execution at a specific time.
      #
      # @param type [String] the job type
      # @param time [Time] when to execute
      # @param args [Array] job arguments
      # @param queue [String] the queue name (default: "default")
      # @return [Hash] enqueue response
      def perform_at(type, time, *args, queue: "default")
        client.enqueue(type, args, queue: queue, scheduled_at: time.utc.iso8601)
      end

      def client
        OJS::Sidekiq.client || raise(OJS::Sidekiq::Error, "OJS client not configured")
      end
      private_class_method :client
    end
  end
end
