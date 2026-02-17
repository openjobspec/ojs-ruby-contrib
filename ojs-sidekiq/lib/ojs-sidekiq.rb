# frozen_string_literal: true

require "ojs"
require "ojs/sidekiq/adapter"
require "ojs/sidekiq/migration"
require "ojs/sidekiq/compat"

module OJS
  module Sidekiq
    class Error < StandardError; end

    class << self
      attr_accessor :client

      def configure
        yield self if block_given?
      end
    end
  end
end
