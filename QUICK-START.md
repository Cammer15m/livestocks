# 🚀 Redis RDI Training - Quick Start

**Get up and running with Redis Data Integration in under 2 minutes!**

## Prerequisites
- Docker & Docker Compose
- Redis Cloud account (free at [redis.io/try-free](https://redis.io/try-free))

## 30-Second Setup

### 1. Clone & Configure
```bash
git clone https://github.com/Cammer15m/Redis_RDI_CTF.git
cd Redis_RDI_CTF
cp .env.template .env
```

### 2. Add Redis Cloud Details
Edit `.env` with your Redis Cloud connection info:
```bash
REDIS_HOST=redis-12345.c123.us-east-1-1.ec2.redns.redis-cloud.com
REDIS_PORT=12345
REDIS_PASSWORD=your-password
REDIS_USER=default
```

### 3. Start Everything
```bash
./quick-start.sh
```

### 4. Configure RDI Pipeline
```bash
docker exec -it rdi-cli redis-di configure
docker exec -it rdi-cli redis-di deploy --config /config/config-cloud.yaml
docker exec -it rdi-cli redis-di start
```

### 5. Test Data Flow
```bash
# Start load generator
docker exec -it rdi-loadgen python /scripts/generate_load.py

# Check RDI status
docker exec -it rdi-cli redis-di status
```

## 🎯 Access Points
- **Training Dashboard**: http://localhost:8080
- **Redis Insight**: http://localhost:5540 (connect to your Redis Cloud)
- **PostgreSQL**: localhost:5432

## ✅ Success Check
Your setup is working when:
1. `redis-di status` shows "running"
2. Data appears in Redis Cloud (check via Redis Insight)
3. PostgreSQL changes sync to Redis in real-time

## 🛑 Stop Everything
```bash
docker-compose -f docker-compose-cloud.yml down
```

---

**That's it! You're now running a complete Redis Data Integration pipeline.** 🎉

The focus is on **using RDI**, not installing it. Start experimenting with data transformations, monitoring, and real-time sync!
