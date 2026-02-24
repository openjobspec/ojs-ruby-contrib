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
        priority: nil,
        executions: 0,
        locale: "en",
        provider_job_id: nil
      )

      allow(job).to receive(:provider_job_id=)

      expect(mock_client).to receive(:enqueue).with(
        "EmailJob",
        ["user@example.com", "welcome"],
        queue: "default",
        meta: hash_including(
          "active_job_id" => "abc-123",
          "active_job_class" => "EmailJob"
        )
      ).and_return(double(id: "ojs-job-1"))

      adapter.enqueue(job)
      expect(job).to have_received(:provider_job_id=).with("ojs-job-1")
    end

    it "applies queue prefix from configuration" do
      OJS::Rails.configuration.queue_prefix = "production"

      job = double(
        "ActiveJob",
        class: double(name: "EmailJob"),
        queue_name: "mailers",
        arguments: [],
        job_id: "abc-123",
        priority: nil,
        executions: 0,
        locale: "en",
        provider_job_id: nil
      )
      allow(job).to receive(:provider_job_id=)

      expect(mock_client).to receive(:enqueue).with(
        "EmailJob",
        [],
        queue: "production_mailers",
        meta: anything
      ).and_return(double(id: "ojs-job-2"))

      adapter.enqueue(job)
    end

    it "maps ActiveJob priority to OJS priority" do
      OJS::Rails.configuration.queue_prefix = nil

      job = double(
        "ActiveJob",
        class: double(name: "UrgentJob"),
        queue_name: "default",
        arguments: [],
        job_id: "abc-123",
        priority: 0,
        executions: 0,
        locale: "en",
        provider_job_id: nil
      )
      allow(job).to receive(:provider_job_id=)

      expect(mock_client).to receive(:enqueue).with(
        "UrgentJob",
        [],
        queue: "default",
        priority: 10,
        meta: anything
      ).and_return(double(id: "ojs-job-3"))

      adapter.enqueue(job)
    end

    it "includes executions in meta when > 0" do
      job = double(
        "ActiveJob",
        class: double(name: "RetryJob"),
        queue_name: "default",
        arguments: [],
        job_id: "abc-123",
        priority: nil,
        executions: 3,
        locale: "en",
        provider_job_id: nil
      )
      allow(job).to receive(:provider_job_id=)

      expect(mock_client).to receive(:enqueue).with(
        "RetryJob",
        [],
        queue: "default",
        meta: hash_including("executions" => 3)
      ).and_return(double(id: "ojs-job-4"))

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
        priority: 10,
        executions: 0,
        locale: "en",
        provider_job_id: nil
      )
      allow(job).to receive(:provider_job_id=)

      timestamp = Time.utc(2026, 1, 15, 12, 0, 0).to_f

      expect(mock_client).to receive(:enqueue).with(
        "ReportJob",
        [42],
        scheduled_at: "2026-01-15T12:00:00Z",
        queue: "reports",
        priority: -10,
        meta: hash_including("active_job_id" => "def-456")
      ).and_return(double(id: "ojs-job-5"))

      adapter.enqueue_at(job, timestamp)
    end
  end

  describe "#enqueue with retry policy" do
    it "includes retry policy from configuration" do
      OJS::Rails.configuration.retry_policy = { max_attempts: 5 }

      job = double(
        "ActiveJob",
        class: double(name: "ReliableJob"),
        queue_name: "default",
        arguments: [],
        job_id: "abc-123",
        priority: nil,
        executions: 0,
        locale: "en",
        provider_job_id: nil
      )
      allow(job).to receive(:provider_job_id=)

      expect(mock_client).to receive(:enqueue).with(
        "ReliableJob",
        [],
        queue: "default",
        retry: { max_attempts: 5 },
        meta: anything
      ).and_return(double(id: "ojs-job-6"))

      adapter.enqueue(job)
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
        priority: nil,
        executions: 0,
        locale: "en",
        provider_job_id: nil
      )

      expect { adapter.enqueue(job) }.to raise_error(OJS::Rails::Error, /not configured/)
    end
  end
end

