# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Sidekiq::Compat do
  let(:mock_client) { instance_double(OJS::Client) }

  before do
    OJS::Sidekiq.client = mock_client
  end

  describe ".perform_async" do
    it "enqueues a job for immediate execution" do
      expect(mock_client).to receive(:enqueue).with(
        "email.send",
        ["user@example.com", "welcome"],
        queue: "default"
      )

      described_class.perform_async("email.send", "user@example.com", "welcome")
    end

    it "accepts a custom queue" do
      expect(mock_client).to receive(:enqueue).with(
        "report.generate",
        [42],
        queue: "reports"
      )

      described_class.perform_async("report.generate", 42, queue: "reports")
    end
  end

  describe ".perform_in" do
    it "enqueues a job with a delay" do
      allow(Time).to receive(:now).and_return(Time.utc(2026, 1, 15, 12, 0, 0))

      expect(mock_client).to receive(:enqueue).with(
        "email.send",
        ["user@example.com"],
        queue: "default",
        scheduled_at: "2026-01-15T12:10:00Z"
      )

      described_class.perform_in("email.send", 600, "user@example.com")
    end
  end

  describe ".perform_at" do
    it "enqueues a job at a specific time" do
      target_time = Time.utc(2026, 6, 1, 9, 0, 0)

      expect(mock_client).to receive(:enqueue).with(
        "report.generate",
        ["monthly"],
        queue: "default",
        scheduled_at: "2026-06-01T09:00:00Z"
      )

      described_class.perform_at("report.generate", target_time, "monthly")
    end
  end

  describe "when client is not configured" do
    before { OJS::Sidekiq.client = nil }

    it "raises an error" do
      expect {
        described_class.perform_async("test.job")
      }.to raise_error(OJS::Sidekiq::Error, /not configured/)
    end
  end
end
