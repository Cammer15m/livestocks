# RDI-Compatible Docker Container

This container is built using Ubuntu 22.04 with systemd as PID 1, configured to support Redis Data Integration (RDI) installation via the official install script.

## Features
- Ubuntu 22.04 base image
- systemd as PID 1 for full service management
- Privileged mode with cgroup support
- Pre-installed dependencies for RDI installation

## Quick Start

1. Build and start the container:
```bash
cd rdi-container
docker-compose up --build -d
```

2. Verify systemd is running:
```bash
docker exec -it rdi-container ps -p 1 -o comm=
# Should return: systemd
```

3. Install RDI:
```bash
docker exec -it rdi-container bash
curl -s https://downloads.redis.com/rdi/install.sh | bash
```

## Verification Checklist
- [ ] systemd is running as PID 1
- [ ] K3s installed and active
- [ ] RDI CLI works without errors

## Container Configuration
- **Privileged**: Required for systemd and K3s
- **cgroupns**: host mode for proper cgroup management
- **Volumes**: /sys/fs/cgroup mounted as read-write
- **tmpfs**: /run and /tmp for systemd operation
