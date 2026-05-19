#!/usr/bin/env bash
# Verify all three SSE endpoints and print Windows Claude Code config

UBUNTU_IP=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | head -1)

echo "=== MCP SSE Endpoint Health Check ==="
echo "Ubuntu LAN IP: $UBUNTU_IP"
echo ""

test_sse() {
  local name=$1
  local port=$2
  echo -n "  [$name] :$port/sse  → "
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:$port/sse")
  if [ "$HTTP_CODE" = "200" ]; then
    echo "OK"
  else
    echo "FAIL (HTTP $HTTP_CODE)"
    echo "    → docker compose logs $name | tail -30"
  fi
}

test_sse "smartspreads-mcp"         3001
test_sse "schwab-smartspreads-file" 3002
test_sse "bullstrangle-mcp"         3003

echo ""
echo "=== Paste this into Windows .claude/settings.json ==="
cat <<EOF
{
  "mcpServers": {
    "smartspreads-mcp": {
      "type": "sse",
      "url": "http://$UBUNTU_IP:3001/sse"
    },
    "schwab-smartspreads-file": {
      "type": "sse",
      "url": "http://$UBUNTU_IP:3002/sse"
    },
    "bullstrangle-mcp": {
      "type": "sse",
      "url": "http://$UBUNTU_IP:3003/sse"
    }
  }
}
EOF

echo ""
echo "=== Container status ==="
docker compose ps
