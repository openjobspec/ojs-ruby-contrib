# OJS Rails

[ActiveJob](https://guides.rubyonrails.org/active_job_basics.html) adapter for [Open Job Spec](https://github.com/openjobspec/ojs-ruby-sdk), with Railtie auto-configuration and transactional `after_commit` enqueue support.

## Installation

Add to your Gemfile:

```ruby
gem "ojs-rails"
```

## Configuration

In `config/application.rb` or an initializer:

```ruby
# config/initializers/ojs.rb
Rails.application.configure do
  config.ojs.url = ENV.fetch("OJS_URL", "http://localhost:8080")
  config.active_job.queue_adapter = :ojs
end
```

## Features

### ActiveJob Adapter

Use OJS as the backend for any ActiveJob class:

```ruby
class EmailJob < ApplicationJob
  queue_as :default

  def perform(user_id, template)
    # your job logic
  end
end

EmailJob.perform_later(user.id, "welcome")
```

### Transactional Enqueue

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

### Generators

```bash
rails generate ojs:install    # Create initializer
rails generate ojs:job MyJob  # Create OJS-backed job class
```

## Status

**Alpha** — API may change.

## License

Apache 2.0 — see [LICENSE](../LICENSE).
