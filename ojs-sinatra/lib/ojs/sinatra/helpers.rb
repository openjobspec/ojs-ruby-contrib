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
    end
  end
end
