# frozen_string_literal: true

require "ojs"
require "ojs/rails/configuration"
require "ojs/rails/railtie" if defined?(::Rails::Railtie)
require "ojs/rails/active_job/adapter"
require "ojs/rails/active_job/callbacks"
require "ojs/rails/enqueue"
require "ojs/rails/generator"

module OJS
  module Rails
    class Error < StandardError; end

    class << self
      # @return [OJS::Client, nil] the global OJS client instance
      attr_accessor :client

      # @return [OJS::Rails::Configuration] the current configuration
      def configuration
        @configuration ||= Configuration.new
      end

      # Yield the configuration for modification.
      #
      #   OJS::Rails.configure do |config|
      #     config.url = "http://ojs.internal:8080"
      #     config.queue_prefix = Rails.env
      #   end
      #
      def configure
        yield configuration if block_given?
        @client = configuration.build_client
        configuration
      end

      # Reset configuration and client (mainly for testing).
      def reset!
        @configuration = Configuration.new
        @client = nil
      end
    end
  end
end
