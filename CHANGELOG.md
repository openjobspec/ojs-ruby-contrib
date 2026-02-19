# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] - 2026-02-20

Release candidate for v1.0.

### Changed

- Bumped all gem versions to 0.9.0
- Stabilized `ojs-rails` gem: ActiveJob adapter, Railtie auto-config, `after_commit` enqueue
- Stabilized `ojs-sinatra` gem: Sinatra extension with helper methods
- Stabilized `ojs-sidekiq` gem: Sidekiq-compatible `perform_async` API for migration

### Added

- Initial `ojs-rails` gem: ActiveJob adapter, Railtie auto-config, `after_commit` enqueue
- Initial `ojs-sinatra` gem: Sinatra extension with helper methods
- Initial `ojs-sidekiq` gem: Sidekiq-compatible `perform_async` API for migration
- Expanded test coverage for `ojs-sinatra` and `ojs-sidekiq`
