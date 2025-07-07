# Redis RDI CTF 🚀

Welcome to the **Redis Data Integration (RDI) Capture The Flag** challenge! This hands-on learning environment teaches real-time data integration patterns using Redis and PostgreSQL.

## 🎯 What You'll Learn

- **Data Integration Patterns**: Snapshot vs Change Data Capture (CDC)
- **Real-time Data Replication**: PostgreSQL → Redis synchronization
- **Redis Data Structures**: Hashes, Streams, and JSON
- **Advanced RDI Features**: Transformations and multi-table replication

## 🐳 Quick Start (Docker - Recommended)

**The easiest and safest way to run the CTF!** Everything is containerized - no system changes required.

### **Prerequisites**
- **Docker**: 20.10+ with Docker Compose
- **RAM**: 2GB minimum, 4GB recommended
- **Disk**: ~1GB free space
- **Port**: 8080 available

### **🎯 Smart Startup (Recommended)**
```bash
# Clone and start with optimal experience
git clone https://github.com/Cammer15m/Redis_RDI_CTF
cd Redis_RDI_CTF

# One-command startup with verification
./start_ctf.sh

# That's it! The script will:
# ✅ Show startup logs for verification
# ✅ Auto-detect success/failure
# ✅ Keep container running in background if successful
# ✅ Give you access URL when ready
```

### **Option 1: With Redis Cloud (Recommended)**
```bash
# Configure Redis connection (get free account at redis.com)
# Edit .env and uncomment/set the Redis Cloud URL:
# REDIS_URL=redis://username:password@your-redis-cloud-host:port

# Start the CTF
./start_ctf.sh

# Access the CTF
open http://localhost:8080
```

### **Option 2: With Local Redis**
```bash
# The .env file is already configured for local Redis:
# REDIS_HOST=localhost
# REDIS_PORT=6379
# REDIS_PASSWORD=

# Start CTF + local Redis
docker-compose --profile local-redis up -d --build

# Access the CTF
open http://localhost:8080
```

## 🎮 What's Included

### **Single Container Includes:**
- ✅ **PostgreSQL** with sample music database (3,494+ tracks)
- ✅ **Python environment** with all dependencies
- ✅ **RDI connector scripts** for data synchronization
- ✅ **Web monitoring interface** (http://localhost:8080)
- ✅ **All lab materials** and CTF challenges
- ✅ **Flag validation system**
- ✅ **Database access** via container shell

### **External (Your Choice):**
- 🔗 **Redis** - Use Redis Cloud (recommended) or local Redis

## 🚀 Getting Started

### **1. Start the Container**
```bash
# Quick test build
./build_and_test.sh

# Or manual start
docker-compose up --build
```

### **2. Configure Redis Connection**
Edit `.env` file:
```bash
# For Redis Cloud (recommended)
REDIS_URL=redis://username:password@host:port

# Or for local Redis
REDIS_HOST=localhost
REDIS_PORT=6379
```

### **3. Begin Lab 1**
```bash
# Enter the container
docker exec -it redis-rdi-ctf bash

# Navigate to Lab 1
cd labs/01_postgres_to_redis
cat README.md

# Start RDI connector
cd /app/scripts
python3 rdi_connector.py
```

### **4. Monitor Your Progress**
- **Web UI**: http://localhost:8080
- **Flag Checker**: `python3 scripts/check_flags.py`
- **Database Access**: `docker exec -it redis-rdi-ctf psql -U rdi_user -d rdi_db`

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │───▶│   RDI Connector │───▶│   Redis Cloud   │
│  (Container)    │    │  (Container)    │    │   (Your DB)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                        ▲
         │                       │                        │
         ▼                       ▼                        │
┌─────────────────┐    ┌─────────────────┐                │
│    SQLPad       │    │   Web Monitor   │────────────────┘
│  (Container)    │    │  (Container)    │
└─────────────────┘    └─────────────────┘
```

**Components:**
- **🐳 Container**: PostgreSQL, RDI Connector, Web UI, SQLPad
- **☁️ External**: Redis Cloud (or local Redis)
- **🔗 Integration**: Custom RDI simulation handles real-time sync

## 📚 Lab Overview

| Lab | Topic | Difficulty | Estimated Time |
|-----|-------|------------|----------------|
| **01** | PostgreSQL → Redis (Snapshot) | 🟢 Beginner | 15 minutes |
| **02** | Snapshot vs CDC | 🟡 Intermediate | 25 minutes |
| **03** | Advanced RDI Features | 🟠 Advanced | 20 minutes |

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

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Happy Learning! 🎉**

*Ready to become a Redis Data Integration expert? Start with Lab 1 and work your way through the challenges!*
