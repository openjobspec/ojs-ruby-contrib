# frozen_string_literal: true

require "sinatra/base"
require "ojs/sinatra/helpers"

module OJS
  module Sinatra
    # Sinatra extension that registers OJS helpers and manages the OJS client.
    #
    # Usage:
    #   register OJS::Sinatra::Extension
    #
    #   configure do
    #     set :ojs_url, "http://localhost:8080"
    #   end
    #
    module Extension
      def self.registered(app)
        app.helpers OJS::Sinatra::Helpers

        app.set :ojs_url, ENV.fetch("OJS_URL", "http://localhost:8080")
        app.set :ojs_client, nil
      end
    end
  end
end
