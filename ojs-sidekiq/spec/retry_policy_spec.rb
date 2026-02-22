# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OJS::Sidekiq::Job retry policy mapping" do
  let(:mock_client) { instance_double(OJS::Client) }

  before { OJS::Sidekiq.client = mock_client }

  describe "sidekiq_options retry" do
    it "stores default retry value of 25" do
      job_class = Class.new do
        include OJS::Sidekiq::Job
        def self.name; "DefaultRetryJob"; end
      end

      expect(job_class.get_sidekiq_options["retry"]).to eq(25)
    end

    it "stores custom retry value" do
      job_class = Class.new do
        include OJS::Sidekiq::Job
        sidekiq_options retry: 3
        def self.name; "CustomRetryJob"; end
      end

      expect(job_class.get_sidekiq_options["retry"]).to eq(3)
    end

    it "allows retry to be set to false (no retries)" do
      job_class = Class.new do
        include OJS::Sidekiq::Job
        sidekiq_options retry: false
        def self.name; "NoRetryJob"; end
      end

      expect(job_class.get_sidekiq_options["retry"]).to be false
    end

    it "allows retry to be set to zero" do
      job_class = Class.new do
        include OJS::Sidekiq::Job
        sidekiq_options retry: 0
        def self.name; "ZeroRetryJob"; end
      end

      expect(job_class.get_sidekiq_options["retry"]).to eq(0)
    end

    it "merges retry with other options" do
      job_class = Class.new do
        include OJS::Sidekiq::Job
        sidekiq_options queue: "critical", retry: 10
        def self.name; "MergedOptionsJob"; end
      end

      opts = job_class.get_sidekiq_options
      expect(opts["queue"]).to eq("critical")
      expect(opts["retry"]).to eq(10)
    end
  end

  describe "options isolation between job classes" do
    it "does not share options between different job classes" do
      job_a = Class.new do
        include OJS::Sidekiq::Job
        sidekiq_options retry: 3
        def self.name; "JobA"; end
      end

      job_b = Class.new do
        include OJS::Sidekiq::Job
        sidekiq_options retry: 10
        def self.name; "JobB"; end
      end

      expect(job_a.get_sidekiq_options["retry"]).to eq(3)
      expect(job_b.get_sidekiq_options["retry"]).to eq(10)
    end
  end
end

