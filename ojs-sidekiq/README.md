# OJS Sidekiq

Drop-in [Sidekiq](https://sidekiq.org/)-compatible API for [Open Job Spec](https://github.com/openjobspec/ojs-ruby-sdk). Migrate from Sidekiq to OJS with minimal code changes.

## Installation

Add to your Gemfile:

```ruby
gem "ojs-sidekiq"
```

## Configuration

Configure the OJS client before enqueuing jobs:

```ruby
require "ojs-sidekiq"

OJS::Sidekiq.configure do |config|
  config.client = OJS::Client.new(ENV.fetch("OJS_URL", "http://localhost:8080"))
end
```

## Usage

Replace `Sidekiq::Job` with `OJS::Sidekiq::Job`:

```ruby
# Before (Sidekiq)
class EmailWorker
  include Sidekiq::Job

  def perform(user_id, template)
    # ...
  end
end

EmailWorker.perform_async(user.id, "welcome")

# After (OJS)
class EmailWorker
  include OJS::Sidekiq::Job

  def perform(user_id, template)
    # ...
  end
end

EmailWorker.perform_async(user.id, "welcome")
```

## API Compatibility

| Sidekiq API | OJS Equivalent | Status |
|-------------|----------------|--------|
| `perform_async(*args)` | `enqueue(args: args)` | ✅ |
| `perform_in(interval, *args)` | `enqueue(args: args, scheduled_at: ...)` | ✅ |
| `perform_at(time, *args)` | `enqueue(args: args, scheduled_at: ...)` | ✅ |
| `sidekiq_options` | Maps to OJS queue/retry config | ✅ |

## Migration Helper

Use the migration module for a phased rollout:

```ruby
require "ojs/sidekiq/migration"

# Converts existing Sidekiq job classes to use OJS
OJS::Sidekiq::Migration.convert(EmailWorker)
```

## Status

**Alpha** — API may change.

## License

Apache 2.0 — see [LICENSE](../LICENSE).
