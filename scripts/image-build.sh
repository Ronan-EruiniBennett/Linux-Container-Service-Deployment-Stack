#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/config.sh
source "$SCRIPT_DIR/config.sh"

cd "$SCRIPT_DIR/.."

if sudo docker build -t $TAG . ;
    then
        echo "Docker image built successfully with tag $TAG"
    else
        echo "Failed to build Docker image with tag $TAG"
fi