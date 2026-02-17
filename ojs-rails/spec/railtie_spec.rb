# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Rails::Railtie do
  it "is defined as a class" do
    expect(described_class).to be_a(Class)
  end

  describe "configuration defaults" do
    it "defaults OJS URL to localhost:8080" do
      expect(ENV.fetch("OJS_URL", "http://localhost:8080")).to eq("http://localhost:8080")
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
        config.client = OJS::Client.new("http://block:8080")
      end

      expect(OJS::Rails.client.url).to eq("http://block:8080")
    end
  end
end
