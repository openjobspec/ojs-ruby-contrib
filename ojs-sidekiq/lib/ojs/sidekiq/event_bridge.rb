# frozen_string_literal: true

module OJS
  module Sidekiq
    # Bridges Sidekiq lifecycle events to OJS events.
    #
    # Allows registering listeners for standard job and worker lifecycle
    # events, and emitting those events with arbitrary payloads. Can be
    # wired into Sidekiq's server lifecycle hooks via {#install_sidekiq_hooks}.
    #
    # @example
    #   bridge = OJS::Sidekiq::EventBridge.new
    #   bridge.on(:job_completed) { |payload| puts "Done: #{payload[:job_id]}" }
    #   bridge.emit(:job_completed, job_id: "abc-123")
    #
    class EventBridge
      # Supported lifecycle events.
      EVENTS = %i[
        job_started
        job_completed
        job_failed
        job_retrying
        worker_started
        worker_stopped
        worker_heartbeat
      ].freeze

      # Creates a new event bridge.
      #
      # @param client [OJS::Client, nil] optional OJS client (falls back to module-level client)
      def initialize(client: nil)
        @client = client || OJS::Sidekiq.client
        @listeners = Hash.new { |h, k| h[k] = [] }
      end

      # Registers a listener for the given event.
      #
      # @param event [Symbol] one of {EVENTS}
      # @yield [Hash] the event payload
      # @return [self]
      # @raise [ArgumentError] if event is not in {EVENTS}
      def on(event, &block)
        event = event.to_sym
        raise ArgumentError, "Unknown event: #{event}. Valid events: #{EVENTS.join(", ")}" unless EVENTS.include?(event)

        @listeners[event] << block
        self
      end

      # Emits an event, calling all registered listeners with the payload.
      #
      # @param event [Symbol] the event to emit
      # @param payload [Hash] data passed to each listener
      # @return [Array] results from each listener
      def emit(event, payload = {})
        event = event.to_sym
        enriched = { event: event, timestamp: Time.now.utc.iso8601 }.merge(payload)
        @listeners[event].map { |listener| listener.call(enriched) }
      end

      # Installs Sidekiq server lifecycle hooks that emit OJS events.
      #
      # Wires Sidekiq's +on(:startup)+ and +on(:shutdown)+ callbacks to
      # emit +:worker_started+ and +:worker_stopped+ events respectively.
      # Requires the Sidekiq gem to be loaded.
      #
      # @return [self]
      def install_sidekiq_hooks
        bridge = self

        if defined?(::Sidekiq)
          ::Sidekiq.configure_server do |config|
            config.on(:startup) do
              bridge.emit(:worker_started, pid: Process.pid)
            end

            config.on(:shutdown) do
              bridge.emit(:worker_stopped, pid: Process.pid)
            end
          end
        end

        self
      end

      # Returns the event types that have at least one registered listener.
      #
      # @return [Array<Symbol>]
      def registered_events
        @listeners.keys
      end

      # Returns the number of listeners for a given event.
      #
      # @param event [Symbol] the event to query
      # @return [Integer]
      def listener_count(event)
        @listeners.fetch(event.to_sym, []).size
      end

      # Returns a summary of all registered listeners.
      #
      # @return [Hash{Symbol => Integer}]
      def stats
        EVENTS.each_with_object({}) do |event, hash|
          count = @listeners.fetch(event, []).size
          hash[event] = count if count > 0
        end
      end
    end
  end
end
