# frozen_string_literal: true

module OJS
  module Rails
    # Rails generators for OJS setup and job creation.
    #
    # Generators follow the standard Rails convention and live in
    # lib/generators/ojs/. They are auto-discovered by Rails when
    # the gem is loaded via the Railtie.
    #
    # Usage:
    #   rails generate ojs:install    # Creates config/initializers/ojs.rb
    #   rails generate ojs:job MyJob  # Creates app/jobs/my_job.rb with OJS adapter
    module Generator
    end
  end
end
