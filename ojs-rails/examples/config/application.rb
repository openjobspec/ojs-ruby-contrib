# frozen_string_literal: true

require_relative "boot" if File.exist?(File.expand_path("boot", __dir__))
require "rails"
require "action_controller/railtie"
require "active_job/railtie"

module OjsRailsExample
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.eager_load = false

    config.active_job.queue_adapter = :ojs
  end
end
