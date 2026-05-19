# MCP Server Docker Host — Ubuntu Setup Guide

## Step 1: Install Docker Engine on Ubuntu 24.04

Run these commands **in order** on your Ubuntu machine:

```bash
# 1. Remove old/conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg 2>/dev/null || true
done

# 2. Add Docker's official GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 3. Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Install Docker Engine + Compose plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Let your user run Docker without sudo
sudo usermod -aG docker $USER
newgrp docker   # apply group in current shell

# 6. Verify
docker version
docker compose version
docker run --rm hello-world
```

Expected output for `docker compose version`: `Docker Compose version v2.x.x`

---

## Step 2: Understand the stdio → SSE Bridge Strategy

Your Windows MCP servers use **stdio** transport (Claude Code forks the process and talks via stdin/stdout).
Docker containers need **SSE** or **HTTP** transport so remote clients can reach them over the network.

We use **supergateway** — a zero-code-change bridge that wraps any stdio MCP server as an SSE server:

```
Windows Claude Code  ─── HTTP/SSE ───►  Ubuntu Docker
                                         └─ supergateway
                                              └─ node server.js  (your stdio MCP)
```

No changes to your existing server code required.

---

## Step 3: Transfer Your MCP Server Code to Ubuntu

From Windows, copy each server folder to Ubuntu. Options:

**Option A — SCP from Windows (in PowerShell):**
```powershell
scp -r C:\work\smartspreads-mcp bvajjala@<ubuntu-ip>:~/mywork/mcp-docker/smartspreads-mcp/app
scp -r C:\work\schwab-smartspreads-file bvajjala@<ubuntu-ip>:~/mywork/mcp-docker/schwab-smartspreads-file/app
scp -r C:\work\bullstrangle-mcp bvajjala@<ubuntu-ip>:~/mywork/mcp-docker/bullstrangle-mcp/app
```

**Option B — Git (if repos are in git):**
```bash
cd ~/mywork/mcp-docker/smartspreads-mcp
git clone <your-repo-url> app
```

**Option C — SMB/network share** via your existing `home-share` mount.

---

## Step 4: Data Volumes

Map your Windows data paths to Ubuntu:

| Windows Path                        | Ubuntu Path                              | Mount in Container     |
|-------------------------------------|------------------------------------------|------------------------|
| `C:\work\SmartSpreads\*.db`         | `/data/smartspreads/`                    | `/app/data`            |
| `C:\work\schwab\files\`             | `/data/schwab/`                          | `/app/data`            |
| `C:\work\newsletters\`              | `/data/newsletters/`                     | `/app/newsletters`     |

Create the directories:
```bash
sudo mkdir -p /data/smartspreads /data/schwab /data/newsletters
sudo chown -R $USER:$USER /data/
```

Copy your SQLite databases from Windows:
```bash
# From Windows PowerShell:
scp C:\work\SmartSpreads\spreads.db bvajjala@<ubuntu-ip>:/data/smartspreads/
```

---

## Step 5: Build and Start

```bash
cd ~/mywork/mcp-docker
docker compose up -d --build

# Check logs
docker compose logs -f

# Check individual service
docker compose logs smartspreads-mcp
```

---

## Step 6: Test SSE Endpoints

From Ubuntu (local test):
```bash
# Should return SSE stream headers
curl -N http://localhost:3001/sse

# List available tools (MCP initialize)
curl -X POST http://localhost:3001/message \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```

From your Windows PC (replace `192.168.x.x` with Ubuntu's actual IP):
```powershell
curl http://192.168.x.x:3001/sse
```

---

## Step 6b: Schwab OAuth Token (copy from Windows — no re-auth needed)

The server uses `SCHWAB_TOKEN_PATH=/app/config/token.json` (file-based, no keyring).
Copy your existing token from Windows before starting the container:

```powershell
# From Windows PowerShell:
scp C:\Users\vsbra\.schwab\token.json bvajjala@<ubuntu-ip>:/data/schwab/config/
```

The token auto-refreshes while the server is running. If it ever expires (e.g. container
was down for weeks), re-run auth interactively:

```bash
docker compose run --rm -it schwab-smartspreads-file schwab-auth
```

---

## Step 7: Configure Claude Code on Windows

Add to your Windows Claude Code config (`%APPDATA%\Claude\claude_desktop_config.json` or `.claude/settings.json`):

```json
{
  "mcpServers": {
    "smartspreads-mcp": {
      "type": "sse",
      "url": "http://192.168.x.x:3001/sse"
    },
    "schwab-smartspreads-file": {
      "type": "sse",
      "url": "http://192.168.x.x:3002/sse"
    },
    "bullstrangle-mcp": {
      "type": "sse",
      "url": "http://192.168.x.x:3003/sse"
    }
  }
}
```

---

## Useful Commands

```bash
# Start all
docker compose up -d

# Stop all
docker compose down

# Rebuild after code changes
docker compose up -d --build smartspreads-mcp

# View running containers
docker compose ps

# Enter a container for debugging
docker compose exec smartspreads-mcp sh

# View real-time logs
docker compose logs -f smartspreads-mcp

# Check Ubuntu's LAN IP
ip addr show | grep "inet " | grep -v 127.0.0.1
```
