# frozen_string_literal: true

Rails.application.configure do
  config.ojs.url = ENV.fetch("OJS_URL", "http://localhost:8080")
end
