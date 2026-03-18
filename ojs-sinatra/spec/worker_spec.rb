# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Sinatra::Worker do
  let(:client) { OJS::Client.new("http://localhost:8080") }

  describe "#initialize" do
    it "creates with default config" do
      worker = described_class.new(client: client)

      expect(worker.config[:client]).to eq(client)
      expect(worker.config[:queues]).to eq(["default"])
      expect(worker.config[:concurrency]).to eq(5)
      expect(worker.config[:poll_interval]).to eq(2)
    end

    it "accepts custom config" do
      worker = described_class.new(
        client: client,
        queues: ["critical", "low"],
        concurrency: 10,
        poll_interval: 5
      )

      expect(worker.config[:queues]).to eq(["critical", "low"])
      expect(worker.config[:concurrency]).to eq(10)
      expect(worker.config[:poll_interval]).to eq(5)
    end

    it "starts with no handlers" do
      worker = described_class.new(client: client)
      expect(worker.handlers).to be_empty
    end

    it "is not running initially" do
      worker = described_class.new(client: client)
      expect(worker.running?).to be false
    end
  end

  describe "#register" do
    it "registers a handler for a job type" do
      worker = described_class.new(client: client)
      worker.register("email.send") { |job| job }

      expect(worker.handlers).to have_key("email.send")
    end

    it "registers multiple handlers" do
      worker = described_class.new(client: client)
      worker.register("email.send") { |job| job }
      worker.register("report.generate") { |job| job }

      expect(worker.handlers.keys).to contain_exactly("email.send", "report.generate")
    end

    it "raises without a block" do
      worker = described_class.new(client: client)
      expect { worker.register("email.send") }.to raise_error(ArgumentError, "a block is required")
    end
  end

  describe "#registered_types" do
    it "returns empty array when no handlers registered" do
      worker = described_class.new(client: client)
      expect(worker.registered_types).to eq([])
    end

    it "returns registered job types" do
      worker = described_class.new(client: client)
      worker.register("email.send") { |job| job }
      worker.register("cleanup.run") { |job| job }

      expect(worker.registered_types).to contain_exactly("email.send", "cleanup.run")
    end
  end

  describe "#start and #stop" do
    it "starts the worker and sets running to true" do
      worker = described_class.new(client: client, poll_interval: 0.1)
      thread = worker.start

      expect(thread).to be_a(Thread)
      expect(worker.running?).to be true

      worker.stop(timeout: 2)
    end

    it "stops the worker and sets running to false" do
      worker = described_class.new(client: client, poll_interval: 0.1)
      worker.start

      worker.stop(timeout: 2)
      expect(worker.running?).to be false
    end

    it "is idempotent when starting multiple times" do
      worker = described_class.new(client: client, poll_interval: 0.1)
      thread1 = worker.start
      thread2 = worker.start

      expect(thread1).to eq(thread2)

      worker.stop(timeout: 2)
    end
  end
end
