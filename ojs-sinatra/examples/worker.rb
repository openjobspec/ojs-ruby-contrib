# frozen_string_literal: true

require "ojs"

client = OJS::Client.new(ENV.fetch("OJS_URL", "http://localhost:8080"))
worker = OJS::Worker.new(client: client, queues: ["default"])

worker.register("email.send") do |job|
  email, template = job.args
  puts "Sending #{template} email to #{email}"
end

puts "Worker started, waiting for jobs..."
worker.start
