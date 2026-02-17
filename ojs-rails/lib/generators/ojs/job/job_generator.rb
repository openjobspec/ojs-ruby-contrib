# frozen_string_literal: true

require "rails/generators"

module Ojs
  module Generators
    class JobGenerator < ::Rails::Generators::NamedBase
      desc "Creates an ActiveJob class configured for OJS"

      source_root File.expand_path("templates", __dir__)

      def create_job_file
        template "job.rb", "app/jobs/#{file_name}_job.rb"
      end
    end
  end
end
