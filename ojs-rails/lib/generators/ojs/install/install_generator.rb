# frozen_string_literal: true

require "rails/generators"

module Ojs
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "Sets up OJS in your Rails application"

      source_root File.expand_path("templates", __dir__)

      def create_initializer
        template "initializer.rb", "config/initializers/ojs.rb"
      end

      def create_yaml_config
        template "ojs.yml", "config/ojs.yml"
      end

      def display_post_install
        say ""
        say "OJS has been installed! Next steps:", :green
        say "  1. Update config/ojs.yml with your OJS server URL"
        say "  2. Set config.active_job.queue_adapter = :ojs in config/application.rb"
        say "  3. Generate a job: rails generate ojs:job MyJob"
        say ""
      end
    end
  end
end
