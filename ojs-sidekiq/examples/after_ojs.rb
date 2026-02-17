# frozen_string_literal: true

# AFTER: Same app using OJS via the Sidekiq-compatible adapter.
# Only change: `include Sidekiq::Job` → `include OJS::Sidekiq::Job`

require "ojs-sidekiq"

OJS::Sidekiq.client = OJS::Client.new(ENV.fetch("OJS_URL", "http://localhost:8080"))

class EmailWorker
  include OJS::Sidekiq::Job
  sidekiq_options queue: "mailers", retry: 3

  def perform(user_id, template)
    puts "Sending #{template} email to user #{user_id}"
  end
end

class ReportWorker
  include OJS::Sidekiq::Job
  sidekiq_options queue: "reports", retry: 5

  def perform(report_type, params)
    puts "Generating #{report_type} report with #{params}"
  end
end

# Enqueue jobs — same API as Sidekiq
EmailWorker.perform_async(1, "welcome")
EmailWorker.perform_in(3600, 2, "reminder")
ReportWorker.perform_async("monthly", { "month" => "january" })
