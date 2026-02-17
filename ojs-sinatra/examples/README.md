# OJS Sinatra Example

A minimal Sinatra application demonstrating OJS integration.

## Prerequisites

- Docker and Docker Compose
- Ruby >= 3.2

## Quick Start

```bash
# Start OJS backend
docker compose up -d

# Install dependencies
bundle install

# Run the app
ruby app.rb

# In another terminal, start the worker
ruby worker.rb
```

## Enqueue a Job

```bash
curl -X POST http://localhost:4567/enqueue \
  -H "Content-Type: application/json" \
  -d '{"type": "email.send", "args": ["user@example.com", "welcome"]}'
```
