#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/config.sh
source "$SCRIPT_DIR/config.sh"

echo "Starting Container..."

sleep 0.5

echo "Container being created with name $NAME and on port $HOST_PORT"

sleep 0.5

echo "Container ID:"
sudo docker run -d --name "$NAME" -p 127.0.0.1:"${HOST_PORT}":"${CONTAINER_PORT}" -t "$TAG"

if sudo docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
	echo "Container running"
else
	echo "Container is not running"
fi
