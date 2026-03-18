# frozen_string_literal: true

module OJS
  module Sinatra
    # Helper methods available in Sinatra route blocks.
    module Helpers
      # Returns the configured OJS client, creating one if needed.
      #
      # @return [OJS::Client]
      def ojs_client
        settings.ojs_client ||= OJS::Client.new(settings.ojs_url)
      end

      # Enqueue a job via the OJS client.
      #
      # @param type [String] the job type
      # @param args [Array] the job arguments
      # @param queue [String] the queue name (default: "default")
      # @param options [Hash] additional OJS enqueue options
      # @return [Hash] the enqueue response
      def enqueue_job(type, args, queue: "default", **options)
        ojs_client.enqueue(type, args, queue: queue, **options)
      end

      # Enqueue multiple jobs at once.
      #
      # @param jobs [Array<Hash>] list of job hashes, each containing
      #   +:type+, +:args+, and optional +:queue+ / other options
      # @return [Array<Hash>] enqueue responses
      def enqueue_batch(jobs)
        ojs_client.enqueue_batch(jobs)
      end

      # Cancel a previously enqueued job.
      #
      # @param job_id [String] the job identifier
      # @return [Hash] the cancellation response
      def cancel_job(job_id)
        ojs_client.cancel(job_id)
      end

      # Retrieve the current status of a job.
      #
      # @param job_id [String] the job identifier
      # @return [Hash] the job details
      def get_job(job_id)
        ojs_client.get_job(job_id)
      end

      # Access the OJS worker instance (if enabled).
      #
      # @return [OJS::Sinatra::Worker, nil]
      def ojs_worker
        settings.respond_to?(:ojs_worker) ? settings.ojs_worker : nil
      end
    end
  end
end
