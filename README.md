# Redis RDI Training Environment 🚀

Welcome to the **Redis Data Integration (RDI) Training Environment**! This professional setup provides hands-on experience with real Redis RDI, PostgreSQL, and Redis Enterprise.

## 🎯 What You'll Learn

- **Real Redis RDI**: Work with actual Redis Data Integration tools
- **Production Environment**: Redis Enterprise cluster with monitoring
- **Data Pipeline Management**: Configure and manage real data pipelines
- **Professional Tools**: Redis Insight, Grafana monitoring, Prometheus metrics

## 🐳 Quick Start

**Professional Redis RDI training environment with Redis Enterprise!**

### **Prerequisites**
- **Docker**: 20.10+ with Docker Compose
- **RAM**: 8GB minimum, 16GB recommended
- **Disk**: ~5GB free space
- **Redis Cloud Account**: Free at [redis.com/try-free](https://redis.com/try-free/)

### **🎯 Quick Setup**
```bash
# Clone the repository
git clone https://github.com/Cammer15m/Redis_RDI_CTF
cd Redis_RDI_CTF

# Set domain and start all services
export DOMAIN=localhost
./start.sh

# The script will start:
# ✅ Redis Enterprise cluster
# ✅ PostgreSQL with sample data
# ✅ Redis RDI for data integration
# ✅ Redis Insight for monitoring
# ✅ Grafana + Prometheus monitoring stack
```

### **🌐 Service Access**
- **Redis Insight**: http://localhost:8443
- **Grafana Monitoring**: http://localhost:3000
- **PostgreSQL**: localhost:5432 (postgres/postgres/postgres)

### **🔧 Configure RDI**
```bash
# 1. Access the RDI container
docker exec -it rdi bash

# 2. Configure RDI with your Redis Cloud connection
redis-di configure --rdi-host localhost:13000 --rdi-password <password>

# 3. Set up data pipeline
redis-di create-pipeline --name postgres-pipeline

# 4. Deploy and start pipeline
redis-di deploy
redis-di start
```

### **🧪 Testing & Monitoring**
```bash
# Check RDI status
docker exec -it rdi redis-di status

# View RDI logs
docker exec -it rdi redis-di logs

# Access PostgreSQL for testing
docker exec -it postgres psql -U postgres -d postgres

# Monitor with Redis Insight
# Visit: http://localhost:8443
```

### **⚠️ Important: Clean Start**
If you encounter issues, ensure clean startup:
```bash
# Stop all containers
./stop.sh

# Clean up
docker system prune -f

# Start fresh
export DOMAIN=localhost
./start.sh
```

## 🛑 Stopping the Environment

```bash
# Stop all containers safely
./stop.sh

# Or manually
docker-compose down

# Remove all data
docker-compose down -v
```

## 🎮 Architecture

### **Multi-Container Setup:**
- 🗄️ **PostgreSQL Container**: Music store database with sample data
- 🔍 **Redis Insight Container**: RDI configuration and monitoring (optional)
- ⚙️ **RDI CLI Container**: Redis Data Integration management
- 📊 **Load Generator Container**: Test data generation
- 🌐 **Web Interface Container**: CTF instructions and dashboard

### **Redis Insight Options:**

**Option 1: Containerized Redis Insight (Default)**
- ✅ Runs in Docker container
- ✅ Accessible at `http://localhost:5540`
- ✅ Easier setup, no additional downloads
- ✅ Automatically configured

**Option 2: External Redis Insight**
- 🔗 Download from [redis.io/downloads](https://redis.io/downloads/#Redis_Insight)
- 🖥️ Professional desktop application
- ⚡ Better performance and more features
- 🔧 Use `./configure_external_insight.sh` for connection details
- 📱 Available for Windows, macOS, and Linux

### **External Requirements:**
- 🔗 **Redis Cloud**: Your target Redis database (free account)

## 🚀 Getting Started

### **1. Prerequisites Setup**
```bash
# Sign up for Redis Cloud (free)
# Visit: https://redis.com/try-free/
# Create a database and get connection details
```

### **2. Start the Environment**
```bash
./start_ctf.sh
```

### **3. Configure RDI**
```bash
# Copy and edit RDI configuration
docker exec -it rdi-ctf-cli cp /config/config.yaml.template /config/config.yaml
docker exec -it rdi-ctf-cli nano /config/config.yaml

# Update with your Redis Cloud details:
# host: your-redis-host.redns.redis-cloud.com
# port: your-port
# password: your-password
```

### **4. Deploy and Start RDI**
```bash
# Deploy configuration
docker exec -it rdi-ctf-cli redis-di deploy --config /config/config.yaml

# Start the pipeline
docker exec -it rdi-ctf-cli redis-di start

# Check status
docker exec -it rdi-ctf-cli redis-di status
```

### **5. Begin Labs**
- **Web Dashboard**: http://localhost:8080
- **Redis Insight**: http://localhost:5540
- **Follow lab instructions** in the web interface

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │───▶│   Redis RDI     │───▶│   Redis Cloud   │
│   Container     │    │   Container     │    │   (Your DB)     │
│  (musicstore)   │    │   (CLI/Mgmt)    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                        ▲
         │                       │                        │
         ▼                       ▼                        │
┌─────────────────┐    ┌─────────────────┐                │
│  Load Generator │    │  Redis Insight  │────────────────┘
│   Container     │    │   Container     │
│  (Test Data)    │    │ (Configuration) │
└─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────┐
│           Web Interface                 │
│          (Instructions)                 │
└─────────────────────────────────────────┘
```

**Components:**
- **🗄️ PostgreSQL**: Source database with music store data
- **⚙️ RDI CLI**: Real Redis RDI for data integration
- **🔍 Redis Insight**: Configuration and monitoring interface
- **📊 Load Generator**: Creates test data for CDC
- **🌐 Web Interface**: CTF instructions and dashboard
- **☁️ Redis Cloud**: Your target Redis database

## 📚 Lab Overview

| Lab | Topic | Difficulty | Estimated Time |
|-----|-------|------------|----------------|
| **01** | PostgreSQL → Redis (Snapshot) | 🟢 Beginner | 20 minutes |
| **02** | Change Data Capture (CDC) | 🟡 Intermediate | 30 minutes |
| **03** | Advanced Transformations | 🟠 Advanced | 25 minutes |

## 🧪 Testing & Validation

### **Quick Validation**
```bash
# Validate setup without Docker
./validate_setup.sh
```

### **Full Integration Test**
```bash
# Complete test with Docker (requires Docker installed)
./integration_test.sh
```

## 🎮 CTF Flags

Each lab contains a hidden flag. Collect all flags to complete the challenge:

```bash
# Check your progress
cd scripts
python3 check_flags.py
```

**Expected Flags:**
- `flag:01` → `RDI{pg_to_redis_success}`
- `flag:02` → `RDI{snapshot_vs_cdc_detected}`
- `flag:03` → `RDI{advanced_features_mastered}`

## 🛠️ Services & Access

| Service | Access Method | Purpose |
|---------|---------------|---------|
| **Web Monitor** | http://localhost:8080 | Main CTF interface |
| **PostgreSQL** | Container shell | Source database |
| **Redis** | External (your choice) | Target database |

### **Container Access Methods:**
```bash
# Main web interface (external)
open http://localhost:8080

# Database access (container shell)
docker exec -it redis-rdi-ctf psql -U rdi_user -d rdi_db

# Run CTF scripts (container shell)
docker exec -it redis-rdi-ctf bash
cd scripts && python3 rdi_connector.py
```

## 🧹 Cleanup

### **Stop Everything**
```bash
docker-compose down
```

### **Complete Removal**
```bash
# Remove containers and volumes
docker-compose down -v

# Remove images
docker rmi redis-rdi-ctf_redis-rdi-ctf

# Remove project directory
cd .. && rm -rf Redis_RDI_CTF
```

## 📁 Directory Structure

```
Redis_RDI_CTF/
├── 📖 README.md                 # This file
├── 🐳 Dockerfile                # Container definition
├── 🐳 docker-compose.yml        # Service orchestration
├── ⚙️  .env                     # Environment configuration
├── 🧪 labs/                     # Hands-on exercises
│   ├── 01_postgres_to_redis/    # Lab 1: Basic integration
│   ├── 02_snapshot_vs_cdc/      # Lab 2: Replication modes
│   └── 03_advanced_rdi/         # Lab 3: Advanced features
├── 🔧 scripts/                  # Utility scripts
│   ├── check_flags.py           # Progress checker
│   ├── rdi_connector.py         # Main RDI simulation
│   └── rdi_web.py               # Web monitoring interface
├── 🌱 seed/                     # Sample data
│   └── music_database.sql       # Chinook database
├── 🐳 docker/                   # Container support files
└── 📚 docs/                     # Documentation
```

## 🔧 Troubleshooting

### **Container Won't Start**
```bash
# Use the smart startup script (recommended)
./start_ctf.sh

# If that fails, check logs manually
docker logs redis-rdi-ctf

# Rebuild container
docker-compose up --build --force-recreate
```

### **Startup Script Issues**
```bash
# Make sure script is executable
chmod +x start_ctf.sh

# Run with verbose output
bash -x start_ctf.sh

# Manual startup if script fails
docker-compose up -d --build
docker logs -f redis-rdi-ctf
```

### **Can't Connect to Redis**
```bash
# Check .env configuration
cat .env

# Test Redis connection from container
docker exec redis-rdi-ctf python3 -c "import redis; r=redis.from_url('your-redis-url'); print(r.ping())"
```

### **PostgreSQL Issues**
```bash
# Check PostgreSQL status
docker exec redis-rdi-ctf pg_isready -U rdi_user -d rdi_db

# Access PostgreSQL directly
docker exec -it redis-rdi-ctf psql -U rdi_user -d rdi_db

# View PostgreSQL logs
docker exec redis-rdi-ctf tail -f /var/log/postgresql.log
```

### **Port Conflicts**
```bash
# Check if port 8080 is in use
netstat -an | grep 8080

# Use different port if needed
docker compose up -p 18080:8080
```

## 🐳 Container Access Guide

### **Everything Runs Inside the Container**
The CTF is designed to be completely self-contained. All services run inside Docker:

```bash
# Main interface (external access)
open http://localhost:8080

# Database queries (inside container)
docker exec -it redis-rdi-ctf psql -U rdi_user -d rdi_db -c "SELECT COUNT(*) FROM \"Track\";"

# Interactive database session
docker exec -it redis-rdi-ctf psql -U rdi_user -d rdi_db

# Run CTF scripts
docker exec -it redis-rdi-ctf bash
cd scripts
python3 rdi_connector.py

# Check flags
docker exec -it redis-rdi-ctf python3 scripts/check_flags.py
```

### **Why Single Port Design?**
- ✅ **Simpler setup** - Only one port to remember
- ✅ **More secure** - No database exposed to host
- ✅ **Fewer conflicts** - Less chance of port collisions
- ✅ **Container-native** - Everything accessible via `docker exec`

## 💡 Advanced Setup (Local Installation)

For advanced users who prefer local installation, see [docs/LEGACY_SETUP.md](docs/LEGACY_SETUP.md).

**⚠️ Warning**: Local installation modifies your system and requires manual cleanup.

## 🎓 Learning Resources

- [Redis Data Integration Documentation](https://redis.io/docs/data-integration/)
- [Redis Streams Guide](https://redis.io/docs/data-types/streams/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [RedisInsight Documentation](https://redis.com/redis-enterprise/redis-insight/)

## 🤝 Contributing

Found an issue or want to improve the labs? Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 🚀 Quick Reference

```bash
# Start CTF environment
./start_ctf.sh

# Stop CTF environment
./stop_ctf.sh

# Validate setup
./validate_setup.sh

# Full integration test
./integration_test.sh
```

## 🐳 Container Access

```bash
# Access PostgreSQL database
docker exec -it rdi-ctf-postgres psql -U postgres -d musicstore

# Access RDI CLI for pipeline management
docker exec -it rdi-ctf-cli bash
docker exec -it rdi-ctf-cli redis-di status

# Run load generator for testing
docker exec -it rdi-ctf-loadgen python /scripts/generate_load.py

# View container logs
docker logs rdi-ctf-postgres
docker logs rdi-ctf-cli
docker logs rdi-ctf-insight
docker logs rdi-ctf-web

# Check all CTF containers
docker ps | grep rdi-ctf
```

## 🎯 What's New in This Version

This Redis RDI CTF has been completely refactored to provide a **professional, production-like experience**:

### **✨ Key Improvements**
- **🏗️ Multi-Container Architecture**: Separate containers for each service (PostgreSQL, RDI CLI, Redis Insight, Load Generator, Web Interface)
- **⚙️ Real Redis RDI**: Uses actual Redis RDI CLI instead of simulation
- **🔍 Redis Insight Integration**: Professional RDI configuration and monitoring interface
- **📊 Advanced Load Generation**: Realistic data generation for CDC testing
- **🌐 Enhanced Web Interface**: Comprehensive instructions and dashboard
- **🧪 Comprehensive Testing**: Validation and integration test scripts

### **🎓 Learning Benefits**
- **Real-world Skills**: Learn actual Redis RDI, not just concepts
- **Professional Tools**: Use the same tools used in production environments
- **Hands-on Experience**: Configure real data pipelines with Redis Cloud
- **Best Practices**: Follow industry-standard deployment patterns

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Happy Learning! 🎉**

*Ready to become a Redis Data Integration expert? Start with Lab 1 and work your way through the challenges!*
