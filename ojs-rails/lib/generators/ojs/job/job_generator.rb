# frozen_string_literal: true

require "rails/generators"

module Ojs
  module Generators
    class JobGenerator < ::Rails::Generators::NamedBase
      desc "Creates an ActiveJob class configured for OJS"

      source_root File.expand_path("templates", __dir__)

      class_option :queue, type: :string, default: "default",
                           desc: "Queue name for the job"
      class_option :priority, type: :numeric, default: nil,
                              desc: "Job priority (0=highest, 10=lowest)"

      def create_job_file
        template "job.rb", "app/jobs/#{file_name}_job.rb"
      end

      private

      def queue_name
        options[:queue]
      end

      def priority_line
        options[:priority] ? "\n  queue_with_priority #{options[:priority]}\n" : ""
      end
    end
  end
end
