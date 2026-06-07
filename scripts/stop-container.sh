#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/config.sh
source "$SCRIPT_DIR/config.sh"

echo "Stopping and removing container with name $NAME if it exists..."
if sudo docker ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
    echo "Container $NAME exists. Stopping and removing it..."
    sudo docker stop "$NAME"
    sudo docker rm "$NAME"
    echo "Container $NAME has been stopped and removed."
else
    echo "Container $NAME does not exist. No action needed."
fi