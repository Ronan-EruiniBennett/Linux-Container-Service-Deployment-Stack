#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/config.sh
source "$SCRIPT_DIR/config.sh"

### INGRESS TESTS ###
# IP link to check container brigde exists at data link layer
# IP addr to check container bridge has an ip address
# IP route to check container bridge has a default route
# ss -tulpen to check listening ports



### EGRESS TESTS ###
# Vm connectivity test ping
# Vm dns test ping google.com
# Container connectivity test ping
# Container dns test ping google.com
# Container exec ip route to check default route exists
# Container exec ip addr to check container has an ip address

