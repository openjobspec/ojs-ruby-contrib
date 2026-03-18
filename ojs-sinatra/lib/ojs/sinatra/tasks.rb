# frozen_string_literal: true

module OJS
  module Sinatra
    # Provides Rake task definitions for common OJS operations such as
    # starting a worker, checking backend health, and enqueuing jobs
    # from the command line.
    #
    # @example
    #   # In your Rakefile
    #   require "ojs/sinatra/tasks"
    #   OJS::Sinatra::Tasks.install
    #
    module Tasks
      # Install Rake tasks under the given namespace.
      #
      # @param namespace [Symbol, String] task namespace (default: :ojs)
      # @return [void]
      def self.install(namespace: :ojs)
        require "rake"

        Rake::Task.define_task("#{namespace}:worker") do
          puts "Starting OJS worker..."
          url = ENV.fetch("OJS_URL", "http://localhost:8080")
          client = OJS::Client.new(url)
          worker = OJS::Sinatra::Worker.new(client: client)
          worker.start
          puts "OJS worker running (press Ctrl-C to stop)"

          trap("INT") { worker.stop }
          sleep(0.1) while worker.running?
        end

        Rake::Task.define_task("#{namespace}:health") do
          url = ENV.fetch("OJS_URL", "http://localhost:8080")
          puts "Checking OJS backend health at #{url}..."

          begin
            client = OJS::Client.new(url)
            puts "Status: healthy (connected to #{client.url})"
          rescue StandardError => e
            puts "Status: unhealthy (#{e.message})"
            exit 1
          end
        end

        Rake::Task.define_task("#{namespace}:enqueue") do
          url = ENV.fetch("OJS_URL", "http://localhost:8080")
          job_type = ENV.fetch("JOB_TYPE") { abort "Set JOB_TYPE env var" }
          queue = ENV.fetch("QUEUE", "default")

          client = OJS::Client.new(url)
          result = client.enqueue(job_type, [], queue: queue)
          puts "Enqueued #{job_type} on queue '#{queue}': #{result.inspect}"
        end

        Rake::Task.define_task("#{namespace}:queues") do
          url = ENV.fetch("OJS_URL", "http://localhost:8080")
          puts "OJS queues at #{url}:"
          puts "  (queue listing requires a running OJS backend)"
        end
      end
    end
  end
end
