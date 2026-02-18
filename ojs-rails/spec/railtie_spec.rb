# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Rails::Railtie do
  it "is defined as a class" do
    expect(described_class).to be_a(Class)
  end

  describe "configuration defaults" do
    it "defaults OJS URL to localhost:8080" do
      config = OJS::Rails.configuration
      expect(config.url).to eq("http://localhost:8080")
    end

    it "defaults queue prefix to nil" do
      config = OJS::Rails.configuration
      expect(config.queue_prefix).to be_nil
    end

    it "defaults default_queue to 'default'" do
      config = OJS::Rails.configuration
      expect(config.default_queue).to eq("default")
    end

    it "defaults timeout to 30" do
      config = OJS::Rails.configuration
      expect(config.timeout).to eq(30)
    end
  end

  describe "OJS::Rails module" do
    it "has a configurable client accessor" do
      client = OJS::Client.new("http://custom:9090")
      OJS::Rails.client = client

      expect(OJS::Rails.client).to eq(client)
      expect(OJS::Rails.client.url).to eq("http://custom:9090")
    end

    it "supports configure block" do
      OJS::Rails.configure do |config|
        config.url = "http://block:8080"
        config.queue_prefix = "test"
        config.default_queue = "high"
      end

      expect(OJS::Rails.configuration.url).to eq("http://block:8080")
      expect(OJS::Rails.configuration.queue_prefix).to eq("test")
      expect(OJS::Rails.configuration.default_queue).to eq("high")
    end

    it "builds a client from configuration when configure is called" do
      OJS::Rails.configure do |config|
        config.url = "http://configured:9090"
      end

      expect(OJS::Rails.client).to be_a(OJS::Client)
      expect(OJS::Rails.client.url).to eq("http://configured:9090")
    end

    it "resets configuration and client with reset!" do
      OJS::Rails.configure do |config|
        config.url = "http://custom:9090"
      end

      OJS::Rails.reset!

      expect(OJS::Rails.client).to be_nil
      expect(OJS::Rails.configuration.url).to eq("http://localhost:8080")
    end
  end
end
