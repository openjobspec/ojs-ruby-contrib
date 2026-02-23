# frozen_string_literal: true

require "active_job"
require "ojs/rails/active_job/adapter"

module OJS
  module Rails
    # Convenience entry point for the ActiveJob adapter.
    #
    # This module provides a standalone interface for enqueuing ActiveJob jobs
    # through OJS without relying solely on ActiveJob's queue_adapter config.
    #
    # For standard usage, set the adapter in config/application.rb:
    #
    #   config.active_job.queue_adapter = :ojs
    #
    # For programmatic access:
    #
    #   adapter = OJS::Rails::ActiveJobAdapter.new
    #   adapter.enqueue(MyJob.new(user.id))
    #
    class ActiveJobAdapter
      # Enqueue a job for immediate execution.
      #
      # Maps ActiveJob attributes to OJS envelope fields:
      # - job class name → OJS `type` (underscored dot notation)
      # - job arguments   → OJS `args`
      # - queue_name      → OJS `queue` (with optional prefix)
      # - priority        → OJS `priority` (mapped via config)
      #
      # @param job [ActiveJob::Base] the job to enqueue
      # @return [void]
      def enqueue(job)
        ojs_job = client.enqueue(
          job_type(job),
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
          job_type(job),
          serialize_arguments(job),
          scheduled_at: Time.at(timestamp).utc.iso8601,
          **enqueue_options(job)
        )
        job.provider_job_id = ojs_job.respond_to?(:id) ? ojs_job.id : nil
      end

      private

      # Convert ActiveJob class name to OJS type using underscore dot notation.
      #
      # Examples:
      #   SendEmailJob       → "send_email"
      #   Billing::ChargeJob → "billing.charge"
      #   UserMailer         → "user_mailer"
      #
      # @param job [ActiveJob::Base]
      # @return [String]
      def job_type(job)
        name = job.class.name
        name
          .gsub(/Job$/, "")
          .gsub("::", ".")
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
      end

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
        meta["queue_name"] = job.queue_name
        meta
      end

      # Serialize ActiveJob arguments. Passes through the raw arguments so the
      # worker can deserialize via ActiveJob's GlobalID-based serialization.
      #
      # @param job [ActiveJob::Base]
      # @return [Array]
      def serialize_arguments(job)
        job.arguments
      end

      def client
        OJS::Rails.client || raise(
          OJS::Rails::Error,
          "OJS client not configured. Run `rails generate ojs:install` or " \
          "configure in an initializer with OJS::Rails.configure { |c| c.url = '...' }"
        )
      end
    end
  end
end
