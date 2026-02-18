# OJS Rails

First-class [Rails](https://rubyonrails.org/) integration for [Open Job Spec](https://github.com/openjobspec/ojs-ruby-sdk) — the universal, vendor-neutral standard for background job processing.

Provides an [ActiveJob](https://guides.rubyonrails.org/active_job_basics.html) adapter, Railtie auto-configuration, request-scoped middleware, transactional `after_commit` enqueue, and Rails generators.

[![Gem Version](https://badge.fury.io/rb/ojs-rails.svg)](https://rubygems.org/gems/ojs-rails)

## Installation

Add to your Gemfile:

```ruby
gem "ojs-rails"
```

Then run:

```bash
bundle install
rails generate ojs:install
```

This creates:
- `config/initializers/ojs.rb` — Configuration initializer
- `config/ojs.yml` — Environment-specific settings

## Configuration

OJS Rails loads configuration in priority order:

1. `config/ojs.yml` (lowest priority)
2. Rails credentials (`config/credentials.yml.enc`)
3. `config/initializers/ojs.rb` (highest priority)

### Initializer (config/initializers/ojs.rb)

```ruby
OJS::Rails.configure do |config|
  config.url = ENV.fetch("OJS_URL", "http://localhost:8080")
  config.queue_prefix = Rails.env
  config.default_queue = "default"
  config.timeout = 15
  config.headers = { "Authorization" => "Bearer #{ENV['OJS_TOKEN']}" }

  # Default retry policy for all jobs
  config.retry_policy = {
    max_attempts: 5,
    initial_interval: "PT1S",
    backoff_coefficient: 2.0,
    max_interval: "PT10M",
  }
end

Rails.application.config.active_job.queue_adapter = :ojs
```

### YAML config (config/ojs.yml)

```yaml
development:
  url: http://localhost:8080
  default_queue: default

production:
  url: http://ojs:8080
  queue_prefix: production
  timeout: 15
  retry_policy:
    max_attempts: 10
    initial_interval: PT2S
    backoff_coefficient: 2.0
```

### Rails Credentials

```bash
rails credentials:edit
```

```yaml
ojs:
  url: https://ojs.production.internal:8080
  queue_prefix: production
```

## ActiveJob Usage

### Basic Job

```ruby
class EmailJob < ApplicationJob
  queue_as :mailers

  def perform(user_id, template)
    user = User.find(user_id)
    UserMailer.send(template, user).deliver_now
  end
end

# Enqueue
EmailJob.perform_later(user.id, "welcome")

# Schedule for later
EmailJob.set(wait: 5.minutes).perform_later(user.id, "reminder")

# With priority (0 = highest, 10 = lowest in ActiveJob)
EmailJob.set(priority: 0).perform_later(user.id, "urgent")
```

### OJS Lifecycle Callbacks

Include `OJS::Rails::ActiveJob::Callbacks` for automatic error classification and lifecycle logging:

```ruby
class ApplicationJob < ActiveJob::Base
  include OJS::Rails::ActiveJob::Callbacks
end
```

This provides:
- `around_perform` lifecycle tracking with timing
- Automatic error classification to OJS error codes
- Retryable vs non-retryable error detection

### Priority Mapping

ActiveJob priorities (lower = higher priority) are mapped to OJS priorities (higher = higher priority):

| ActiveJob | OJS  | Meaning |
|-----------|------|---------|
| 0         | 10   | Urgent  |
| 5         | 0    | Normal  |
| 10        | -10  | Low     |

Customize the mapping:

```ruby
OJS::Rails.configure do |config|
  config.priority_map = {
    0 => 100,  # critical
    1 => 50,   # high
    5 => 0,    # normal
    10 => -50, # low
  }
end
```

### Queue Name Prefixing

When `queue_prefix` is set, all queue names are automatically prefixed:

```ruby
OJS::Rails.configure do |config|
  config.queue_prefix = Rails.env  # "production"
end

# EmailJob with queue_as :mailers → enqueued to "production_mailers"
```

## Request-Scoped Middleware

Buffer jobs during a web request and flush them only on success:

```ruby
# config/application.rb
config.middleware.use OJS::Rails::Middleware
```

```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.create!(order_params)

    # Jobs are buffered and only enqueued if the response is successful (< 500)
    OJS::Rails::Middleware.enqueue("order.confirm", [@order.id])
    OJS::Rails::Middleware.enqueue("analytics.track", [@order.id, "created"])

    render json: @order, status: :created
  end
end
```

Multiple buffered jobs are automatically batched via `enqueue_batch` for efficiency.

## Transactional Enqueue

Enqueue jobs only after the database transaction commits:

```ruby
class User < ApplicationRecord
  after_commit :send_welcome_email, on: :create

  private

  def send_welcome_email
    OJS::Rails::Enqueue.after_commit("email.send", [id, "welcome"])
  end
end
```

Or enqueue immediately:

```ruby
OJS::Rails::Enqueue.enqueue_now("report.generate", [42], queue: "reports")
```

## Generators

### Install

```bash
rails generate ojs:install
```

Creates `config/initializers/ojs.rb` and `config/ojs.yml`.

### Job

```bash
rails generate ojs:job SendEmail
rails generate ojs:job ProcessOrder --queue=orders --priority=0
```

Creates `app/jobs/send_email_job.rb` with OJS boilerplate.

## Migration from Sidekiq

| Sidekiq | OJS Rails |
|---------|-----------|
| `include Sidekiq::Job` | `class MyJob < ApplicationJob` |
| `sidekiq_options queue: :default` | `queue_as :default` |
| `perform_async(args)` | `MyJob.perform_later(args)` |
| `perform_in(5.minutes, args)` | `MyJob.set(wait: 5.minutes).perform_later(args)` |
| `Sidekiq.configure_server` | `OJS::Rails.configure` |
| `config/sidekiq.yml` | `config/ojs.yml` |

## Migration from GoodJob

| GoodJob | OJS Rails |
|---------|-----------|
| `config.active_job.queue_adapter = :good_job` | `config.active_job.queue_adapter = :ojs` |
| `GoodJob.retry_on_unhandled_error = true` | `config.retry_policy = { max_attempts: 5 }` |
| `good_job.yml` | `config/ojs.yml` |

GoodJob users already using ActiveJob need only change the adapter — all `perform_later`, `set()`, `queue_as`, and `retry_on`/`discard_on` calls work unchanged.

## Status

**Beta** — API is stabilizing. Suitable for production use with the understanding that minor breaking changes may occur before 1.0.

## Requirements

- Ruby >= 3.2
- Rails >= 7.0
- [ojs](https://rubygems.org/gems/ojs) gem (Ruby SDK)

## License

Apache 2.0 — see [LICENSE](../LICENSE).
