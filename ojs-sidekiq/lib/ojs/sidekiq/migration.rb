# frozen_string_literal: true

module OJS
  module Sidekiq
    # Helper to migrate existing Sidekiq job classes to OJS.
    #
    # Replaces the Sidekiq::Job include with OJS::Sidekiq::Job,
    # preserving existing sidekiq_options. Provides discovery, dry-run
    # previews, and validation utilities for safe incremental migration.
    module Migration
      module_function

      # Convert a Sidekiq job class to use OJS as the backend.
      #
      # @param klass [Class] the Sidekiq job class to convert
      # @return [void]
      def convert(klass)
        return if klass.ancestors.include?(OJS::Sidekiq::Job)

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
      # @return [void]
      def convert_all(*klasses)
        klasses.each { |klass| convert(klass) }
      end

      # Discover all classes that include Sidekiq::Job or Sidekiq::Worker.
      #
      # Scans +ObjectSpace+ for classes whose ancestors include the real
      # Sidekiq::Job or Sidekiq::Worker modules (if loaded). Excludes
      # classes that have already been converted to OJS::Sidekiq::Job.
      #
      # @return [Array<Class>] discovered Sidekiq job classes
      def scan
        sidekiq_modules = []
        sidekiq_modules << ::Sidekiq::Job if defined?(::Sidekiq::Job)
        sidekiq_modules << ::Sidekiq::Worker if defined?(::Sidekiq::Worker)

        return [] if sidekiq_modules.empty?

        ObjectSpace.each_object(Class).select do |klass|
          sidekiq_modules.any? { |mod| klass.ancestors.include?(mod) } &&
            !klass.ancestors.include?(OJS::Sidekiq::Job)
        end
      end

      # Preview what would be converted without making changes.
      #
      # Returns a list of hashes describing each class that would be
      # affected by a conversion, including its current options and
      # whether it has already been converted.
      #
      # @param klasses [Array<Class>] classes to preview (defaults to {scan} results)
      # @return [Array<Hash>] preview entries
      def dry_run(*klasses)
        targets = klasses.empty? ? scan : klasses

        targets.map do |klass|
          existing_options = if klass.respond_to?(:get_sidekiq_options)
                               klass.get_sidekiq_options
                             else
                               {}
                             end

          {
            class_name: klass.name || klass.to_s,
            already_converted: klass.ancestors.include?(OJS::Sidekiq::Job),
            current_options: existing_options,
            action: klass.ancestors.include?(OJS::Sidekiq::Job) ? :skip : :convert
          }
        end
      end

      # Generate a migration report summarizing the current state.
      #
      # @param klasses [Array<Class>] classes to report on (defaults to {scan} results)
      # @return [Hash] report with counts and class details
      def generate_report(*klasses)
        targets = klasses.empty? ? scan : klasses
        entries = dry_run(*targets)

        to_convert = entries.count { |e| e[:action] == :convert }
        already_done = entries.count { |e| e[:action] == :skip }

        {
          total: entries.size,
          to_convert: to_convert,
          already_converted: already_done,
          classes: entries,
          generated_at: Time.now.utc.iso8601
        }
      end

      # Convert a class and validate it responds to the OJS::Sidekiq::Job API.
      #
      # @param klass [Class] the class to convert and validate
      # @return [Hash] result with :success, :class_name, and :errors keys
      def convert_with_validation(klass)
        convert(klass)

        errors = []
        errors << "missing perform_async" unless klass.respond_to?(:perform_async)
        errors << "missing perform_in" unless klass.respond_to?(:perform_in)
        errors << "missing perform_at" unless klass.respond_to?(:perform_at)
        errors << "missing get_sidekiq_options" unless klass.respond_to?(:get_sidekiq_options)
        errors << "not in ancestors" unless klass.ancestors.include?(OJS::Sidekiq::Job)

        {
          success: errors.empty?,
          class_name: klass.name || klass.to_s,
          errors: errors
        }
      end
    end
  end
end
