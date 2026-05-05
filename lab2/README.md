# Lab 2 - Docker Compose Deployment

Runs the Task Tracker app (3 services) with Docker Compose on a custom bridge network.

## Run

From `lab2`:

```bash
docker compose up --build
```

## How it works

**Services:**

1. **db** — PostgreSQL 16 (Alpine)
   - Database: `mywebappdb`, user: `mywebapp`, password: `mywebapp`
   - Healthcheck: verifies DB is ready before app starts
   - Data stored in `./pgdata` (persists across restarts)

2. **app** — Node.js Task Tracker
   - Builds from `./mywebapp/Dockerfile`
   - Runs migrations, then starts the app on port 5000
   - Waits for DB healthcheck to pass before starting
   - Reads config from `/etc/mywebapp/config.json`

3. **nginx** — Nginx reverse proxy
   - Image: `nginx:alpine`
   - Config mounted from `./nginx/default.conf`
   - Routes traffic from port 80 to app:5000
   - Starts after app (`depends_on`)

**Network:** Custom bridge `mywebapp-net` isolates these services from Docker's default network.

## Persistence

PostgreSQL data is bind-mounted to `./pgdata`, so it survives container removal, Docker restarts, and machine reboots.

## Test

```bash
# 1. Check if services are running
docker compose ps

# 2. Health check (DB)
curl http://127.0.0.1/health/alive
curl http://127.0.0.1/health/ready

# 3. Get root page (HTML)
curl http://127.0.0.1/

# 4. List tasks (should be empty at first)
curl -i http://127.0.0.1/tasks

# 5. Create a task (JSON)
curl -X POST http://127.0.0.1/tasks \
  -H 'Content-Type: application/json' \
  -d '{"title":"Buy milk"}'

# 6. Create another task
curl -X POST http://127.0.0.1/tasks \
  -H 'Content-Type: application/json' \
  -d '{"title":"Write docs"}'

# 7. Mark first task as done
curl -X POST http://127.0.0.1/tasks/1/done

# 8. List tasks again (should show 2)
curl -i http://127.0.0.1/tasks

```