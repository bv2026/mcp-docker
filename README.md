# mcp-docker

Runs multiple MCP servers in Docker containers on an Ubuntu host, exposing them as SSE endpoints accessible from Claude Desktop on any machine on the local network.

**Architecture**
- Legacy MCPs (3 servers) — each on a dedicated port, built from private GitHub repos
- New MCPs — routed by Traefik on port 80, no port allocation needed
- All servers use [mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) to bridge stdio → SSE

---

## Running Servers

| Container | Port | Claude Desktop URL |
|-----------|------|--------------------|
| smartspreads-mcp | 3001 | `http://<host-ip>:3001/sse` |
| schwab-smartspreads-file | 3002 | `http://<host-ip>:3002/sse` |
| bullstrangle-mcp | 3003 | `http://<host-ip>:3003/sse` |
| traefik (dashboard) | 8080 | `http://<host-ip>:8080` |
| new MCPs (via Traefik) | 80 | `http://<host-ip>/<mcp-name>/sse` |

---

## Prerequisites

- Ubuntu 22.04 / 24.04 desktop
- Sudo access
- GitHub Personal Access Token (PAT) with `repo` scope

---

## 1. Install Docker CE

```bash
chmod +x install-docker.sh
./install-docker.sh
```

Log out and back in after installation so your user is in the `docker` group.

> **Ubuntu 24.04 note:** If `docker` commands fail, check that `~/.bashrc` does not contain `alias docker=podman`. Comment it out if present.

---

## 2. Create Data Directories

```bash
chmod +x bootstrap-data-dirs.sh
sudo ./bootstrap-data-dirs.sh
```

This creates the host directories that containers bind-mount for persistent data:

```
/data/smartspreads/        ← newsletter data + SQLite DB
/data/schwab/config/       ← Schwab OAuth token, DB, config files
/data/bullstrangle/        ← bullstrangle data + DB
```

---

## 3. Copy Config Files from Windows

On your Windows PC, edit and run `copy-to-ubuntu.ps1` to SCP your existing config files to the Ubuntu host:

```
C:\work\SmartSpreads\           → /data/smartspreads/
C:\work\schwab-mcp-file\config\ → /data/schwab/config/
```

Or copy manually using `scp`:

```bash
scp -r "C:\work\schwab-mcp-file\config\*" user@<host-ip>:/data/schwab/config/
```

---

## 4. Configure Schwab Credentials

The schwab credentials are stored inline in `docker-compose.yml` under the `schwab-smartspreads-file` service `environment:` block. Edit that section with your Schwab API key and secret before building.

---

## 5. Set GitHub Token

All three MCP repos are private. Docker needs your PAT to clone them at build time.

Add to `~/.bashrc` (one-time):

```bash
export GITHUB_TOKEN=ghp_your_token_here
```

Then reload:

```bash
source ~/.bashrc
```

The token is passed as a Docker build secret — it is **never stored in the image layers**.

---

## 6. Build and Start

```bash
cd /path/to/mcp-docker

# Build all images
docker compose build

# Start all containers
docker compose up -d

# Check status
docker compose ps

# View logs for a specific container
docker compose logs -f schwab-smartspreads-file
```

---

## 7. Configure Claude Desktop (Windows)

Edit `%APPDATA%\Claude\claude_desktop_config.json` and add (or replace) the MCP entries:

```json
{
  "mcpServers": {
    "smartspreads-mcp": {
      "url": "http://192.168.1.167:3001/sse"
    },
    "schwab-smartspreads-file": {
      "url": "http://192.168.1.167:3002/sse"
    },
    "bullstrangle-mcp": {
      "url": "http://192.168.1.167:3003/sse"
    }
  }
}
```

Replace `192.168.1.167` with your Ubuntu host's IP. Restart Claude Desktop after saving.

---

## 8. Adding a New MCP (Traefik routing)

New MCPs are routed by Traefik on port 80 — no port allocation needed.

**Step 1 — Create the folder and Dockerfile**

Copy `_template/Dockerfile` to a new folder and update the repo URL and server module:

```
mcp-docker/
└── my-new-mcp/
    └── Dockerfile
```

Use port `3000` inside the container (all new MCPs share the same internal port — Traefik handles the routing).

**Step 2 — Add the service to `docker-compose.yml`**

```yaml
my-new-mcp:
  build:
    context: ./my-new-mcp
    dockerfile: Dockerfile
    secrets:
      - github_token
  container_name: my-new-mcp
  restart: unless-stopped
  # No ports: — Traefik handles routing
  volumes:
    - /data/my-new-mcp:/data/my-new-mcp
  environment:
    - MY_VAR=value
  networks:
    - mcp-net
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.my-new-mcp.rule=PathPrefix(`/my-new-mcp`)"
    - "traefik.http.routers.my-new-mcp.middlewares=my-new-mcp-strip"
    - "traefik.http.middlewares.my-new-mcp-strip.stripprefix.prefixes=/my-new-mcp"
    - "traefik.http.services.my-new-mcp.loadbalancer.server.port=3000"
  healthcheck:
    test: ["CMD", "python3", "-c", "import socket; s=socket.create_connection(('localhost',3000),3); s.close()"]
    interval: 30s
    timeout: 5s
    retries: 3
    start_period: 15s
```

**Step 3 — Build and start**

```bash
docker compose build my-new-mcp
docker compose up -d my-new-mcp
```

**Step 4 — Add to Claude Desktop**

```json
"my-new-mcp": {
  "url": "http://192.168.1.167/my-new-mcp/sse"
}
```

---

## Useful Commands

```bash
# Restart a single container
docker compose restart schwab-smartspreads-file

# Rebuild and restart one container after code changes
docker compose build --no-cache schwab-smartspreads-file
docker compose up -d schwab-smartspreads-file

# Stop everything
docker compose down

# Traefik dashboard (shows all active routes)
open http://192.168.1.167:8080
```

---

## File Structure

```
mcp-docker/
├── docker-compose.yml              # All services
├── _template/                      # Copy this for new MCPs
│   ├── Dockerfile
│   └── .env.example
├── smartspreads-mcp/
│   └── Dockerfile
├── schwab-smartspreads-file/
│   ├── Dockerfile
│   └── .env.example
├── bullstrangle-mcp/
│   └── Dockerfile
├── install-docker.sh               # Docker CE installer
├── bootstrap-data-dirs.sh          # Creates /data/* directories
├── copy-to-ubuntu.ps1              # Windows → Ubuntu file transfer
└── test-endpoints.sh               # Smoke-test all SSE endpoints
```
