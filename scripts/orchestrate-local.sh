#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting local orchestration of the project..."

"$SCRIPT_DIR/stop-container.sh"
"$SCRIPT_DIR/image-build.sh"
"$SCRIPT_DIR/nginx-config-deploy.sh"
"$SCRIPT_DIR/container-run.sh"
"$SCRIPT_DIR/vm-network-test.sh"
"$SCRIPT_DIR/local-smoke-test.sh"

echo "Local orchestration completed successfully!"