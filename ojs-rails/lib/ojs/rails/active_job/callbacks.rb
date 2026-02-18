# frozen_string_literal: true

module OJS
  module Rails
    module ActiveJob
      # Callbacks module for ActiveJob classes using the OJS adapter.
      #
      # Provides lifecycle hooks that integrate ActiveJob's perform cycle
      # with OJS job state management and error classification.
      #
      # Include in your job classes or ApplicationJob:
      #
      #   class ApplicationJob < ActiveJob::Base
      #     include OJS::Rails::ActiveJob::Callbacks
      #   end
      #
      module Callbacks
        extend ::ActiveSupport::Concern

        included do
          around_perform :ojs_lifecycle_wrapper
          rescue_from StandardError, with: :ojs_handle_error
        end

        private

        # Wraps job execution with OJS lifecycle tracking.
        # Sets start time and captures completion for observability.
        def ojs_lifecycle_wrapper
          @ojs_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          yield
          @ojs_completed_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          log_ojs_lifecycle(:completed) if defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
        end

        # Maps Ruby exceptions to OJS error classifications.
        #
        # Retryable errors (mapped to OJS retryable state):
        # - Net::OpenTimeout, Net::ReadTimeout → timeout
        # - Errno::ECONNREFUSED, Errno::ECONNRESET → connection_error
        # - OJS::ConnectionError, OJS::TimeoutError → retryable OJS errors
        #
        # Non-retryable errors (mapped to OJS discard):
        # - ArgumentError, TypeError → invalid_arguments
        # - OJS::ValidationError → validation_error
        # - All other errors → unknown_error
        #
        def ojs_handle_error(error)
          code = ojs_error_code(error)
          retryable = ojs_retryable?(error)

          if defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
            ::Rails.logger.error(
              "[OJS] Job #{self.class.name}##{job_id} failed: #{code} " \
              "(retryable=#{retryable}) — #{error.class}: #{error.message}"
            )
          end

          # Re-raise so ActiveJob's retry/discard mechanisms can handle it.
          # The error code is attached as metadata for OJS-aware error handlers.
          raise error
        end

        # Classify an exception into an OJS error code.
        #
        # @param error [Exception]
        # @return [String] OJS error code
        def ojs_error_code(error)
          case error
          when ->(e) { timeout_error?(e) }
            "timeout"
          when ->(e) { connection_error?(e) }
            "connection_error"
          when ArgumentError, TypeError
            "invalid_arguments"
          when defined?(OJS::ValidationError) ? OJS::ValidationError : nil
            "validation_error"
          when defined?(OJS::ConflictError) ? OJS::ConflictError : nil
            "duplicate"
          else
            "unknown_error"
          end
        end

        # Determine if an error should allow retry.
        #
        # @param error [Exception]
        # @return [Boolean]
        def ojs_retryable?(error)
          case error
          when ->(e) { timeout_error?(e) }
            true
          when ->(e) { connection_error?(e) }
            true
          when ->(e) { e.respond_to?(:retryable?) && e.retryable? }
            true
          when ArgumentError, TypeError
            false
          else
            false
          end
        end

        def timeout_error?(error)
          return true if defined?(Net::OpenTimeout) && error.is_a?(Net::OpenTimeout)
          return true if defined?(Net::ReadTimeout) && error.is_a?(Net::ReadTimeout)
          return true if defined?(OJS::TimeoutError) && error.is_a?(OJS::TimeoutError)

          false
        end

        def connection_error?(error)
          return true if defined?(Errno::ECONNREFUSED) && error.is_a?(Errno::ECONNREFUSED)
          return true if defined?(Errno::ECONNRESET) && error.is_a?(Errno::ECONNRESET)
          return true if defined?(OJS::ConnectionError) && error.is_a?(OJS::ConnectionError)

          false
        end

        def log_ojs_lifecycle(state)
          duration = if @ojs_started_at && @ojs_completed_at
                       ((@ojs_completed_at - @ojs_started_at) * 1000).round(2)
                     end

          ::Rails.logger.info(
            "[OJS] Job #{self.class.name}##{job_id} #{state}" \
            "#{duration ? " in #{duration}ms" : ""}"
          )
        end
      end
    end
  end
end
