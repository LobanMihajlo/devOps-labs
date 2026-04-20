# Lab 1 - Web Service Deployment with Automation

## 1. Individual Task Variant

`N = 19`

- `V2 = (N % 2) + 1 = (19 % 2) + 1 = 2`
- `V3 = (N % 3) + 1 = (19 % 3) + 1 = 2`
- `V5 = (N % 5) + 1 = (19 % 5) + 1 = 5`

Selected variant:

- App type (`V3=2`): Task Tracker
- Configuration mode (`V2=2`): config file `/etc/mywebapp/config.json`
- DB (`V2=2`): PostgreSQL
- App port (`V5=5`): 5000

## 2. Application Documentation

### 2.1 Purpose

`mywebapp` is a Task Tracker service.
It stores tasks and supports task creation, listing, and marking tasks as done.

Task model fields:

- `id`
- `title`
- `status`
- `created_at`

### 2.2 Development / Test / Run Environment

Minimum requirements for local development:

- Linux
- Node.js + npm
- PostgreSQL

Project location:

- App source: `lab1/mywebapp/src`
- Migration script: `lab1/mywebapp/src/migrations/migrate.js`
- Entry script for full deployment: `lab1/mywebapp/setup.sh`

### 2.3 How to Run the Application

Full automated deployment (recommended):

```bash
cd lab1/mywebapp
chmod +x setup.sh
./setup.sh
```

What this does:

1. Installs required packages
2. Creates users
3. Creates DB and app config
4. Copies app to `/opt/mywebapp`
5. Installs Node.js dependencies
6. Creates systemd socket/service units
7. Configures nginx reverse proxy

After deployment, access app via nginx:

```bash
curl -i http://127.0.0.1/
```

### 2.4 API Endpoints

Business endpoints:

1. `GET /tasks`
- Returns all tasks (`id, title, status, created_at`)
- Supports `Accept: application/json` and `Accept: text/html`

2. `POST /tasks`
- Creates a new task
- Request body (JSON):

```json
{ "title": "Buy milk" }
```

- Supports `Accept: application/json` and `Accept: text/html`

3. `POST /tasks/:id/done`
- Marks task status as `done`
- Supports `Accept: application/json` and `Accept: text/html`

Health endpoints:

1. `GET /health/alive` -> `200 OK` with `OK`
2. `GET /health/ready` -> `200 OK` when DB reachable, otherwise `500`

Root endpoint:

1. `GET /` -> HTML page with business endpoint list

## 3. Deployment Documentation

### 3.1 Base VM Image

Use an official Linux distribution image.

Recommended:

- Ubuntu Server 24.04 LTS (official image)
- Download page: https://ubuntu.com/download/server
- Cloud images: https://cloud-images.ubuntu.com/

### 3.2 VM Resources

Minimum tested resources:

- CPU: 1 vCPU
- RAM: 1 GB
- Disk: 10 GB

### 3.3 Special OS Install Settings

No special disk layout is required.
Default installation profile is sufficient.

### 3.4 How to Log In to VM and Credentials

Initial login is done with default credentials/user provided by the selected official image.

Typical connection (replace placeholders):

```bash
ssh <default_user>@<VM_IP>
```

OpenSSH reference: https://ubuntu.com/server/docs/openssh-server

```bash
hostname -I
```

Use VM_IP for checks from another machine (host laptop/PC) to simulate real user traffic through nginx.
Use `127.0.0.1` for internal checks executed inside the VM.

After running automation, these users are created:

1. `student` (sudo) - default password `12345678`, password change forced at first login
2. `teacher` (sudo) - default password `12345678`, password change forced at first login
3. `operator` (restricted sudo for service/nginx ops) - default password `12345678`, password change forced at first login
4. `app` (system account for service runtime)

Automation also creates:

- `/home/student/gradebook` containing only `N`

### 3.5 How to Download and Run Automation

```bash
git clone https://github.com/LobanMihajlo/devOps-labs.git
cd devOps-labs/lab1/mywebapp
chmod +x setup.sh
./setup.sh
```

If `git` is missing:

```bash
sudo apt update
sudo apt install -y git
```

## 4. Deployed System Testing Instructions

Run checks after `./setup.sh` completes.

### 4.1 Set test targets

From another machine (external simulation), set only VM IP:

```bash
VM_IP=<your_vm_ip>
```

### 4.2 Service state checks

```bash
sudo systemctl is-enabled mywebapp.socket nginx
sudo systemctl is-active mywebapp.socket nginx
sudo systemctl status mywebapp.service --no-pager
```

Expected:

- `mywebapp.socket` and `nginx` are enabled and active.
- `mywebapp.service` becomes active after first request (socket activation).

### 4.3 User and access checks

```bash
id student
id teacher
id operator
id app
sudo -l -U operator
```

Expected:

- `student` and `teacher` are in `sudo` group.
- `operator` can only run allowed service/nginx commands from `/etc/sudoers.d/operator`.

### 4.4 Endpoint functional checks (through nginx)

1. Root endpoint (HTML):

```bash
curl -i -H 'Accept: text/html' http://127.0.0.1/
```

2. Create task (JSON):

```bash
curl -i -X POST http://127.0.0.1/tasks \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{"title":"Task 1"}'
```

3. List tasks (JSON + HTML):

```bash
curl -i -H 'Accept: application/json' http://127.0.0.1/tasks
curl -i -H 'Accept: text/html' http://127.0.0.1/tasks
```

4. Mark task as done:

```bash
curl -i -X POST -H 'Accept: application/json' http://127.0.0.1/tasks/1/done
```

Expected:

- Business endpoints respond with `200/201`.
- JSON response contains `created_at` in snake_case.

### 4.5 Health endpoint exposure checks

Internal app checks (inside VM):

```bash
curl -i http://127.0.0.1:5000/health/alive
curl -i http://127.0.0.1:5000/health/ready
```

Expected: `200 OK` for alive, `200/500` for ready depending on DB availability.

Nginx external path check:

```bash
curl -i http://127.0.0.1/health/alive
```

Expected: `404` (health is not exposed by nginx).

### 4.6 External traffic simulation (VM_IP)

Run from host machine or another VM:

```bash
curl -i http://$VM_IP/
curl -i -H 'Accept: application/json' http://$VM_IP/tasks
curl -i http://$VM_IP/health/alive
```

Expected:

- `/` and `/tasks` are reachable via nginx.
- `/health/alive` returns `404` externally.

### 4.7 Gradebook check

```bash
cat /home/student/gradebook
```

Expected: file exists and contains only `19`.
