# OJS Rails Example

A complete Rails application demonstrating OJS integration with ActiveJob.

## Prerequisites

- Docker and Docker Compose
- Ruby >= 3.2

## Quick Start

```bash
# Start OJS backend
docker compose up -d

# Install dependencies
bundle install

# Run the example
bin/rails server
```

## Enqueue a Job

```bash
curl -X POST http://localhost:3000/jobs \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "template": "welcome"}'
```

## Architecture

- `config/initializers/ojs.rb` — Configures OJS URL and sets the ActiveJob adapter
- `app/jobs/email_job.rb` — ActiveJob class backed by OJS
- `app/controllers/jobs_controller.rb` — API endpoint to trigger jobs
