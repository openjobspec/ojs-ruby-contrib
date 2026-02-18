# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Rails::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "sets url from OJS_URL env or localhost" do
      expect(config.url).to eq(ENV.fetch("OJS_URL", "http://localhost:8080"))
    end

    it "has nil queue_prefix" do
      expect(config.queue_prefix).to be_nil
    end

    it "defaults default_queue to 'default'" do
      expect(config.default_queue).to eq("default")
    end

    it "defaults timeout to 30" do
      expect(config.timeout).to eq(30)
    end

    it "defaults headers to empty hash" do
      expect(config.headers).to eq({})
    end

    it "defaults retry_policy to empty hash" do
      expect(config.retry_policy).to eq({})
    end

    it "has a default priority map" do
      expect(config.priority_map).to be_a(Hash)
      expect(config.priority_map[0]).to eq(10)
      expect(config.priority_map[5]).to eq(0)
      expect(config.priority_map[10]).to eq(-10)
    end
  end

  describe "#resolve_queue" do
    it "returns the queue name when no prefix is set" do
      expect(config.resolve_queue("mailers")).to eq("mailers")
    end

    it "returns default_queue when name is nil" do
      expect(config.resolve_queue(nil)).to eq("default")
    end

    it "returns default_queue when name is empty" do
      expect(config.resolve_queue("")).to eq("default")
    end

    it "prepends prefix when configured" do
      config.queue_prefix = "production"
      expect(config.resolve_queue("mailers")).to eq("production_mailers")
    end

    it "prepends prefix to default queue" do
      config.queue_prefix = "staging"
      expect(config.resolve_queue(nil)).to eq("staging_default")
    end
  end

  describe "#resolve_priority" do
    it "returns nil for nil priority" do
      expect(config.resolve_priority(nil)).to be_nil
    end

    it "maps ActiveJob 0 (highest) to OJS 10" do
      expect(config.resolve_priority(0)).to eq(10)
    end

    it "maps ActiveJob 5 (normal) to OJS 0" do
      expect(config.resolve_priority(5)).to eq(0)
    end

    it "maps ActiveJob 10 (lowest) to OJS -10" do
      expect(config.resolve_priority(10)).to eq(-10)
    end

    it "passes through unmapped priorities" do
      expect(config.resolve_priority(99)).to eq(99)
    end

    it "supports custom priority map" do
      config.priority_map = { 1 => 100, 2 => 50 }
      expect(config.resolve_priority(1)).to eq(100)
      expect(config.resolve_priority(2)).to eq(50)
    end
  end

  describe "#build_client" do
    it "returns an OJS::Client" do
      expect(config.build_client).to be_a(OJS::Client)
    end

    it "uses the configured URL" do
      config.url = "http://custom:9090"
      client = config.build_client
      expect(client.url).to eq("http://custom:9090")
    end
  end
end
