# frozen_string_literal: true

require "active_job"

module OJS
  module Rails
    # OJS worker that fetches jobs from the OJS server and executes them
    # through ActiveJob's perform mechanism.
    #
    # Usage:
    #
    #   worker = OJS::Rails::Worker.new(
    #     queues: %w[default mailers],
    #     concurrency: 5,
    #     poll_interval: 2.0
    #   )
    #   worker.start  # blocks until shutdown
    #
    # Or via the Rails runner:
    #
    #   rails runner "OJS::Rails::Worker.run"
    #
    class Worker
      # @return [Array<String>] queues this worker consumes
      attr_reader :queues

      # @return [Integer] maximum concurrent job executions
      attr_reader :concurrency

      # @return [Float] seconds between poll cycles when no jobs are available
      attr_reader :poll_interval

      # @param queues [Array<String>] queues to consume (default: ["default"])
      # @param concurrency [Integer] max concurrent jobs (default: 5)
      # @param poll_interval [Float] poll interval in seconds (default: 2.0)
      def initialize(queues: nil, concurrency: nil, poll_interval: nil)
        config = OJS::Rails.configuration

        @queues = (queues || [config.default_queue]).map { |q| config.resolve_queue(q) }
        @concurrency = concurrency || 5
        @poll_interval = poll_interval || 2.0
        @running = false
        @threads = []
      end

      # Start the worker, blocking the current thread.
      # Registers signal handlers for graceful shutdown.
      def start
        @running = true
        install_signal_handlers

        log_info("Starting OJS worker: queues=#{@queues} concurrency=#{@concurrency}")

        ojs_worker = build_ojs_worker
        register_handler(ojs_worker)

        ojs_worker.start
      rescue Interrupt
        log_info("Shutting down OJS worker...")
      ensure
        @running = false
        ojs_worker&.stop
        log_info("OJS worker stopped.")
      end

      # Convenience class method to start a worker with default configuration.
      #
      # @param options [Hash] options forwarded to {#initialize}
      def self.run(**options)
        new(**options).start
      end

      private

      def build_ojs_worker
        client = OJS::Rails.client || raise(
          OJS::Rails::Error,
          "OJS client not configured. Ensure OJS::Rails is configured before starting the worker."
        )

        OJS::Worker.new(
          client,
          queues: @queues,
          concurrency: @concurrency,
          poll_interval: @poll_interval
        )
      end

      # Register a wildcard handler that routes all OJS jobs through ActiveJob.
      def register_handler(ojs_worker)
        ojs_worker.on("*") do |job|
          execute_active_job(job)
        end
      end

      # Deserialize and execute an OJS job as an ActiveJob job.
      #
      # @param ojs_job [OJS::Job] the OJS job envelope
      def execute_active_job(ojs_job)
        meta = ojs_job.meta || {}
        job_class_name = meta["active_job_class"] || infer_class_name(ojs_job.type)

        job_class = job_class_name.constantize
        job_data = build_active_job_data(ojs_job, job_class_name, meta)

        job = ActiveJob::Base.deserialize(job_data)
        job.perform_now
      rescue NameError => e
        raise OJS::Rails::Error,
              "Cannot find ActiveJob class '#{job_class_name}' for OJS job type '#{ojs_job.type}': #{e.message}"
      rescue StandardError => e
        log_error("Job #{ojs_job.id} (#{ojs_job.type}) failed: #{e.class}: #{e.message}")
        raise
      end

      # Build an ActiveJob serialized hash from an OJS job.
      #
      # @param ojs_job [OJS::Job]
      # @param class_name [String]
      # @param meta [Hash]
      # @return [Hash]
      def build_active_job_data(ojs_job, class_name, meta)
        {
          "job_class" => class_name,
          "job_id" => meta["active_job_id"] || ojs_job.id,
          "provider_job_id" => ojs_job.id,
          "queue_name" => meta["queue_name"] || ojs_job.queue || "default",
          "arguments" => ojs_job.args || [],
          "executions" => meta.fetch("executions", 0),
          "locale" => meta["locale"] || I18n.locale.to_s,
        }
      end

      # Infer the ActiveJob class name from an OJS job type.
      #
      # Reverses the type conversion:
      #   "send_email"      → "SendEmailJob"
      #   "billing.charge"  → "Billing::ChargeJob"
      #
      # @param type [String] OJS job type
      # @return [String] Ruby class name
      def infer_class_name(type)
        type
          .split(".")
          .map { |segment| segment.split("_").map(&:capitalize).join }
          .join("::")
          .then { |name| name.end_with?("Job") ? name : "#{name}Job" }
      end

      def install_signal_handlers
        %w[INT TERM].each do |signal|
          Signal.trap(signal) do
            @running = false
            raise Interrupt
          end
        end
      end

      def log_info(message)
        if defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
          ::Rails.logger.info("[OJS::Worker] #{message}")
        else
          $stdout.puts("[OJS::Worker] #{message}")
        end
      end

      def log_error(message)
        if defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
          ::Rails.logger.error("[OJS::Worker] #{message}")
        else
          $stderr.puts("[OJS::Worker] #{message}")
        end
      end
    end
  end
end
