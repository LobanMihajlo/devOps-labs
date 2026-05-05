# Lab 2 — Docker Compose Deployment

This lab packages the Task Tracker application into three services managed by Docker Compose: a PostgreSQL database, the Node.js application, and an Nginx reverse proxy.

PDF report: [lab2/lab2_Loban_report.pdf](lab2/lab2_Loban_report.pdf)

## 1. Dockerfile and `docker-compose.yml`

### `lab2/mywebapp/Dockerfile`

The application image is built from `lab2/mywebapp/Dockerfile`.

- Base image: `node:20-alpine`
- Working directory: `/usr/src/app`
- Dependencies: `package.json` and `package-lock.json` are copied first, then `npm ci --omit=dev` installs production dependencies reproducibly
- Configuration: `config/config.json` is copied into `/etc/mywebapp/config.json` so the app keeps the same config path it used in Lab 1
- Application source: `src` is copied into the image
- Default command: `node src/app.js`

This image is intentionally simple: it keeps the Lab 1 configuration path unchanged, installs only production dependencies, and starts the application directly inside the container.

### `lab2/docker-compose.yml`

The Compose file defines the whole stack and its runtime behavior.

- `db`
   - Uses `postgres:16-alpine`
   - Sets `POSTGRES_DB=mywebappdb`, `POSTGRES_USER=mywebapp`, and `POSTGRES_PASSWORD=mywebapp`
   - Persists data in `./pgdata:/var/lib/postgresql/data`
   - Uses a healthcheck based on `pg_isready`
   - Joins the custom `mywebapp-net` bridge network

- `app`
   - Builds from `./mywebapp`
   - Starts with `node src/migrations/migrate.js && node src/app.js`
   - Waits for the database to become healthy before starting
   - Joins the same custom network so it can resolve `db` by service name

- `nginx`
   - Uses the official `nginx:alpine` image
   - Mounts `./nginx/default.conf` into the container
   - Proxies requests from port `80` to `app:5000`
   - Starts after the application service

The `mywebapp-net` network is a user-defined bridge network, so the stack does not use Docker's default network.

## 2. How the lab requirements are satisfied

- Three services are running together: the database, the application, and Nginx.
- The services are isolated in a separate Docker network: `mywebapp-net`.
- The database keeps its data between restarts because the PostgreSQL data directory is mounted on the host.
- The application preserves the Lab 1 config path by reading `/etc/mywebapp/config.json`.
- Database migrations are executed automatically when the application container starts.
- Nginx is used as a reverse proxy, so the application is exposed through a clean public entry point.
- Service startup is ordered so that the application waits for the database, and Nginx waits for the application.

## 3. Test

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