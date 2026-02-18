# frozen_string_literal: true

# OJS (Open Job Spec) configuration.
#
# This initializer is loaded after config/ojs.yml. Values set here
# take the highest priority and override YAML and credentials settings.
#
# For full configuration options see:
#   https://github.com/openjobspec/ojs-ruby-contrib/tree/main/ojs-rails

OJS::Rails.configure do |config|
  # Server URL (default: ENV["OJS_URL"] || "http://localhost:8080")
  # config.url = "http://localhost:8080"

  # Prefix all queue names with the Rails environment.
  # e.g. "production_default", "staging_mailers"
  # config.queue_prefix = Rails.env

  # Default queue for jobs that don't specify one.
  # config.default_queue = "default"

  # Default retry policy applied to all jobs.
  # config.retry_policy = { max_attempts: 5, initial_interval: "PT1S", backoff_coefficient: 2.0 }

  # HTTP request timeout in seconds.
  # config.timeout = 30

  # Additional HTTP headers (e.g. for authentication).
  # config.headers = { "Authorization" => "Bearer #{ENV['OJS_TOKEN']}" }
end

# Set OJS as the ActiveJob backend.
Rails.application.config.active_job.queue_adapter = :ojs
