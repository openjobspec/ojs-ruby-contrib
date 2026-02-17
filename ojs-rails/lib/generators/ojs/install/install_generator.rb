# frozen_string_literal: true

require "rails/generators"

module Ojs
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "Creates an OJS initializer file"

      source_root File.expand_path("templates", __dir__)

      def create_initializer
        template "initializer.rb", "config/initializers/ojs.rb"
      end
    end
  end
end
