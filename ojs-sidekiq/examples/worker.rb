# frozen_string_literal: true

require "ojs"

client = OJS::Client.new(ENV.fetch("OJS_URL", "http://localhost:8080"))
worker = OJS::Worker.new(client: client, queues: %w[mailers reports])

worker.register("EmailWorker") do |job|
  user_id, template = job.args
  puts "Sending #{template} email to user #{user_id}"
end

worker.register("ReportWorker") do |job|
  report_type, params = job.args
  puts "Generating #{report_type} report with #{params}"
end

puts "Worker started, waiting for jobs..."
worker.start
