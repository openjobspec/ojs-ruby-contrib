# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Sidekiq::Worker do
  let(:mock_client) { instance_double(OJS::Client) }

  before { OJS::Sidekiq.client = mock_client }

  describe "#initialize" do
    it "creates a worker with default configuration" do
      worker = described_class.new(client: mock_client)

      expect(worker.config[:queues]).to eq(["default"])
      expect(worker.config[:concurrency]).to eq(5)
      expect(worker.config[:poll_interval]).to eq(2)
      expect(worker.config[:shutdown_timeout]).to eq(25)
    end

    it "accepts custom configuration" do
      worker = described_class.new(
        client: mock_client,
        queues: %w[critical high],
        concurrency: 10,
        poll_interval: 1,
        shutdown_timeout: 30
      )

      expect(worker.config[:queues]).to eq(%w[critical high])
      expect(worker.config[:concurrency]).to eq(10)
      expect(worker.config[:poll_interval]).to eq(1)
      expect(worker.config[:shutdown_timeout]).to eq(30)
    end

    it "starts with no handlers" do
      worker = described_class.new(client: mock_client)
      expect(worker.handlers).to be_empty
    end

    it "starts in a stopped state" do
      worker = described_class.new(client: mock_client)
      expect(worker).not_to be_running
    end
  end

  describe "#register" do
    let(:worker) { described_class.new(client: mock_client) }

    it "registers a block handler" do
      worker.register("EmailJob") { |args| args }
      expect(worker.registered_types).to contain_exactly("EmailJob")
    end

    it "registers a callable handler" do
      handler = ->(args) { args }
      worker.register("EmailJob", handler)
      expect(worker.handlers["EmailJob"]).to eq(handler)
    end

    it "returns self for chaining" do
      result = worker.register("EmailJob") { |args| args }
      expect(result).to eq(worker)
    end

    it "converts job type to string" do
      worker.register(:EmailJob) { |args| args }
      expect(worker.registered_types).to contain_exactly("EmailJob")
    end

    it "raises if neither handler nor block given" do
      expect { worker.register("EmailJob") }.to raise_error(ArgumentError, /handler or block required/)
    end

    it "allows registering multiple handlers" do
      worker.register("EmailJob") { |args| args }
      worker.register("ReportJob") { |args| args }
      expect(worker.registered_types).to contain_exactly("EmailJob", "ReportJob")
    end

    it "overwrites existing handler for same job type" do
      first = ->(args) { "first" }
      second = ->(args) { "second" }

      worker.register("EmailJob", first)
      worker.register("EmailJob", second)

      expect(worker.handlers["EmailJob"]).to eq(second)
    end
  end

  describe "#registered_types" do
    let(:worker) { described_class.new(client: mock_client) }

    it "returns empty array when no handlers registered" do
      expect(worker.registered_types).to eq([])
    end

    it "returns registered job type names" do
      worker.register("EmailJob") { |args| args }
      worker.register("ReportJob") { |args| args }
      expect(worker.registered_types).to contain_exactly("EmailJob", "ReportJob")
    end
  end

  describe "#running?" do
    let(:worker) do
      described_class.new(client: mock_client, concurrency: 1, poll_interval: 0.1)
    end

    it "returns false before start" do
      expect(worker).not_to be_running
    end

    it "returns true after start" do
      worker.start
      expect(worker).to be_running
      worker.stop
    end

    it "returns false after stop" do
      worker.start
      worker.stop
      expect(worker).not_to be_running
    end
  end

  describe "#start" do
    let(:worker) do
      described_class.new(client: mock_client, concurrency: 2, poll_interval: 0.1)
    end

    after { worker.stop if worker.running? }

    it "sets running to true" do
      worker.start
      expect(worker).to be_running
    end

    it "returns self for chaining" do
      result = worker.start
      expect(result).to eq(worker)
    end

    it "is idempotent" do
      worker.start
      worker.start
      expect(worker).to be_running
    end
  end

  describe "#stop" do
    let(:worker) do
      described_class.new(client: mock_client, concurrency: 2, poll_interval: 0.1, shutdown_timeout: 2)
    end

    it "sets running to false" do
      worker.start
      worker.stop
      expect(worker).not_to be_running
    end

    it "returns self for chaining" do
      worker.start
      result = worker.stop
      expect(result).to eq(worker)
    end

    it "is safe to call when not running" do
      expect { worker.stop }.not_to raise_error
    end
  end

  describe "#stats" do
    let(:worker) do
      described_class.new(client: mock_client, queues: %w[default critical], concurrency: 3, poll_interval: 0.1)
    end

    after { worker.stop if worker.running? }

    it "returns correct structure when stopped" do
      worker.register("EmailJob") { |args| args }

      stats = worker.stats
      expect(stats[:running]).to be false
      expect(stats[:queues]).to eq(%w[default critical])
      expect(stats[:concurrency]).to eq(3)
      expect(stats[:handlers]).to contain_exactly("EmailJob")
      expect(stats[:thread_count]).to eq(0)
    end

    it "returns correct structure when running" do
      worker.register("EmailJob") { |args| args }
      worker.start
      sleep(0.05) # allow threads to start

      stats = worker.stats
      expect(stats[:running]).to be true
      expect(stats[:thread_count]).to be > 0
    end
  end
end
