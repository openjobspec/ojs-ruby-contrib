# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OJS::Sidekiq error handling" do
  describe OJS::Sidekiq::Error do
    it "is a subclass of StandardError" do
      expect(OJS::Sidekiq::Error).to be < StandardError
    end

    it "can be raised with a message" do
      expect {
        raise OJS::Sidekiq::Error, "something went wrong"
      }.to raise_error(OJS::Sidekiq::Error, "something went wrong")
    end
  end

  describe "client not configured" do
    before { OJS::Sidekiq.client = nil }

    context "with Job class" do
      let(:job_class) do
        Class.new do
          include OJS::Sidekiq::Job
          def self.name; "UnconfiguredJob"; end
        end
      end

      it "raises on perform_async" do
        expect { job_class.perform_async("arg") }.to raise_error(OJS::Sidekiq::Error, /not configured/)
      end

      it "raises on perform_in" do
        expect { job_class.perform_in(60, "arg") }.to raise_error(StandardError)
      end

      it "raises on perform_at" do
        expect { job_class.perform_at(Time.now, "arg") }.to raise_error(OJS::Sidekiq::Error, /not configured/)
      end
    end

    context "with Compat module" do
      it "raises on perform_async" do
        expect {
          OJS::Sidekiq::Compat.perform_async("test.job")
        }.to raise_error(OJS::Sidekiq::Error, /not configured/)
      end

      it "raises on perform_in" do
        expect {
          OJS::Sidekiq::Compat.perform_in("test.job", 60)
        }.to raise_error(StandardError)
      end

      it "raises on perform_at" do
        expect {
          OJS::Sidekiq::Compat.perform_at("test.job", Time.now)
        }.to raise_error(OJS::Sidekiq::Error, /not configured/)
      end
    end
  end

  describe "configure block" do
    it "yields self for configuration" do
      yielded = nil
      OJS::Sidekiq.configure { |c| yielded = c }
      expect(yielded).to eq(OJS::Sidekiq)
    end

    it "allows setting client via configure" do
      mock_client = instance_double(OJS::Client)
      OJS::Sidekiq.configure { |c| c.client = mock_client }
      expect(OJS::Sidekiq.client).to eq(mock_client)
    end

    it "works without a block" do
      expect { OJS::Sidekiq.configure }.not_to raise_error
    end
  end
end
