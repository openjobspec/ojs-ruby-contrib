# Contributing to OJS Ruby Contrib

Thank you for your interest in contributing to the Open Job Spec Ruby integrations!

## Development Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/openjobspec/ojs-ruby-contrib.git
   cd ojs-ruby-contrib
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Run all tests:

   ```bash
   rake test:all
   ```

## Adding a New Integration

1. Create a new directory: `ojs-{framework}/`
2. Follow the existing gem structure (see `ojs-rails/` as a reference)
3. Include: gemspec, Gemfile, lib/, spec/, examples/, and README.md
4. Add the gem path to the root `Gemfile`
5. Add the gem's Rake tasks to the root `Rakefile`
6. Update the root README.md status table

## Coding Standards

- Use `frozen_string_literal: true` in all Ruby files
- Follow [Ruby Style Guide](https://rubystyle.guide/) conventions
- Use RSpec for testing
- Use RuboCop for linting
- All public methods must have YARD documentation

## Testing

- Tests use RSpec with mocks — no real OJS backend needed for unit tests
- Each gem has its own `spec/` directory with a `spec_helper.rb`
- Run a single gem's tests: `cd ojs-rails && bundle exec rspec`
- Run all tests: `rake test:all`

## Pull Request Process

1. Fork the repository and create a feature branch
2. Add tests for any new functionality
3. Ensure all tests pass (`rake test:all`)
4. Ensure linting passes (`rake lint:all`)
5. Update CHANGELOG.md with your changes
6. Submit a pull request

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 License.
