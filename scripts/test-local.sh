#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/config.sh
source "$SCRIPT_DIR/config.sh"

if [[ "$(docker inspect -f '{{.State.Running}}' $NAME 2>/dev/null)" == "true" ]]; then
    echo "PASS: Container $NAME is running"
else
    echo "FAIL: Container $NAME is not running"
    exit 1
fi

sleep 2

echo "Checking Docker port mapping..."
docker port "$CONTAINER_NAME" "$CONTAINER_PORT" | grep -q "$HOST_PORT"
echo "PASS: Container port $CONTAINER_PORT is mapped to host port $HOST_PORT"

sleep 2

echo "Checking Nginx config..."
sudo nginx -t
echo "PASS: Nginx config is valid"

sleep 2

echo "Checking Nginx service..."
sudo systemctl is-active --quiet nginx
echo "PASS: Nginx is active"

echo "Would you like to test the api endpoints? (y/n)"
read -r TEST

ENDPOINTS=(
    "/"
    "/health"
    "/version"
    "/metrics"
)

while [ "$TEST" == "y" ]; do
    for endpoint in "${ENDPOINTS[@]}"; do
        echo "Testing endpoint: $endpoint"
        curl -i "$VM_IP:${HOST_PORT}${endpoint}"
        sleep 0.5
    done
	echo "Would you like to test the endpoints again? (y/n)"
	read -r TEST
done