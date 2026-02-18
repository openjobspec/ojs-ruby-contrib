# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Rails::Middleware do
  let(:mock_client) { instance_double(OJS::Client) }
  let(:app) { ->(env) { [env[:status] || 200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }

  before do
    OJS::Rails.client = mock_client
  end

  after do
    Thread.current[described_class::THREAD_KEY] = nil
  end

  describe "#call" do
    it "flushes buffered jobs on successful response" do
      allow(mock_client).to receive(:enqueue)

      middleware.call(status: 200)

      # No jobs buffered, no enqueue calls expected
      expect(mock_client).not_to have_received(:enqueue)
    end

    it "does not flush jobs on 500 response" do
      error_app = ->(_env) do
        described_class.enqueue("important.job", [1])
        [500, {}, ["Error"]]
      end
      error_middleware = described_class.new(error_app)

      error_middleware.call({})
      expect(mock_client).not_to have_received(:enqueue)
    end

    it "flushes a single buffered job" do
      single_app = ->(_env) do
        described_class.enqueue("email.send", [1], queue: "mailers")
        [200, {}, ["OK"]]
      end
      single_middleware = described_class.new(single_app)

      expect(mock_client).to receive(:enqueue).with(
        "email.send", [1], queue: "mailers"
      )

      single_middleware.call({})
    end

    it "uses enqueue_batch for multiple buffered jobs" do
      multi_app = ->(_env) do
        described_class.enqueue("email.send", [1])
        described_class.enqueue("report.generate", [2])
        [200, {}, ["OK"]]
      end
      multi_middleware = described_class.new(multi_app)

      expect(mock_client).to receive(:enqueue_batch).with(
        [
          { type: "email.send", args: [1] },
          { type: "report.generate", args: [2] },
        ]
      )

      multi_middleware.call({})
    end

    it "clears buffer on exception" do
      raise_app = ->(_env) { raise "boom" }
      raise_middleware = described_class.new(raise_app)

      expect { raise_middleware.call({}) }.to raise_error("boom")
      expect(Thread.current[described_class::THREAD_KEY]).to be_nil
    end
  end

  describe ".enqueue" do
    it "enqueues immediately when no request buffer is active" do
      Thread.current[described_class::THREAD_KEY] = nil

      expect(mock_client).to receive(:enqueue).with(
        "immediate.job", [1], queue: "default"
      ).and_return(double(id: "job-1"))

      described_class.enqueue("immediate.job", [1], queue: "default")
    end

    it "buffers when a request is active" do
      Thread.current[described_class::THREAD_KEY] = []
      described_class.enqueue("buffered.job", [1])

      expect(Thread.current[described_class::THREAD_KEY].size).to eq(1)
      expect(Thread.current[described_class::THREAD_KEY].first[:type]).to eq("buffered.job")
    end
  end

  describe ".buffering?" do
    it "returns false when no request is active" do
      Thread.current[described_class::THREAD_KEY] = nil
      expect(described_class.buffering?).to be false
    end

    it "returns true during a request" do
      Thread.current[described_class::THREAD_KEY] = []
      expect(described_class.buffering?).to be true
    end
  end

  describe ".buffer_size" do
    it "returns 0 when no request is active" do
      Thread.current[described_class::THREAD_KEY] = nil
      expect(described_class.buffer_size).to eq(0)
    end

    it "returns the count of buffered jobs" do
      Thread.current[described_class::THREAD_KEY] = [
        { type: "a", args: [] },
        { type: "b", args: [] },
      ]
      expect(described_class.buffer_size).to eq(2)
    end
  end
end
