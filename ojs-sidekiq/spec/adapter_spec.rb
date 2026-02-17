# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Sidekiq::Job do
  let(:mock_client) { instance_double(OJS::Client) }

  before do
    OJS::Sidekiq.client = mock_client
  end

  let(:job_class) do
    Class.new do
      include OJS::Sidekiq::Job
      sidekiq_options queue: "critical", retry: 5

      def self.name
        "TestEmailJob"
      end
    end
  end

  describe ".perform_async" do
    it "enqueues a job via the OJS client" do
      expect(mock_client).to receive(:enqueue).with(
        "TestEmailJob",
        ["user@example.com", "welcome"],
        queue: "critical"
      )

      job_class.perform_async("user@example.com", "welcome")
    end
  end

  describe ".perform_in" do
    it "enqueues a scheduled job with a delay" do
      allow(Time).to receive(:now).and_return(Time.utc(2026, 1, 15, 12, 0, 0))

      expect(mock_client).to receive(:enqueue).with(
        "TestEmailJob",
        [42],
        queue: "critical",
        scheduled_at: "2026-01-15T12:05:00Z"
      )

      job_class.perform_in(300, 42)
    end
  end

  describe ".perform_at" do
    it "enqueues a job scheduled at a specific time" do
      target_time = Time.utc(2026, 6, 1, 9, 0, 0)

      expect(mock_client).to receive(:enqueue).with(
        "TestEmailJob",
        ["report"],
        queue: "critical",
        scheduled_at: "2026-06-01T09:00:00Z"
      )

      job_class.perform_at(target_time, "report")
    end
  end

  describe ".sidekiq_options" do
    it "stores options" do
      expect(job_class.get_sidekiq_options).to include("queue" => "critical", "retry" => 5)
    end
  end

  describe "when client is not configured" do
    before { OJS::Sidekiq.client = nil }

    it "raises an error on perform_async" do
      expect { job_class.perform_async("test") }.to raise_error(OJS::Sidekiq::Error, /not configured/)
    end
  end
end

RSpec.describe OJS::Sidekiq::Migration do
  let(:mock_client) { instance_double(OJS::Client) }

  before do
    OJS::Sidekiq.client = mock_client
  end

  it "converts a class to use OJS::Sidekiq::Job" do
    klass = Class.new do
      def self.name
        "LegacyJob"
      end
    end

    OJS::Sidekiq::Migration.convert(klass)
    expect(klass.ancestors).to include(OJS::Sidekiq::Job)
  end
end
