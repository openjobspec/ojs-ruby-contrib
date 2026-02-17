# frozen_string_literal: true

module OJS
  module Rails
    # Provides transactional enqueue using ActiveRecord after_commit callbacks.
    #
    # Ensures jobs are only enqueued after the database transaction commits,
    # preventing phantom jobs when transactions roll back.
    module Enqueue
      module_function

      # Enqueue a job after the current transaction commits.
      #
      # @param type [String] the job type
      # @param args [Array] the job arguments
      # @param queue [String] the queue name (default: "default")
      # @param options [Hash] additional OJS enqueue options
      def after_commit(type, args, queue: "default", **options)
        if defined?(ActiveRecord::Base) &&
           ActiveRecord::Base.connection_pool.active_connection? &&
           ActiveRecord::Base.connection.transaction_open?
          ActiveRecord::Base.connection.after_transaction_commit do
            enqueue_now(type, args, queue: queue, **options)
          end
        else
          enqueue_now(type, args, queue: queue, **options)
        end
      end

      # Enqueue a job immediately.
      #
      # @param type [String] the job type
      # @param args [Array] the job arguments
      # @param queue [String] the queue name (default: "default")
      # @param options [Hash] additional OJS enqueue options
      def enqueue_now(type, args, queue: "default", **options)
        client = OJS::Rails.client || raise(OJS::Rails::Error, "OJS client not configured")
        client.enqueue(type, args, queue: queue, **options)
      end
    end
  end
end
