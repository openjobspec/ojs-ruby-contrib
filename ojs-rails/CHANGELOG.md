# Changelog

All notable changes to ojs-rails will be documented in this file.

## [0.2.0] - 2025-07-17

### Added
- **Configuration DSL** — `OJS::Rails.configure` block with `url`, `queue_prefix`, `default_queue`, `retry_policy`, `timeout`, `headers`, and `priority_map` options.
- **YAML configuration** — Auto-loads `config/ojs.yml` with environment-specific settings.
- **Rails credentials support** — Reads OJS config from `config/credentials.yml.enc`.
- **Priority mapping** — Automatic translation from ActiveJob integer priorities to OJS priorities.
- **Queue name prefixing** — Optional prefix (e.g. Rails.env) prepended to all queue names.
- **ActiveJob callbacks module** — `OJS::Rails::ActiveJob::Callbacks` with lifecycle tracking and error classification.
- **Request-scoped middleware** — `OJS::Rails::Middleware` buffers jobs during a request and flushes on success, with automatic batching.
- **Enhanced generators** — `ojs:install` now creates both initializer and `config/ojs.yml`; `ojs:job` supports `--queue` and `--priority` options.
- **Provider job ID** — `enqueue` and `enqueue_at` now set `provider_job_id` on the ActiveJob instance.
- **ActiveJob metadata** — Jobs include `active_job_class`, `executions`, and `locale` in OJS meta.
- Comprehensive test suite for all new features.

### Changed
- Gemspec now depends on `railties` and `activejob` (>= 7.0) instead of full `rails` gem.
- Railtie loads configuration from multiple sources with clear priority ordering.
- ActiveJob adapter uses configuration for queue resolution and priority mapping.
- README updated with full documentation, migration guides from Sidekiq and GoodJob.
- Status upgraded from **Alpha** to **Beta**.

### Removed
- `lib/ojs/rails/active_job_adapter.rb` — Replaced by `lib/ojs/rails/active_job/adapter.rb`.
- `lib/ojs/rails/generator.rb` — Generator autoloading now handled by the Railtie.

## [0.1.0] - 2025-06-01

### Added
- Initial alpha release.
- Basic ActiveJob adapter (enqueue, enqueue_at).
- Railtie with simple URL configuration.
- Transactional `after_commit` enqueue via `OJS::Rails::Enqueue`.
- Install and job generators.
