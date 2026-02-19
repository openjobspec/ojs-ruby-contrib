# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "ojs-sinatra"
  spec.version       = "0.9.0"
  spec.authors       = ["OpenJobSpec Contributors"]
  spec.email         = ["contributors@openjobspec.org"]

  spec.summary       = "Sinatra integration for Open Job Spec"
  spec.description   = "Sinatra extension with helper methods for OJS job enqueue"
  spec.homepage      = "https://github.com/openjobspec/ojs-ruby-contrib"
  spec.license       = "Apache-2.0"

  spec.required_ruby_version = ">= 3.2"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "ojs", "~> 0.1"
  spec.add_dependency "sinatra", ">= 4.0"

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rack-test", "~> 2.1"
  spec.add_development_dependency "rubocop", "~> 1.60"
  spec.add_development_dependency "rubocop-rspec", "~> 2.25"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/openjobspec/ojs-ruby-contrib/tree/main/ojs-sinatra"
  spec.metadata["changelog_uri"] = "https://github.com/openjobspec/ojs-ruby-contrib/blob/main/CHANGELOG.md"
end
