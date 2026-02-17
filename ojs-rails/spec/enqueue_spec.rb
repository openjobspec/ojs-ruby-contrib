# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Rails::Enqueue do
  let(:mock_client) { instance_double(OJS::Client) }

  before do
    OJS::Rails.client = mock_client
  end

  describe ".enqueue_now" do
    it "enqueues a job immediately via the OJS client" do
      expect(mock_client).to receive(:enqueue).with(
        "email.send",
        ["user@example.com", "welcome"],
        queue: "default"
      )

      described_class.enqueue_now("email.send", ["user@example.com", "welcome"])
    end

    it "uses a custom queue when specified" do
      expect(mock_client).to receive(:enqueue).with(
        "report.generate",
        [42],
        queue: "reports"
      )

      described_class.enqueue_now("report.generate", [42], queue: "reports")
    end

    it "raises an error when client is not configured" do
      OJS::Rails.client = nil

      expect {
        described_class.enqueue_now("test.job", [])
      }.to raise_error(OJS::Rails::Error, /not configured/)
    end
  end

  describe ".after_commit" do
    it "enqueues immediately when no transaction is open" do
      expect(mock_client).to receive(:enqueue).with(
        "email.send",
        ["user@example.com"],
        queue: "default"
      )

      described_class.after_commit("email.send", ["user@example.com"])
    end

    it "passes additional options through" do
      expect(mock_client).to receive(:enqueue).with(
        "email.send",
        [1],
        queue: "mailers",
        scheduled_at: "2026-01-15T12:00:00Z"
      )

      described_class.after_commit(
        "email.send", [1],
        queue: "mailers",
        scheduled_at: "2026-01-15T12:00:00Z"
      )
    end
  end
end
