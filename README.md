[![Docker Image CI](https://github.com/Ronan-EruiniBennett/Infrastructure_operations_lab/actions/workflows/docker-image.yml/badge.svg)](https://github.com/Ronan-EruiniBennett/Infrastructure_operations_lab/actions/workflows/docker-image.yml)

# Infrastructure Operations Lab

A self-hosted infrastructure operations lab for deploying, monitoring, and troubleshooting containerised services on Linux using Docker, Nginx, Flask, Gunicorn, and Bash.

## Project Overview
This project emulates a small production like service environment where a containerised web application is deployed, presented through a reverse proxy, validated and tested through scripts. The goal was to develop professional experience of Linux administration, containerisation, networking, deployment workflows, and troubleshooting.

Instead of focusing only on application code, the project explores how an app is packaged, configured, networked, and run in a more production-like setting. It helped me understand the relationship between source code, runtime dependencies, containers, ports, environment configuration, and deployment infrastructure.

## Architecture

### Tech Stack

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=flat&logo=gnu-bash&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![Flask](https://img.shields.io/badge/Flask-000000?style=flat&logo=flask&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![Gunicorn](https://img.shields.io/badge/gunicorn-%298729.svg?style=for-the-badge&logo=gunicorn&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)


## Key Features

- **GitHub Actions CI:** built a GitHub Actions workflow to automatically validate Bash script syntax, run ShellCheck, build the Docker image, start the Flask/Gunicorn container, and test the end-to-end request flow across the application endpoints.


- **Bash Automation:** created Bash scripts to automate the deployment workflow, including network diagnostic checks, Docker image builds, Nginx configuration validation and reloads, container deployment, endpoint testing, and clean-up.


- **Containerised runtime with Docker:** packaged the app, dependencies, exposed port, and startup command into a reproducible image so the same build can run consistently across CI and compatible Linux AMD64 deployment environments.


- **Nginx Reverse Proxy:** configured Nginx as the public HTTP entry point on port 80, proxying requests to the Docker-hosted backend exposed on the host loopback interface. This reduced direct network exposure for the backend, separated public traffic handling from the application runtime, and provided a central layer for access logging, request header forwarding, and future TLS termination.

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

**Symptom:** Browser couldn't reach the application through Nginx after new configuration file changes

**Investigation:**

* Examined Nginx status on the VM
* Validated configuration with `nginx -t`

**Likely Root Cause:**

There were directive syntax errors in the configuration file I created, so Nginx could not safely reload the new configuration and proxy traffic to my backend correctly.

**Resolution:**

Corrected the syntax errors identified by `nginx -t`. Moving forward, this reinforced the importance of validating all configuration and code before deployment, especially when changes affect the application's entry point.
