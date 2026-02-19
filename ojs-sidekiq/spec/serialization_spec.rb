# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OJS::Sidekiq::Job serialization" do
  let(:mock_client) { instance_double(OJS::Client) }

  before { OJS::Sidekiq.client = mock_client }

  let(:job_class) do
    Class.new do
      include OJS::Sidekiq::Job

      def self.name
        "SerializationTestJob"
      end
    end
  end

  describe "argument serialization" do
    it "serializes string arguments" do
      expect(mock_client).to receive(:enqueue).with(
        "SerializationTestJob",
        ["hello", "world"],
        queue: "default"
      )

      job_class.perform_async("hello", "world")
    end

    it "serializes numeric arguments" do
      expect(mock_client).to receive(:enqueue).with(
        "SerializationTestJob",
        [42, 3.14],
        queue: "default"
      )

      job_class.perform_async(42, 3.14)
    end

    it "serializes hash arguments" do
      expect(mock_client).to receive(:enqueue).with(
        "SerializationTestJob",
        [{ "key" => "value" }],
        queue: "default"
      )

      job_class.perform_async({ "key" => "value" })
    end

    it "serializes array arguments" do
      expect(mock_client).to receive(:enqueue).with(
        "SerializationTestJob",
        [[1, 2, 3]],
        queue: "default"
      )

      job_class.perform_async([1, 2, 3])
    end

    it "serializes nil arguments" do
      expect(mock_client).to receive(:enqueue).with(
        "SerializationTestJob",
        [nil],
        queue: "default"
      )

      job_class.perform_async(nil)
    end

    it "serializes no arguments as empty array" do
      expect(mock_client).to receive(:enqueue).with(
        "SerializationTestJob",
        [],
        queue: "default"
      )

      job_class.perform_async
    end

    it "serializes mixed-type arguments" do
      expect(mock_client).to receive(:enqueue).with(
        "SerializationTestJob",
        [1, "two", true, nil, [3]],
        queue: "default"
      )

      job_class.perform_async(1, "two", true, nil, [3])
    end
  end

  describe "job type name" do
    it "uses the class name as the job type" do
      expect(mock_client).to receive(:enqueue).with(
        "SerializationTestJob",
        ["arg"],
        queue: "default"
      )

      job_class.perform_async("arg")
    end

    it "uses a custom class name when defined" do
      custom_job = Class.new do
        include OJS::Sidekiq::Job

        def self.name
          "Custom::Namespaced::Job"
        end
      end

      expect(mock_client).to receive(:enqueue).with(
        "Custom::Namespaced::Job",
        [],
        queue: "default"
      )

      custom_job.perform_async
    end
  end
end
