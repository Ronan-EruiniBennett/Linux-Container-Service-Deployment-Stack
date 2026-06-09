#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/config.sh
source "$SCRIPT_DIR/config.sh"

### HOST DOCKER NETWORK STATE ###

echo "== Host Docker network state =="

# Check if the docker0 interface exists.
echo "[1] Checking data link layer state of docker0 interface:"
if ip link show docker0 >/dev/null 2>&1; then
    echo "PASS: docker0 interface exists"
else
    echo "FAIL: docker0 interface does not exist"
    echo "Meaning: Docker may not be running, bridge networking may be disabled, or Docker may be misconfigured."
    exit 1
fi

# Check if the docker0 interface has an IPv4 address assigned.
echo "[2] Checking IPv4 address of docker0 interface:"
if ip -4 addr show docker0 2>/dev/null | grep -q "inet "; then
    echo "PASS: docker0 interface has an IPv4 address"
    ip -4 addr show docker0
else
    echo "FAIL: docker0 interface does not have an IPv4 address"
    echo "Meaning: docker0 exists at Layer 2, but may not have a usable Layer 3 subnet."
    exit 1
fi

# Check if the VM host has a route to the Docker bridge subnet via docker0.
echo "[3] Checking VM host route to the Docker bridge subnet via docker0:"
if ip route show dev docker0 2>/dev/null | grep -q .; then
    echo "PASS: VM host has a route to the Docker bridge subnet via docker0"
    ip route show dev docker0
else
    echo "FAIL: VM host does not have a route to the Docker bridge subnet via docker0"
    echo "Meaning: docker0 may exist, but the VM host may not know how to route traffic to containers on the Docker bridge subnet."
    exit 1
fi


### CONTAINER NETWORK STATE ###

echo "== Container network state =="

# Check if the container exists and is running.
echo "[1] Checking container exists:"
if sudo docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
    echo "PASS: Container '$NAME' is running"
else
    echo "FAIL: Container '$NAME' is not running"
    echo "Meaning: The container may not have started successfully, or may have exited due to an error."
    exit 1
fi

# Check if the container has any port mappings.
echo "[2] Checking container port mapping:"
if sudo docker port "$NAME" 2>/dev/null | grep -q .; then
    echo "PASS: Container '$NAME' has port mappings"
    sudo docker port "$NAME"
else
    echo "FAIL: Container '$NAME' does not have any port mappings"
    echo "Meaning: The container may be running, but may not be accessible from the host or Nginx due to missing port mappings."
    exit 1
fi

# Check if the container is connected to a network and has an IP address.
echo "[3] Checking container networks and IP addresses:"
if sudo docker inspect "$NAME" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | grep -q .; then
    echo "PASS: Container '$NAME' is connected to a network and has an IP address"
    sudo docker inspect "$NAME" --format '{{range $network, $config := .NetworkSettings.Networks}}Network={{$network}}{{println}}Gateway={{$config.Gateway}}{{println}}IP={{$config.IPAddress}}{{println}}MAC={{$config.MacAddress}}{{println}}{{end}}'
else
    echo "FAIL: Container '$NAME' is not connected to any network or does not have an IP address"
    echo "Meaning: The container may not be attached to a Docker network, or Docker network assignment failed."
    exit 1
fi


### EGRESS TESTS ###

echo "== Egress connectivity tests =="


# Check if the VM can reach the public internet by IP. We use Cloudflare's DNS resolver
echo "[1] Checking VM egress connectivity to the public internet by IP:"
if ping -c 3 1.1.1.1 >/dev/null 2>&1; then
    echo "PASS: VM can reach the public internet by IP"
else
    echo "FAIL: VM cannot reach the public internet by IP"
    echo "Meaning: The VM may not have a default route to the internet, or may be blocked by firewall rules."
    exit 1
fi

# Check if the VM can resolve DNS names. We test this separately from general IP connectivity to distinguish between general network issues and DNS-specific issues.
echo "[2] Checking VM DNS resolution:"
if getent hosts 'google.com' >/dev/null 2>&1; then
    echo "PASS: VM can resolve DNS names"
else
    echo "FAIL: VM cannot resolve DNS names"
    echo "Meaning: The VM may have general network connectivity issues, or may be misconfigured to use an incorrect DNS server, or DNS traffic may be blocked by firewall rules."
    exit 1
fi

# We use Python to open a TCP connection to a stable public IP (Cloudflare) on port 443.
echo "[3] Checking container egress connectivity to the public internet via TCP by IP:"
if sudo docker exec "$NAME" python3 -c "import socket; socket.create_connection(('1.1.1.1', 443),timeout=5).close()" >/dev/null 2>&1; then
    echo "PASS: Container can reach the public internet by IP"
else
    echo "FAIL: Container cannot reach the public internet by IP"
    echo "Meaning: The container may not have a default route to the internet, or may be blocked by firewall rules."
    exit 1
fi

# Check if the container can resolve DNS names. We test this separately from general IP connectivity to distinguish between general network issues and DNS-specific issues.
echo "[4] Checking container DNS resolution:"
if sudo docker exec "$NAME" python3 -c "import socket; socket.gethostbyname('google.com')" >/dev/null 2>&1; then
    echo "PASS: Container can resolve DNS names"
else
    echo "FAIL: Container cannot resolve DNS names"
    echo "Meaning: The container may have network connectivity but may be misconfigured to use an incorrect DNS server, or DNS traffic may be blocked by firewall rules."
    exit 1
fi

### INGRESS / SERVICE PATH TESTS ###
# Confirms the VM has expected listening ports.
# Then tests the backend directly and through Nginx to distinguish app/container faults from reverse-proxy faults.

echo "== Ingress / service path tests =="

echo "[1] Checking if Nginx is listening on port 80 on all IPv4 interfaces:"
if sudo ss -tulpen 2>/dev/null | grep -F '0.0.0.0:80' | grep -q 'nginx'; then
    echo "PASS: Nginx is listening on port 80 on all IPv4 interfaces"
else
    echo "FAIL: Nginx is not listening on port 80"
    echo "Meaning: Nginx may not be running, or may be misconfigured and failed to start."
    exit 1
fi

echo "[2] Checking if container port $CONTAINER_PORT is exposed on host port $HOST_PORT on loopback interface:"
if sudo ss -tulpen | grep -F "127.0.0.1:${HOST_PORT}" >/dev/null 2>&1; then
    echo "PASS: Container port $CONTAINER_PORT is exposed on host port $HOST_PORT on loopback interface"
else
    echo "FAIL: Container port $CONTAINER_PORT is not exposed on host port $HOST_PORT"
    echo "Meaning: The container may be running, but may not have the correct port mapping to be accessible from Nginx or the host."
    exit 1
fi

# Test the backend directly via the host port to confirm the app is responding and to distinguish app/container faults from reverse-proxy faults.
echo "[3] Testing backend app directly via host port ${HOST_PORT}:"
if curl -fsS "http://localhost:${HOST_PORT}/health" >/dev/null 2>&1; then
    echo "PASS: Successfully reached containerized app directly via host loopback port ${HOST_PORT}"
else
    echo "FAIL: Could not reach containerized app directly via host port ${HOST_PORT}"
    echo "Meaning: The container may be running, but the app inside the container may have failed to start, or may be listening on the wrong port, or there may be an issue with Docker port mapping."
    exit 1
fi

# Test the backend via Nginx to confirm the full service path is working.
echo "[4] Testing backend app via Nginx reverse proxy on port 80:"
if curl -fsS "http://localhost/health" >/dev/null 2>&1; then
    echo "PASS: Successfully reached containerized app via Nginx reverse proxy"
else
    echo "FAIL: Could not reach containerized app via Nginx reverse proxy"
    echo "Meaning: The container may be running, but there may be an issue with the Nginx configuration or the reverse proxy setup."
    exit 1
fi

sleep 2
echo "PASS: All internal VM network diagnostics completed successfully"