# Redis RDI CTF Lab - Helm-based Deployment

A complete Redis Data Integration (RDI) training environment using Helm and Kubernetes (K3s) in Docker containers. This setup provides hands-on experience with Redis Enterprise, PostgreSQL, and real-time data integration pipelines using modern cloud-native deployment methods.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- 4GB+ RAM recommended
- 10GB+ free disk space

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Cammer15m/Redis_RDI_CTF.git
   cd Redis_RDI_CTF
   ```

2. **Start the lab environment:**
   ```bash
   ./start-helm-lab.sh
   ```

3. **Configure and install RDI:**
   ```bash
   # Access the RDI container
   docker exec -it rdi-helm bash
   
   # Configure RDI with default Redis Cloud connection
   cd /rdi
   ./configure-rdi-values.sh
   
   # Install RDI via Helm
   ./install-rdi-helm.sh --skip-download
   ```

## 🔧 Custom Redis Configuration

To use your own Redis instance instead of the default Redis Cloud:

```bash
# Set your Redis connection details
export REDIS_HOST=your-redis-host.com
export REDIS_PORT=6379
export REDIS_PASSWORD=your-password

# Start the lab with custom configuration
./start-helm-lab.sh
```

## 📊 Access Points

Once the lab is running, you can access:

- **Web Interface**: http://localhost:8082 - Lab instructions and guides
- **Redis Insight**: http://localhost:5541 - Redis database browser
- **Log Viewer**: http://localhost:8083 - Container logs and monitoring
- **PostgreSQL**: localhost:5433 - Source database (postgres/postgres)

## 🏗️ Architecture

This Helm-based deployment includes:

- **PostgreSQL Container**: Source database with Chinook sample data
- **RDI Helm Container**: K3s + Helm + RDI deployment tools
- **Redis Insight**: Web-based Redis browser
- **Web Interface**: Lab instructions and documentation
- **Log Viewer**: Real-time container monitoring

## 🔄 RDI Installation Process

The RDI installation uses Helm charts and follows these steps:

1. **Download RDI Helm Chart**: Automatically downloads from Redis S3
2. **Configure Values**: Sets Redis connection and JWT authentication
3. **Deploy via Helm**: Installs RDI components on K3s cluster
4. **Verify Deployment**: Checks all pods and services are running

## 📝 Configuration Files

- `rdi-values.yaml`: Helm values for RDI configuration
- `install-rdi-helm.sh`: Main Helm installation script
- `configure-rdi-values.sh`: Helper script for configuration
- `docker-compose-helm.yml`: Container orchestration

## 🛠️ Management Commands

```bash
# Start the lab
./start-helm-lab.sh

# Stop the lab
./stop-helm-lab.sh

# Access RDI container
docker exec -it rdi-helm bash

# Check RDI status (inside container)
kubectl get all -n rdi

# View RDI logs (inside container)
kubectl logs -n rdi -l app=rdi

# Restart RDI installation
cd /rdi && ./install-rdi-helm.sh --skip-download
```

## 🔍 Troubleshooting

### K3s Issues
If K3s fails to start:
```bash
docker exec -it rdi-helm bash
systemctl restart k3s
kubectl get nodes
```

### RDI Installation Issues
Check Helm deployment status:
```bash
helm list -n rdi
kubectl describe pods -n rdi
```

### Container Issues
View container logs:
```bash
docker logs rdi-helm
docker logs rdi-postgres-helm
```

## 🌟 Features

- **Completely Containerized**: No local installations required
- **Cloud-Native**: Uses Helm and Kubernetes for deployment
- **Flexible Configuration**: Easy Redis connection customization
- **Production-Like**: Mirrors real-world RDI deployments
- **Educational**: Perfect for learning modern data integration

## 📚 Learning Objectives

- Deploy RDI using Helm charts
- Configure Kubernetes-based data pipelines
- Monitor real-time data integration
- Understand cloud-native Redis deployments
- Practice with production deployment tools

## 🤝 Contributing

This lab environment is designed for educational purposes. Feel free to submit issues or improvements to enhance the learning experience.
