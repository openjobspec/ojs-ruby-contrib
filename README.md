# Open Job Spec — Ruby Contrib

Community framework integrations for the [OJS Ruby SDK](https://github.com/openjobspec/ojs-ruby-sdk).

## Provided Integrations

| Status | Integration | Description |
|--------|-------------|-------------|
| alpha  | [Rails](./ojs-rails/README.md) | ActiveJob adapter, Railtie auto-config, and `after_commit` enqueue |
| alpha  | [Sinatra](./ojs-sinatra/README.md) | Sinatra extension with helper methods |
| alpha  | [Sidekiq](./ojs-sidekiq/README.md) | Sidekiq-compatible `perform_async` API for seamless migration |

Status definitions: `alpha` (API may change), `beta` (API stable, not battle-tested), `stable` (production-ready).

## Getting Started

Each integration is a separate gem following the naming convention `ojs-{framework}`. Install the one you need:

```ruby
# Gemfile
gem "ojs-rails"    # For Rails / ActiveJob
gem "ojs-sinatra"  # For Sinatra
gem "ojs-sidekiq"  # For Sidekiq migration
```

## Development

Clone the repo and install all gems locally:

```bash
bundle install
rake test:all    # Run all tests
rake lint:all    # Run all linters
```

## License

Apache 2.0 — see [LICENSE](./LICENSE).
