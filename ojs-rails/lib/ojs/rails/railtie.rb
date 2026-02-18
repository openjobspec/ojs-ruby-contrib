# frozen_string_literal: true

require "rails/railtie"

module OJS
  module Rails
    class Railtie < ::Rails::Railtie
      config.ojs = ActiveSupport::OrderedOptions.new

      # Load configuration from config/ojs.yml, Rails credentials, or explicit config.
      initializer "ojs.configure", before: "ojs.active_job" do |app|
        ojs_config = OJS::Rails.configuration

        # 1. Load from config/ojs.yml if present
        yaml_path = app.root.join("config", "ojs.yml")
        if yaml_path.exist?
          yaml = load_yaml(yaml_path, app)
          apply_yaml_config(ojs_config, yaml)
        end

        # 2. Load from Rails credentials (config/credentials.yml.enc)
        if app.credentials.respond_to?(:ojs) && app.credentials.ojs
          creds = app.credentials.ojs
          ojs_config.url = creds[:url] if creds[:url]
          ojs_config.queue_prefix = creds[:queue_prefix] if creds[:queue_prefix]
          ojs_config.timeout = creds[:timeout].to_i if creds[:timeout]
        end

        # 3. Apply explicit config.ojs settings (highest priority)
        app_ojs = app.config.ojs
        ojs_config.url = app_ojs[:url] if app_ojs[:url]
        ojs_config.queue_prefix = app_ojs[:queue_prefix] if app_ojs[:queue_prefix]
        ojs_config.default_queue = app_ojs[:default_queue] if app_ojs[:default_queue]
        ojs_config.timeout = app_ojs[:timeout].to_i if app_ojs[:timeout]
        ojs_config.headers = app_ojs[:headers] if app_ojs[:headers]

        # Build the client
        OJS::Rails.client = ojs_config.build_client
      end

      # Register OJS as an ActiveJob adapter.
      initializer "ojs.active_job" do
        ActiveSupport.on_load(:active_job) do
          require "ojs/rails/active_job/adapter"
        end
      end

      # Register generators.
      generators do
        require "generators/ojs/install/install_generator"
        require "generators/ojs/job/job_generator"
      end

      private

      def load_yaml(path, app)
        content = File.read(path)
        if content.include?("<%")
          content = ERB.new(content).result
        end
        yaml = YAML.safe_load(content, permitted_classes: [Symbol], aliases: true) || {}
        env = defined?(::Rails.env) ? ::Rails.env : (app.config.respond_to?(:env) ? app.config.env : "development")
        yaml[env] || yaml
      end

      def apply_yaml_config(config, yaml)
        return unless yaml.is_a?(Hash)

        config.url = yaml["url"] if yaml["url"]
        config.queue_prefix = yaml["queue_prefix"] if yaml["queue_prefix"]
        config.default_queue = yaml["default_queue"] if yaml["default_queue"]
        config.timeout = yaml["timeout"].to_i if yaml["timeout"]

        if yaml["retry_policy"].is_a?(Hash)
          config.retry_policy = yaml["retry_policy"].transform_keys(&:to_sym)
        end

        if yaml["headers"].is_a?(Hash)
          config.headers = yaml["headers"]
        end
      end
    end
  end
end
