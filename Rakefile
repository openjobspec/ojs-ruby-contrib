# frozen_string_literal: true

require "rake"

GEMS = %w[ojs-rails ojs-sinatra ojs-sidekiq].freeze

desc "Run tests for all gems"
task "test:all" do
  failures = []
  GEMS.each do |gem_dir|
    Dir.chdir(gem_dir) do
      puts "\n=== Testing #{gem_dir} ==="
      sh "bundle install --quiet && bundle exec rspec"
    rescue StandardError => e
      failures << gem_dir
      puts "FAILED: #{gem_dir} — #{e.message}"
    end
  end
  abort "\nTest failures in: #{failures.join(', ')}" unless failures.empty?
end

desc "Run linter for all gems"
task "lint:all" do
  failures = []
  GEMS.each do |gem_dir|
    Dir.chdir(gem_dir) do
      puts "\n=== Linting #{gem_dir} ==="
      sh "bundle install --quiet && bundle exec rubocop"
    rescue StandardError => e
      failures << gem_dir
      puts "FAILED: #{gem_dir} — #{e.message}"
    end
  end
  abort "\nLint failures in: #{failures.join(', ')}" unless failures.empty?
end

task default: "test:all"
