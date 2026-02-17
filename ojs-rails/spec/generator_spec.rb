# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OJS Rails Generators" do
  describe "InstallGenerator" do
    let(:template_path) do
      File.expand_path(
        "../../lib/generators/ojs/install/templates/initializer.rb",
        __dir__
      )
    end

    it "has an initializer template" do
      expect(File.exist?(template_path)).to be true
    end

    it "template contains OJS configuration" do
      content = File.read(template_path)
      expect(content).to include("config.ojs.url")
      expect(content).to include("config.active_job.queue_adapter = :ojs")
      expect(content).to include("frozen_string_literal: true")
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
      expect(content).to include("queue_as :default")
      expect(content).to include("def perform")
      expect(content).to include("frozen_string_literal: true")
    end
  end
end
