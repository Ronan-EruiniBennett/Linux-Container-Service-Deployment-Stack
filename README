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

During the Docker image build, the RUN pip install --no-cache-dir -r requirements.txt step failed because pip could not resolve packages from PyPI. Although the failure occurred during Python dependency installation, the error log showed DNS resolution failures, so I treated it as a network issue rather than immediately changing the requirements file, package versions, or base image.

I first tested connectivity and DNS resolution from the Ubuntu VM itself using both IP addresses and domain names. These tests succeeded, which ruled out general VM-level connectivity and DNS problems. I then ran the slim Python base image independently and used a `python -c` command with the socket library to test DNS resolution and external connectivity from inside a container. Both tests failed, which narrowed the fault to Docker’s container networking layer.

I inspected the Docker network state by checking the host interfaces with `ip a`, confirming that the docker0 interface existed. I then checked the host routing table with ip route and found that the expected route to the Docker bridge subnet was missing. To verify that Docker still had a bridge network configured, I used docker network inspect bridge and confirmed that the bridge network existed and had an assigned subnet.

Restarting the Docker service recreated the missing route, after which container DNS and external connectivity worked correctly and the image build completed successfully.

I reproduced this issue multiple times after suspending and resuming the VM. The failure pattern was consistent: after resume, the Docker bridge network still existed, but the host route to the bridge subnet was missing. Restarting Docker restored the route. This showed that the immediate fault was not Python, PyPI, or the dependency list, but Docker’s bridge networking becoming out of sync with the VM’s network state after suspend/resume.

The main lesson was to debug by layer: host network first, then container network, then Docker bridge configuration, then Linux routing. This avoided wasting time changing Python dependencies when the actual failure was network reachability from the build container.

### Validating Nginx Reverse Proxy Configuration

After applying new Nginx configuration files, the browser could not reach the app. Rather than debugging only from the browser, I validated the configuration with `nginx -t` and found directive syntax errors. This reinforced the importance of validating service configuration before deployment, particularly because a broken entry point can take an application offline.