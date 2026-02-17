# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveJob::QueueAdapters::OjsAdapter do
  subject(:adapter) { described_class.new }

  let(:mock_client) { instance_double(OJS::Client) }

  before do
    OJS::Rails.client = mock_client
  end

  describe "#enqueue" do
    it "enqueues a job via the OJS client" do
      job = double(
        "ActiveJob",
        class: double(name: "EmailJob"),
        queue_name: "default",
        arguments: ["user@example.com", "welcome"],
        job_id: "abc-123",
        priority: nil
      )

      expect(mock_client).to receive(:enqueue).with(
        "EmailJob",
        ["user@example.com", "welcome"],
        queue: "default",
        meta: {
          "active_job_id" => "abc-123",
          "priority" => nil
        }
      )

      adapter.enqueue(job)
    end
  end

  describe "#enqueue_at" do
    it "enqueues a scheduled job via the OJS client" do
      job = double(
        "ActiveJob",
        class: double(name: "ReportJob"),
        queue_name: "reports",
        arguments: [42],
        job_id: "def-456",
        priority: 10
      )

      timestamp = Time.utc(2026, 1, 15, 12, 0, 0).to_f

      expect(mock_client).to receive(:enqueue).with(
        "ReportJob",
        [42],
        queue: "reports",
        scheduled_at: "2026-01-15T12:00:00Z",
        meta: {
          "active_job_id" => "def-456",
          "priority" => 10
        }
      )

      adapter.enqueue_at(job, timestamp)
    end
  end

  describe "when client is not configured" do
    before { OJS::Rails.client = nil }

    it "raises an error on enqueue" do
      job = double(
        "ActiveJob",
        class: double(name: "TestJob"),
        queue_name: "default",
        arguments: [],
        job_id: "test-1",
        priority: nil
      )

      expect { adapter.enqueue(job) }.to raise_error(OJS::Rails::Error, /not configured/)
    end
  end
end
