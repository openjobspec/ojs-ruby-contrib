# frozen_string_literal: true

require "sinatra/base"
require "ojs/sinatra/helpers"
require "ojs/sinatra/health"

module OJS
  module Sinatra
    # Sinatra extension that registers OJS helpers and manages the OJS client.
    # Optionally starts a background worker for processing jobs.
    #
    # Usage:
    #   register OJS::Sinatra::Extension
    #
    #   configure do
    #     set :ojs_url, "http://localhost:8080"
    #     set :ojs_worker_enabled, true
    #   end
    #
    module Extension
      # Called automatically by Sinatra when this extension is registered.
      #
      # @param app [Sinatra::Base] the Sinatra application
      # @return [void]
      def self.registered(app)
        app.helpers OJS::Sinatra::Helpers

        app.set :ojs_url, ENV.fetch("OJS_URL", "http://localhost:8080")
        app.set :ojs_client, nil

        # Worker configuration
        app.set :ojs_worker_enabled, false
        app.set :ojs_worker_queues, ["default"]
        app.set :ojs_worker_concurrency, 5
        app.set :ojs_worker, nil

        # Register the health check endpoint
        app.register OJS::Sinatra::Health

        app.configure do
          if app.settings.ojs_worker_enabled
            require "ojs/sinatra/worker"

            client = app.settings.ojs_client || OJS::Client.new(app.settings.ojs_url)
            worker = OJS::Sinatra::Worker.new(
              client: client,
              queues: app.settings.ojs_worker_queues,
              concurrency: app.settings.ojs_worker_concurrency
            )
            app.set :ojs_worker, worker
            worker.start
          end
        end
      end
    end
  end
end
