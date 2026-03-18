# frozen_string_literal: true

require "json"

module OJS
  module Sinatra
    # Sinatra extension that adds a +GET /ojs/health+ endpoint for
    # monitoring the connection to the OJS backend.
    #
    # @example
    #   register OJS::Sinatra::Health
    #
    module Health
      # Called automatically by Sinatra when this module is registered.
      #
      # @param app [Sinatra::Base] the Sinatra application
      # @return [void]
      def self.registered(app)
        app.get "/ojs/health" do
          content_type :json

          begin
            client = ojs_client
            url = client.url
            {
              status: "healthy",
              ojs: {
                connected: true,
                url: url
              }
            }.to_json
          rescue StandardError => e
            status 503
            {
              status: "unhealthy",
              error: e.message
            }.to_json
          end
        end
      end
    end
  end
end
