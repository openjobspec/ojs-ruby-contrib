# frozen_string_literal: true

require "spec_helper"

RSpec.describe OJS::Sidekiq::Migration do
  let(:mock_client) { instance_double(OJS::Client) }

  before { OJS::Sidekiq.client = mock_client }

  describe ".convert" do
    it "adds OJS::Sidekiq::Job to the class ancestors" do
      klass = Class.new do
        def self.name; "MigrationTarget"; end
      end

      OJS::Sidekiq::Migration.convert(klass)
      expect(klass.ancestors).to include(OJS::Sidekiq::Job)
    end

    it "makes perform_async available after conversion" do
      klass = Class.new do
        def self.name; "ConvertedJob"; end
      end

      OJS::Sidekiq::Migration.convert(klass)

      expect(mock_client).to receive(:enqueue).with("ConvertedJob", [1], queue: "default")
      klass.perform_async(1)
    end

    it "preserves existing sidekiq_options after conversion" do
      klass = Class.new do
        def self.name; "JobWithOptions"; end

        def self.get_sidekiq_options
          { "queue" => "high", "retry" => 3 }
        end
      end

      OJS::Sidekiq::Migration.convert(klass)

      opts = klass.get_sidekiq_options
      expect(opts["queue"]).to eq("high")
      expect(opts["retry"]).to eq(3)
    end

    it "skips conversion if already includes OJS::Sidekiq::Job" do
      klass = Class.new do
        include OJS::Sidekiq::Job
        def self.name; "AlreadyConverted"; end
      end

      # Should not raise or double-include
      expect { OJS::Sidekiq::Migration.convert(klass) }.not_to raise_error
    end

    it "handles classes without get_sidekiq_options" do
      klass = Class.new do
        def self.name; "PlainClass"; end
      end

      OJS::Sidekiq::Migration.convert(klass)
      expect(klass.ancestors).to include(OJS::Sidekiq::Job)
      expect(klass.get_sidekiq_options).to include("queue" => "default")
    end
  end

  describe ".convert_all" do
    it "converts multiple classes at once" do
      klass_a = Class.new do
        def self.name; "BatchJobA"; end
      end

      klass_b = Class.new do
        def self.name; "BatchJobB"; end
      end

      OJS::Sidekiq::Migration.convert_all(klass_a, klass_b)

      expect(klass_a.ancestors).to include(OJS::Sidekiq::Job)
      expect(klass_b.ancestors).to include(OJS::Sidekiq::Job)
    end

    it "makes perform_async available on all converted classes" do
      klass_a = Class.new do
        def self.name; "AsyncBatchA"; end
      end

      klass_b = Class.new do
        def self.name; "AsyncBatchB"; end
      end

      OJS::Sidekiq::Migration.convert_all(klass_a, klass_b)

      expect(mock_client).to receive(:enqueue).with("AsyncBatchA", [1], queue: "default")
      expect(mock_client).to receive(:enqueue).with("AsyncBatchB", [2], queue: "default")

      klass_a.perform_async(1)
      klass_b.perform_async(2)
    end
  end
end
