# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe OJS::Sinatra::Tasks do
  before(:each) do
    Rake::Task.clear
  end

  describe ".install" do
    it "defines ojs:worker task" do
      described_class.install

      expect(Rake::Task.task_defined?("ojs:worker")).to be true
    end

    it "defines ojs:health task" do
      described_class.install

      expect(Rake::Task.task_defined?("ojs:health")).to be true
    end

    it "defines ojs:enqueue task" do
      described_class.install

      expect(Rake::Task.task_defined?("ojs:enqueue")).to be true
    end

    it "defines ojs:queues task" do
      described_class.install

      expect(Rake::Task.task_defined?("ojs:queues")).to be true
    end

    it "supports a custom namespace" do
      described_class.install(namespace: :jobs)

      expect(Rake::Task.task_defined?("jobs:worker")).to be true
      expect(Rake::Task.task_defined?("jobs:health")).to be true
      expect(Rake::Task.task_defined?("jobs:enqueue")).to be true
      expect(Rake::Task.task_defined?("jobs:queues")).to be true
    end
  end
end
