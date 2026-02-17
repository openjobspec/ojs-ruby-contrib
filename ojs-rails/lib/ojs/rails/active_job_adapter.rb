# frozen_string_literal: true

require "active_job"

module ActiveJob
  module QueueAdapters
    # ActiveJob adapter that uses Open Job Spec as the backend.
    #
    # To use:
    #   config.active_job.queue_adapter = :ojs
    #
    class OjsAdapter
      def enqueue(job)
        client.enqueue(
          job.class.name,
          job.arguments,
          queue: job.queue_name,
          meta: {
            "active_job_id" => job.job_id,
            "priority" => job.priority
          }
        )
      end

      def enqueue_at(job, timestamp)
        client.enqueue(
          job.class.name,
          job.arguments,
          queue: job.queue_name,
          scheduled_at: Time.at(timestamp).utc.iso8601,
          meta: {
            "active_job_id" => job.job_id,
            "priority" => job.priority
          }
        )
      end

      private

      def client
        OJS::Rails.client || raise(OJS::Rails::Error, "OJS client not configured. Add an initializer or use the Railtie.")
      end
    end
  end
end
