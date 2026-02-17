# frozen_string_literal: true

require "ojs"
require "ojs/rails/railtie" if defined?(::Rails::Railtie)
require "ojs/rails/active_job_adapter"
require "ojs/rails/enqueue"
require "ojs/rails/generator"

module OJS
  module Rails
    class Error < StandardError; end

    class << self
      attr_accessor :client

      def configure
        yield self if block_given?
      end
    end
  end
end
