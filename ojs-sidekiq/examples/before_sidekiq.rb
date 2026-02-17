# frozen_string_literal: true

# BEFORE: Original Sidekiq implementation
# This file shows how the app looked with Sidekiq.

require "sidekiq"

class EmailWorker
  include Sidekiq::Job
  sidekiq_options queue: "mailers", retry: 3

  def perform(user_id, template)
    puts "Sending #{template} email to user #{user_id}"
  end
end

class ReportWorker
  include Sidekiq::Job
  sidekiq_options queue: "reports", retry: 5

  def perform(report_type, params)
    puts "Generating #{report_type} report with #{params}"
  end
end

# Enqueue jobs
EmailWorker.perform_async(1, "welcome")
EmailWorker.perform_in(3600, 2, "reminder")
ReportWorker.perform_async("monthly", { "month" => "january" })
