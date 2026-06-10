[![Docker Image CI](https://github.com/Ronan-EruiniBennett/Linux-Container-Service-Deployment-Stack/actions/workflows/docker-image.yml/badge.svg)](https://github.com/Ronan-EruiniBennett/Linux-Container-Service-Deployment-Stack/actions/workflows/docker-image.yml)

# Linux Networking & Containerised Service Deployment

A self-hosted Linux environment for deploying, routing, securing, and validating a containerised Flask/Gunicorn service through Docker, Nginx, UFW, SSH, and Bash automation.

## Project Overview

This project implements a small production-like service environment for deploying and operating a containerised web application on a Linux host.

The application runs as a Flask/Gunicorn service inside Docker and is exposed through an Nginx reverse proxy on the host. Bash scripts automate the build, run, configuration, validation, and cleanup workflows, while smoke tests verify that the deployed service responds correctly through the expected network path.

The environment is hosted on a local Linux VM and administered over SSH using key-based access. Supporting infrastructure includes UFW firewall rules, host-level file permission controls, Docker port mappings, Nginx configuration validation, and troubleshooting procedures for failures across the Linux host, container runtime, networking layer, and application service.

### Tech Stack

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=flat&logo=gnu-bash&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![Flask](https://img.shields.io/badge/Flask-000000?style=flat&logo=flask&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![Gunicorn](https://img.shields.io/badge/gunicorn-%298729.svg?style=for-the-badge&logo=gunicorn&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

## Architecture

**System Traffic Flow Chart**
```mermaid
flowchart TD
    %% Infrastructure Operations Lab - Traffic Flow

    Client["Client<br/>Browser or curl"] -->|"HTTP request<br/>VM_IP:80"| VMNetwork["Linux VM network interface"]

    VMNetwork -->|"Port 80"| Nginx["Nginx<br/>Reverse proxy"]

    Nginx -->|"proxy_pass<br/>http://127.0.0.1:5000"| HostLoopback["Host loopback interface<br/>127.0.0.1:5000"]

    HostLoopback -->|"Docker port mapping<br/>127.0.0.1:5000 → container:5000"| DockerBridge["Docker networking<br/>bridge / NAT"]

    DockerBridge --> Gunicorn["Gunicorn<br/>WSGI server"]

    Gunicorn --> Flask["Flask application"]

    Flask --> Endpoints["Application endpoints<br/>/, /health, /version, /metrics"]

    Endpoints -->|"HTTP response"| Flask
    Flask --> Gunicorn
    Gunicorn --> DockerBridge
    DockerBridge --> HostLoopback
    HostLoopback --> Nginx
    Nginx --> VMNetwork
    VMNetwork --> Client
```

**CI Flow Chart**
```mermaid id="g3v7pc"
flowchart TD
    %% GitHub Actions CI Flow

    Trigger["Push to main<br/>or Pull Request to main"] --> Runner["GitHub Actions Runner<br/>ubuntu-latest"]

    Runner --> Checkout["Checkout repository"]

    Checkout --> BashSyntax["Validate Bash syntax<br/>bash -n scripts/*.sh"]

    BashSyntax --> ShellCheck["Lint Bash scripts<br/>shellcheck scripts/*.sh"]

    ShellCheck --> DockerBuild["Build Docker image<br/>docker build -t infra-lab ."]

    DockerBuild --> RunContainer["Run container<br/>docker run --name flask-app -p 5000:5000 infra-lab"]

    RunContainer --> HealthCheck["Check application health<br/>curl http://localhost:5000/health"]

    HealthCheck --> CleanupStop["Stop container<br/>docker stop flask-app"]

    CleanupStop --> CleanupRemove["Remove container<br/>docker rm flask-app"]

    CleanupRemove --> Result{"CI result"}

    Result -->|All checks pass| Pass["Workflow passes"]
    Result -->|Any check fails| Fail["Workflow fails"]

    BashSyntax -.->|syntax error| Fail
    ShellCheck -.->|lint issue| Fail
    DockerBuild -.->|image build error| Fail
    RunContainer -.->|container start error| Fail
    HealthCheck -.->|health check fails| Fail
```

## Key Features

- **GitHub Actions CI:** built a GitHub Actions workflow to automatically validate Bash script syntax, run ShellCheck, build the Docker image, start the Flask/Gunicorn container, and test the end-to-end request flow across the application endpoints.


- **Bash Automation:** created Bash scripts to automate the deployment workflow, including network diagnostic checks, Docker image builds, Nginx configuration validation and reloads, container deployment, endpoint testing, and clean-up.


- **Containerised runtime with Docker:** packaged the app, dependencies, exposed port, and startup command into a reproducible image so the same build can run consistently across CI and compatible Linux AMD64 deployment environments.


- **Nginx Reverse Proxy:** configured Nginx as the public HTTP entry point on port 80, proxying requests to the Docker-hosted backend exposed on the host loopback interface. This reduced direct network exposure for the backend, separated public traffic handling from the application runtime, and provided a central layer for access logging, request header forwarding, and future TLS termination.

- **SSH-based remote administration:** configured key-based SSH access to manage the Linux VM, run deployment scripts, troubleshoot Docker/Nginx issues, and validate service health from the command line. Configured Linux ufw to only accept SSH and Nginx http traffic. 

## Challenges


### Diagnosing Docker Container Networking After VM Resume

**Symptom:** 

Pip install failure for `requirements.txt` on Docker image build as docker couldn't resolve or reach external package repositories

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
