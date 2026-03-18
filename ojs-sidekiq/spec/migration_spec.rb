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

  describe ".scan" do
    it "returns an empty array when no Sidekiq modules are defined" do
      # Without real Sidekiq loaded, scan returns empty
      expect(OJS::Sidekiq::Migration.scan).to eq([])
    end
  end

  describe ".dry_run" do
    it "returns preview for given classes" do
      klass = Class.new do
        def self.name; "DryRunTarget"; end
      end

      result = OJS::Sidekiq::Migration.dry_run(klass)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:class_name]).to eq("DryRunTarget")
      expect(result.first[:already_converted]).to be false
      expect(result.first[:action]).to eq(:convert)
    end

    it "marks already-converted classes as skip" do
      klass = Class.new do
        include OJS::Sidekiq::Job
        def self.name; "AlreadyDone"; end
      end

      result = OJS::Sidekiq::Migration.dry_run(klass)

      expect(result.first[:already_converted]).to be true
      expect(result.first[:action]).to eq(:skip)
    end

    it "includes current options in preview" do
      klass = Class.new do
        def self.name; "WithOpts"; end
        def self.get_sidekiq_options
          { "queue" => "high", "retry" => 3 }
        end
      end

      result = OJS::Sidekiq::Migration.dry_run(klass)
      expect(result.first[:current_options]).to eq({ "queue" => "high", "retry" => 3 })
    end

    it "does not actually convert classes" do
      klass = Class.new do
        def self.name; "DryRunOnly"; end
      end

      OJS::Sidekiq::Migration.dry_run(klass)
      expect(klass.ancestors).not_to include(OJS::Sidekiq::Job)
    end
  end

  describe ".generate_report" do
    it "returns a structured report for given classes" do
      convertible = Class.new do
        def self.name; "ReportConvertible"; end
      end

      already_done = Class.new do
        include OJS::Sidekiq::Job
        def self.name; "ReportDone"; end
      end

      report = OJS::Sidekiq::Migration.generate_report(convertible, already_done)

      expect(report[:total]).to eq(2)
      expect(report[:to_convert]).to eq(1)
      expect(report[:already_converted]).to eq(1)
      expect(report[:classes]).to be_an(Array)
      expect(report[:classes].size).to eq(2)
      expect(report[:generated_at]).to be_a(String)
    end

    it "returns zero counts for empty input" do
      report = OJS::Sidekiq::Migration.generate_report

      expect(report[:total]).to eq(0)
      expect(report[:to_convert]).to eq(0)
      expect(report[:already_converted]).to eq(0)
    end
  end

  describe ".convert_with_validation" do
    it "converts and validates successfully" do
      klass = Class.new do
        def self.name; "ValidatedJob"; end
      end

      result = OJS::Sidekiq::Migration.convert_with_validation(klass)

      expect(result[:success]).to be true
      expect(result[:class_name]).to eq("ValidatedJob")
      expect(result[:errors]).to be_empty
    end

    it "includes class name in result" do
      klass = Class.new do
        def self.name; "NamedValidation"; end
      end

      result = OJS::Sidekiq::Migration.convert_with_validation(klass)
      expect(result[:class_name]).to eq("NamedValidation")
    end

    it "confirms perform_async is available after conversion" do
      klass = Class.new do
        def self.name; "PostConvertCheck"; end
      end

      OJS::Sidekiq::Migration.convert_with_validation(klass)

      expect(klass).to respond_to(:perform_async)
      expect(klass).to respond_to(:perform_in)
      expect(klass).to respond_to(:perform_at)
      expect(klass).to respond_to(:get_sidekiq_options)
    end
  end
end
