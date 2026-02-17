# OJS Sidekiq Migration Example

Side-by-side comparison of a Sidekiq app before and after migrating to OJS.

## Prerequisites

- Docker and Docker Compose
- Ruby >= 3.2

## Quick Start

```bash
# Start OJS backend
docker compose up -d

# Install dependencies
bundle install

# Compare the code
diff before_sidekiq.rb after_ojs.rb

# Run the OJS version
ruby after_ojs.rb

# In another terminal, start the worker
ruby worker.rb
```

## Files

- `before_sidekiq.rb` — Original Sidekiq code (for reference)
- `after_ojs.rb` — Same app using OJS via the Sidekiq adapter
- `worker.rb` — OJS worker that processes jobs
