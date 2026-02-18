# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OJS Rails Generators" do
  describe "InstallGenerator" do
    let(:template_dir) do
      File.expand_path(
        "../../lib/generators/ojs/install/templates",
        __dir__
      )
    end

    it "has an initializer template" do
      expect(File.exist?(File.join(template_dir, "initializer.rb"))).to be true
    end

    it "has an ojs.yml template" do
      expect(File.exist?(File.join(template_dir, "ojs.yml"))).to be true
    end

    it "initializer template contains OJS configuration block" do
      content = File.read(File.join(template_dir, "initializer.rb"))
      expect(content).to include("OJS::Rails.configure")
      expect(content).to include("config.url")
      expect(content).to include("config.queue_prefix")
      expect(content).to include("config.retry_policy")
      expect(content).to include("queue_adapter = :ojs")
      expect(content).to include("frozen_string_literal: true")
    end

    it "ojs.yml template has environment-specific configs" do
      content = File.read(File.join(template_dir, "ojs.yml"))
      expect(content).to include("development:")
      expect(content).to include("test:")
      expect(content).to include("staging:")
      expect(content).to include("production:")
      expect(content).to include("retry_policy:")
      expect(content).to include("queue_prefix:")
    end
  end

  describe "JobGenerator" do
    let(:template_path) do
      File.expand_path(
        "../../lib/generators/ojs/job/templates/job.rb",
        __dir__
      )
    end

    it "has a job template" do
      expect(File.exist?(template_path)).to be true
    end

    it "template contains ApplicationJob subclass" do
      content = File.read(template_path)
      expect(content).to include("< ApplicationJob")
      expect(content).to include("queue_as")
      expect(content).to include("def perform")
      expect(content).to include("frozen_string_literal: true")
    end

    it "template includes OJS-specific guidance" do
      content = File.read(template_path)
      expect(content).to include("OJS::Rails::ActiveJob::Callbacks")
      expect(content).to include("retry_on")
      expect(content).to include("discard_on")
    end
  end
end
