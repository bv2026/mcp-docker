#!/usr/bin/env bash
set -e

echo "Creating host data directories..."
sudo mkdir -p \
  /data/smartspreads/published \
  /data/schwab/config \
  /data/bullstrangle/data/newsletters \
  /data/bullstrangle/data/os_uploads \
  /data/bullstrangle/outputs/workbooks

sudo chown -R "$USER:$USER" /data

echo "Done. Layout:"
find /data -type d | sort
echo ""

UBUNTU_IP=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | head -1)
echo "=== Run these from Windows PowerShell (Ubuntu IP: $UBUNTU_IP) ==="
echo ""
echo "# smartspreads-mcp"
echo "scp C:\\work\\SmartSpreads\\newsletters.db            ${USER}@${UBUNTU_IP}:/data/smartspreads/"
echo "scp -r C:\\work\\SmartSpreads\\data\\*               ${USER}@${UBUNTU_IP}:/data/smartspreads/"
echo "scp -r C:\\work\\SmartSpreads\\published\\*          ${USER}@${UBUNTU_IP}:/data/smartspreads/published/"
echo ""
echo "# schwab-smartspreads-file"
echo "scp C:\\work\\schwab-mcp-file\\config\\smartspreads.db    ${USER}@${UBUNTU_IP}:/data/schwab/config/"
echo "scp C:\\work\\schwab-mcp-file\\config\\tos-statement.csv  ${USER}@${UBUNTU_IP}:/data/schwab/config/"
echo "scp C:\\work\\schwab-mcp-file\\config\\positions.yaml     ${USER}@${UBUNTU_IP}:/data/schwab/config/"
echo "scp C:\\work\\schwab-mcp-file\\config\\watchlist.yaml     ${USER}@${UBUNTU_IP}:/data/schwab/config/"
echo "scp C:\\Users\\vsbra\\.schwab\\token.json                 ${USER}@${UBUNTU_IP}:/data/schwab/config/"
echo ""
echo "# bullstrangle-mcp"
echo "scp -r C:\\work\\bullstrangle\\newsletters\\*         ${USER}@${UBUNTU_IP}:/data/bullstrangle/data/newsletters/"
echo "scp C:\\work\\bullstrangle\\bullstrangle.db           ${USER}@${UBUNTU_IP}:/data/bullstrangle/data/"
