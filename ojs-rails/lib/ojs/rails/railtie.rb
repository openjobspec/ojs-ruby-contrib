# frozen_string_literal: true

require "rails/railtie"

module OJS
  module Rails
    class Railtie < ::Rails::Railtie
      config.ojs = ActiveSupport::OrderedOptions.new
      config.ojs.url = ENV.fetch("OJS_URL", "http://localhost:8080")

      initializer "ojs.configure" do |app|
        OJS::Rails.client = OJS::Client.new(app.config.ojs.url)
      end

      initializer "ojs.active_job" do
        ActiveSupport.on_load(:active_job) do
          require "ojs/rails/active_job_adapter"
        end
      end
    end
  end
end
