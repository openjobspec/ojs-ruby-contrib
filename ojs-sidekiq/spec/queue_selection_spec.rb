# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OJS::Sidekiq::Job queue selection" do
  let(:mock_client) { instance_double(OJS::Client) }

  before { OJS::Sidekiq.client = mock_client }

  describe "default queue" do
    let(:job_class) do
      Class.new do
        include OJS::Sidekiq::Job
        def self.name; "DefaultQueueJob"; end
      end
    end

    it "uses 'default' queue when no queue specified" do
      expect(mock_client).to receive(:enqueue).with(
        "DefaultQueueJob",
        [],
        queue: "default"
      )

      job_class.perform_async
    end

    it "stores 'default' in sidekiq_options" do
      expect(job_class.get_sidekiq_options["queue"]).to eq("default")
    end
  end

  describe "custom queue via sidekiq_options" do
    let(:job_class) do
      Class.new do
        include OJS::Sidekiq::Job
        sidekiq_options queue: "critical"
        def self.name; "CriticalJob"; end
      end
    end

    it "enqueues to the configured queue" do
      expect(mock_client).to receive(:enqueue).with(
        "CriticalJob",
        ["data"],
        queue: "critical"
      )

      job_class.perform_async("data")
    end

    it "applies custom queue to perform_in" do
      allow(Time).to receive(:now).and_return(Time.utc(2026, 1, 1, 0, 0, 0))

      expect(mock_client).to receive(:enqueue).with(
        "CriticalJob",
        [1],
        queue: "critical",
        scheduled_at: anything
      )

      job_class.perform_in(60, 1)
    end

    it "applies custom queue to perform_at" do
      target = Time.utc(2026, 6, 1, 12, 0, 0)

      expect(mock_client).to receive(:enqueue).with(
        "CriticalJob",
        [1],
        queue: "critical",
        scheduled_at: anything
      )

      job_class.perform_at(target, 1)
    end
  end

  describe "string vs symbol queue names" do
    it "normalizes symbol queue names to strings" do
      job_class = Class.new do
        include OJS::Sidekiq::Job
        sidekiq_options queue: :mailers
        def self.name; "MailerJob"; end
      end

      expect(job_class.get_sidekiq_options["queue"]).to eq(:mailers)
    end
  end

  describe "Compat module queue selection" do
    it "uses default queue" do
      expect(mock_client).to receive(:enqueue).with(
        "email.send",
        ["user@test.com"],
        queue: "default"
      )

      OJS::Sidekiq::Compat.perform_async("email.send", "user@test.com")
    end

    it "uses custom queue" do
      expect(mock_client).to receive(:enqueue).with(
        "report.run",
        [42],
        queue: "reports"
      )

      OJS::Sidekiq::Compat.perform_async("report.run", 42, queue: "reports")
    end
  end
end
