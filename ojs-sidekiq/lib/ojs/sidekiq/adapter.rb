# frozen_string_literal: true

module OJS
  module Sidekiq
    # Drop-in replacement for Sidekiq::Job. Include this module in your job
    # classes to use OJS as the backend while keeping the Sidekiq-compatible API.
    #
    # Usage:
    #   class MyJob
    #     include OJS::Sidekiq::Job
    #     sidekiq_options queue: "critical", retry: 5
    #
    #     def perform(user_id)
    #       # job logic
    #     end
    #   end
    #
    #   MyJob.perform_async(123)
    #
    module Job
      def self.included(base)
        base.extend(ClassMethods)
        base.instance_variable_set(:@sidekiq_options, { "queue" => "default", "retry" => 25 })
      end

      # Class methods added to job classes that include OJS::Sidekiq::Job.
      module ClassMethods
        # Configure Sidekiq-compatible options.
        #
        # @param opts [Hash] options hash (queue, retry, etc.)
        def sidekiq_options(opts = {})
          @sidekiq_options = @sidekiq_options.merge(opts.transform_keys(&:to_s))
        end

        # Get the current options.
        #
        # @return [Hash]
        def get_sidekiq_options
          @sidekiq_options
        end

        # Enqueue a job for immediate execution.
        #
        # @param args [Array] job arguments
        # @return [Hash] enqueue response
        def perform_async(*args)
          client = OJS::Sidekiq.client || raise(OJS::Sidekiq::Error, "OJS client not configured")
          client.enqueue(
            name,
            args,
            queue: @sidekiq_options["queue"]
          )
        end

        # Enqueue a job for execution after a delay.
        #
        # @param interval [Numeric] seconds to wait
        # @param args [Array] job arguments
        # @return [Hash] enqueue response
        def perform_in(interval, *args)
          scheduled_at = (Time.now.utc + interval).iso8601
          client = OJS::Sidekiq.client || raise(OJS::Sidekiq::Error, "OJS client not configured")
          client.enqueue(
            name,
            args,
            queue: @sidekiq_options["queue"],
            scheduled_at: scheduled_at
          )
        end

        # Enqueue a job for execution at a specific time.
        #
        # @param time [Time] when to execute
        # @param args [Array] job arguments
        # @return [Hash] enqueue response
        def perform_at(time, *args)
          client = OJS::Sidekiq.client || raise(OJS::Sidekiq::Error, "OJS client not configured")
          client.enqueue(
            name,
            args,
            queue: @sidekiq_options["queue"],
            scheduled_at: time.utc.iso8601
          )
        end
      end
    end
  end
end
