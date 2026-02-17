# OJS Sinatra

[Sinatra](https://sinatrarb.com/) extension for [Open Job Spec](https://github.com/openjobspec/ojs-ruby-sdk), providing helper methods for job enqueue within Sinatra applications.

## Installation

Add to your Gemfile:

```ruby
gem "ojs-sinatra"
```

## Usage

```ruby
require "sinatra"
require "ojs-sinatra"

register OJS::Sinatra::Extension

configure do
  set :ojs_url, ENV.fetch("OJS_URL", "http://localhost:8080")
end

post "/send-email" do
  enqueue_job("email.send", [params[:user_id], params[:template]])
  status 202
  json status: "enqueued"
end
```

## Helpers

- `ojs_client` — Returns the configured OJS client instance
- `enqueue_job(type, args, **options)` — Enqueue a job with the given type and arguments

## Status

**Alpha** — API may change.

## License

Apache 2.0 — see [LICENSE](../LICENSE).
