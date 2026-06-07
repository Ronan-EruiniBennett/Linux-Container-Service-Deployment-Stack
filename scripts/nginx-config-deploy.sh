#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/config.sh
source "$SCRIPT_DIR/config.sh"

PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

echo "Updating Nginx configuration for the project..."

sudo rm -f /etc/nginx/sites-enabled/default

sudo cp "$PROJECT_DIR/config/nginx/server-demo.conf" /etc/nginx/sites-available/server-demo.conf
sudo ln -s /etc/nginx/sites-available/server-demo.conf /etc/nginx/sites-enabled/server-demo.conf

sleep 1

echo "Nginx configuration updated. Testing configuration..."
sudo nginx -t

echo "Nginx configuration is valid. Reloading Nginx..."
sudo systemctl reload nginx
sleep 1
echo "Nginx has been reloaded with the new configuration."