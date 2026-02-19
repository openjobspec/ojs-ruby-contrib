# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OJS::Sinatra configuration" do
  describe "default settings" do
    let(:app_class) do
      Class.new(Sinatra::Base) do
        register OJS::Sinatra::Extension
      end
    end

    it "sets ojs_url from default" do
      expect(app_class.ojs_url).to eq("http://localhost:8080")
    end

    it "sets ojs_client to nil initially" do
      expect(app_class.ojs_client).to be_nil
    end
  end

  describe "custom settings" do
    let(:app_class) do
      Class.new(Sinatra::Base) do
        register OJS::Sinatra::Extension
        set :ojs_url, "http://custom-ojs:9090"
      end
    end

    it "uses the custom ojs_url" do
      expect(app_class.ojs_url).to eq("http://custom-ojs:9090")
    end
  end

  describe "environment variable configuration" do
    around do |example|
      original = ENV["OJS_URL"]
      ENV["OJS_URL"] = "http://env-ojs:3000"
      example.run
    ensure
      if original
        ENV["OJS_URL"] = original
      else
        ENV.delete("OJS_URL")
      end
    end

    it "reads ojs_url from OJS_URL environment variable" do
      app_class = Class.new(Sinatra::Base) do
        register OJS::Sinatra::Extension
      end

      expect(app_class.ojs_url).to eq("http://env-ojs:3000")
    end
  end
end
