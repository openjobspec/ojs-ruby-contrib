# frozen_string_literal: true

require "active_job"

module ActiveJob
  module QueueAdapters
    # ActiveJob adapter that uses Open Job Spec as the backend.
    #
    # To use:
    #   config.active_job.queue_adapter = :ojs
    #
    # This adapter maps ActiveJob jobs to OJS job envelopes:
    # - Job class name becomes the OJS job type
    # - ActiveJob arguments are serialized as OJS args array
    # - Queue names are resolved through OJS::Rails::Configuration (with optional prefix)
    # - ActiveJob priorities are mapped to OJS priorities
    # - Scheduled jobs use OJS scheduled_at
    # - Retry policies from configuration are applied as defaults
    #
    class OjsAdapter
      # Enqueue a job for immediate execution.
      #
      # @param job [ActiveJob::Base] the job to enqueue
      # @return [void]
      def enqueue(job)
        ojs_job = client.enqueue(
          job.class.name,
          serialize_arguments(job),
          **enqueue_options(job)
        )
        job.provider_job_id = ojs_job.respond_to?(:id) ? ojs_job.id : nil
      end

      # Enqueue a job for execution at a specific time.
      #
      # @param job [ActiveJob::Base] the job to enqueue
      # @param timestamp [Float] Unix timestamp for scheduled execution
      # @return [void]
      def enqueue_at(job, timestamp)
        ojs_job = client.enqueue(
          job.class.name,
          serialize_arguments(job),
          scheduled_at: Time.at(timestamp).utc.iso8601,
          **enqueue_options(job)
        )
        job.provider_job_id = ojs_job.respond_to?(:id) ? ojs_job.id : nil
      end

      private

      def enqueue_options(job)
        config = OJS::Rails.configuration

        opts = {
          queue: config.resolve_queue(job.queue_name),
          meta: build_meta(job),
        }

        priority = config.resolve_priority(job.priority)
        opts[:priority] = priority unless priority.nil?

        retry_policy = config.retry_policy
        opts[:retry] = retry_policy unless retry_policy.nil? || retry_policy.empty?

        opts
      end

      def build_meta(job)
        meta = {
          "active_job_id" => job.job_id,
          "active_job_class" => job.class.name,
        }
        meta["executions"] = job.executions if job.executions > 0
        meta["locale"] = job.locale if job.respond_to?(:locale) && job.locale
        meta
      end

      # Serialize ActiveJob arguments into an OJS-compatible args array.
      # ActiveJob uses GlobalID-based serialization; we pass through the
      # serialized form so the worker can deserialize via ActiveJob.
      def serialize_arguments(job)
        job.arguments
      end

      def client
        OJS::Rails.client || raise(
          OJS::Rails::Error,
          "OJS client not configured. Run `rails generate ojs:install` or configure in an initializer."
        )
      end
    end
  end
end
