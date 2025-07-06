# 🐳 Redis RDI CTF - Docker Setup

**The easiest way to run the Redis RDI CTF!** Everything is containerized - no system pollution, no complex setup, no uninstall headaches.

## 🚀 Quick Start

### **Option 1: With Redis Cloud (Recommended)**
```bash
# Clone the repository
git clone https://github.com/Cammer15m/Redis_RDI_CTF
cd Redis_RDI_CTF

# Configure Redis connection
cp .env.template .env
# Edit .env with your Redis Cloud connection details

# Build and start the CTF container
docker-compose -f docker-compose.simple.yml up --build

# Access the CTF
open http://localhost:8080
```

### **Option 2: With Local Redis**
```bash
# Clone the repository
git clone https://github.com/Cammer15m/Redis_RDI_CTF
cd Redis_RDI_CTF

# Start CTF + local Redis
docker-compose -f docker-compose.simple.yml --profile local-redis up --build

# Access the CTF
open http://localhost:8080
```

## 🎯 What You Get

### **Single Container Includes:**
- ✅ **PostgreSQL** with sample music database (3,494+ tracks)
- ✅ **Python environment** with all dependencies
- ✅ **RDI connector scripts** for data synchronization
- ✅ **Web monitoring interface** (http://localhost:8080)
- ✅ **Database shell access** via `docker exec`
- ✅ **All lab materials** and CTF challenges
- ✅ **Flag validation system**

### **External (Your Choice):**
- 🔗 **Redis** - Use Redis Cloud or local Redis instance

## 📊 System Requirements

- **Docker**: 20.10+ with Docker Compose
- **RAM**: 2GB minimum, 4GB recommended
- **Disk**: ~1GB for container + data
- **Port**: 8080 (and 6379 if using local Redis)

## ⚙️ Configuration

### **Redis Connection**
Edit `.env` file:
```bash
# For Redis Cloud
REDIS_URL=redis://username:password@host:port

# Or for local Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
```

### **Database Connection (Pre-configured)**
```bash
DB_HOST=localhost
DB_PORT=5432
DB_NAME=rdi_db
DB_USER=rdi_user
DB_PASSWORD=rdi_password
```

## 🎮 Running the CTF

### **1. Start the Container**
```bash
docker-compose -f docker-compose.simple.yml up
```

### **2. Verify Setup**
```bash
# Check container logs
docker logs redis-rdi-ctf

# Test database connection
docker exec redis-rdi-ctf psql -U rdi_user -d rdi_db -c "SELECT COUNT(*) FROM \"Track\";"
```

### **3. Start Lab 1**
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

### **4. Monitor Progress**
- **Web UI**: http://localhost:8080
- **SQLPad**: http://localhost:3001
- **Logs**: `docker logs redis-rdi-ctf`

## 🧹 Cleanup

### **Stop Everything**
```bash
docker-compose -f docker-compose.simple.yml down
```

### **Complete Removal**
```bash
# Remove containers and volumes
docker-compose -f docker-compose.simple.yml down -v

# Remove images
docker rmi redis-rdi-ctf_redis-rdi-ctf redis:7-alpine

# Remove project directory
cd ..
rm -rf Redis_RDI_CTF
```

## 🔧 Troubleshooting

### **Container Won't Start**
```bash
# Check logs
docker logs redis-rdi-ctf

# Rebuild container
docker-compose -f docker-compose.simple.yml up --build --force-recreate
```

### **Can't Connect to Redis**
```bash
# Check .env configuration
cat .env

# Test Redis connection
docker exec redis-rdi-ctf python3 -c "import redis; r=redis.from_url('your-redis-url'); print(r.ping())"
```

### **PostgreSQL Issues**
```bash
# Check PostgreSQL status
docker exec redis-rdi-ctf pg_isready -U rdi_user -d rdi_db

# View PostgreSQL logs
docker exec redis-rdi-ctf tail -f /var/log/postgresql.log
```

## 🎉 Benefits of Docker Approach

- ✅ **No system pollution** - Everything isolated in containers
- ✅ **Consistent environment** - Works the same everywhere
- ✅ **Easy cleanup** - Just remove containers
- ✅ **No sudo required** - No system package installation
- ✅ **Portable** - Share the exact same environment
- ✅ **Safe** - Won't affect your system's PostgreSQL, Python, etc.

## 🚀 Next Steps

1. **Complete Lab 1** - Basic PostgreSQL → Redis sync
2. **Try Lab 2** - Snapshot vs CDC patterns
3. **Master Lab 3** - Advanced RDI features
4. **Collect all flags** - Use `python3 scripts/check_flags.py`

Happy learning! 🎵🔗
