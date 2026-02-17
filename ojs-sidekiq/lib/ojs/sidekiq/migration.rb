# frozen_string_literal: true

module OJS
  module Sidekiq
    # Helper to migrate existing Sidekiq job classes to OJS.
    #
    # Replaces the Sidekiq::Job include with OJS::Sidekiq::Job,
    # preserving existing sidekiq_options.
    module Migration
      module_function

      # Convert a Sidekiq job class to use OJS as the backend.
      #
      # @param klass [Class] the Sidekiq job class to convert
      def convert(klass)
        return if klass.ancestors.include?(OJS::Sidekiq::Job)

        # Capture existing sidekiq_options if present
        existing_options = if klass.respond_to?(:get_sidekiq_options)
                             klass.get_sidekiq_options
                           else
                             {}
                           end

        klass.include(OJS::Sidekiq::Job)
        klass.sidekiq_options(existing_options) unless existing_options.empty?
      end

      # Convert multiple job classes at once.
      #
      # @param klasses [Array<Class>] job classes to convert
      def convert_all(*klasses)
        klasses.each { |klass| convert(klass) }
      end
    end
  end
end
