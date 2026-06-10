# Infrastructure Operations Lab

A self-hosted infrastructure operations lab for deploying, monitoring, and troubleshooting containerised services on Linux using Docker, Nginx, Flask, Gunicorn, and Bash.

## Project Overview
This project emulates a small production like service environment where a containerised web application is deployed, presented through a reverse proxy, validated and tested through scripts. The goal was to develop professional experience of Linux administration, containerisation, networking, deployment workflows, and troubleshooting.

Instead of focusing only on application code, the project explores how an app is packaged, configured, networked, and run in a more production-like setting. It helped me understand the relationship between source code, runtime dependencies, containers, ports, environment configuration, and deployment infrastructure.

## Architecture


## Key Features

- **Containerised runtime with Docker:** packaged the app, dependencies, exposed port, and startup command into a reproducible image so the same build can run consistently across CI and compatible Linux AMD64 deployment environments.

- 

## Challenges

### Diagnosing Docker Container Networking After VM Resume

**Symptom:** Pip install failure for `requirements.txt` on Docker image build as docker couldn't resolve or reach external package repositories

**Investigation:**

* Verified it wasn't a core dependency problem due to using the Python slim image, but a networking issue
* Tested DNS resolution and ping to an IP from the VM host
* Ran the base image on its own and had it run commands for DNS resolution and connection to an IP from inside the container; both failed
* Checked the existence of the Docker bridge subnet and `docker0` interface
* Examined VM routing tables and found the route to the Docker bridge subnet was missing

**Likely Root Cause:**
Suspending the VM and resuming it without completely powering it off likely caused some of Docker’s networking state to not be fully restored, resulting in the missing route for the Docker subnet

**Resolution:**
Restarted the Docker service to restore connectivity to containers, and going forward I’ll fully power off the VM instead of relying on suspend/resume when Docker networking is active.

### Validating Nginx Reverse Proxy Configuration

After applying new Nginx configuration files, the browser could not reach the app. Rather than debugging only from the browser, I validated the configuration with `nginx -t` and found directive syntax errors. This reinforced the importance of validating service configuration before deployment, particularly because a broken entry point can take an application offline.