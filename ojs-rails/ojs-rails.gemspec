# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "ojs-rails"
  spec.version       = "0.9.0"
  spec.authors       = ["OpenJobSpec Contributors"]
  spec.email         = ["contributors@openjobspec.org"]

  spec.summary       = "Rails integration for Open Job Spec"
  spec.description   = "First-class Rails integration for Open Job Spec (OJS): ActiveJob adapter, " \
                        "Railtie auto-configuration from config/ojs.yml or Rails credentials, " \
                        "request-scoped middleware, transactional after_commit enqueue, and generators."
  spec.homepage      = "https://github.com/openjobspec/ojs-ruby-contrib"
  spec.license       = "Apache-2.0"

  spec.required_ruby_version = ">= 3.2"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.files        += Dir["lib/generators/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "ojs", "~> 0.2"
  spec.add_dependency "activejob", ">= 7.0"
  spec.add_dependency "railties", ">= 7.0"

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.60"
  spec.add_development_dependency "rubocop-rspec", "~> 2.25"

  spec.metadata = {
    "homepage_uri"          => spec.homepage,
    "source_code_uri"       => "https://github.com/openjobspec/ojs-ruby-contrib/tree/main/ojs-rails",
    "changelog_uri"         => "https://github.com/openjobspec/ojs-ruby-contrib/blob/main/ojs-rails/CHANGELOG.md",
    "bug_tracker_uri"       => "https://github.com/openjobspec/ojs-ruby-contrib/issues",
    "rubygems_mfa_required" => "true",
  }
end
