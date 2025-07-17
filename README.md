# Redis Training Environment

A complete Redis training environment using Docker containers. This setup provides hands-on experience with PostgreSQL source database, Redis Cloud target database, and data monitoring tools.

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- 2GB+ RAM recommended
- 5GB+ free disk space
- Redis Cloud instance (provided by instructor)

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Cammer15m/Redis_RDI_CTF.git
   cd Redis_RDI_CTF
   ```

2. **Start the environment:**
   ```bash
   ./start.sh
   # You'll be prompted for your Redis Cloud connection details
   ```

3. **Access the services:**
   - **Dashboard**: http://localhost:8080
   - **Redis Insight**: http://localhost:5540
   - **SQLPad (PostgreSQL)**: http://localhost:3001

## Default Credentials

| Service | Username | Password | Notes |
|---------|----------|----------|-------|
| **PostgreSQL** | postgres | postgres | Source database |
| **SQLPad** | admin@rl.org | redislabs | PostgreSQL web interface |
| **Redis Cloud** | your-username | your-password | Target database (your instance) |

## Services Overview

### PostgreSQL Database
- **Purpose**: Source database with sample music store data
- **Access**: http://localhost:3001 (SQLPad web interface)
- **Direct Access**: `docker exec -it rdi-postgres psql -U postgres -d chinook`
- **Tables**: Album, Artist, Track, Genre, MediaType, etc.

### Redis Insight
- **Purpose**: Redis database monitoring and management
- **Access**: http://localhost:5540
- **Connect to**: Your Redis Cloud instance (configured during startup)

### SQLPad
- **Purpose**: Web-based PostgreSQL query interface
- **Access**: http://localhost:3001
- **Login**: admin@rl.org / redislabs
- **Pre-configured**: Connected to PostgreSQL chinook database

### Web Dashboard
- **Purpose**: Training instructions and lab exercises
- **Access**: http://localhost:8080

## Common Tasks

### View PostgreSQL Data
```bash
# Access PostgreSQL via SQLPad web interface
open http://localhost:3001

# Or use command line
docker exec -it rdi-postgres psql -U postgres -d chinook
\dt  # List tables
SELECT * FROM "Track" LIMIT 10;
```

### Monitor Redis Cloud
```bash
# Access Redis Insight
open http://localhost:5540

# Add your Redis Cloud connection:
# Host: your-redis-host.redns.redis-cloud.com
# Port: your-port
# Username: your-username
# Password: your-password
```

### Generate Test Data
```bash
# Run data generation scripts
docker exec -it rdi-postgres psql -U postgres -d chinook -c "
INSERT INTO \"Track\" (\"Name\", \"AlbumId\", \"MediaTypeId\", \"GenreId\", \"Milliseconds\", \"Bytes\", \"UnitPrice\") 
VALUES ('Test Track', 1, 1, 1, 180000, 5000000, 0.99);
"
```

## Management Commands

### Start/Stop Environment
```bash
# Start all services
./start.sh

# Stop all services
./stop.sh

# View service status
docker ps

# View logs
docker-compose logs -f [service-name]
```

### Container Access
```bash
# Access PostgreSQL container
docker exec -it rdi-postgres bash

# Check PostgreSQL status
docker exec rdi-postgres pg_isready -U postgres

# View PostgreSQL configuration
docker exec rdi-postgres cat /etc/postgresql/postgresql.conf | grep -E "(wal_level|max_replication_slots)"
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   Redis Cloud   │    │   Monitoring    │
│   Container     │    │   (Your DB)     │    │   Tools         │
│  (chinook db)   │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        ▲                        │
         │                        │                        │
         ▼                        │                        ▼
┌─────────────────┐              │              ┌─────────────────┐
│    SQLPad       │              │              │   Redis Insight │
│  (Web Query)    │              │              │  (Redis Mgmt)   │
│  localhost:3001 │              │              │  localhost:5540 │
└─────────────────┘              │              └─────────────────┘
                                 │
                        ┌─────────────────┐
                        │   Web Dashboard │
                        │  (Instructions) │
                        │  localhost:8080 │
                        └─────────────────┘
```

**Components:**
- **PostgreSQL**: Source database with music store data
- **Redis Cloud**: Your target Redis database (external)
- **Redis Insight**: Redis monitoring and management interface
- **SQLPad**: Web-based PostgreSQL query interface
- **Web Dashboard**: Training instructions and lab exercises

## Troubleshooting

### Container Issues
```bash
# Check container status
docker ps -a

# View container logs
docker logs rdi-postgres
docker logs rdi-insight
docker logs rdi-sqlpad

# Restart services
./stop.sh && ./start.sh

# Quick diagnostic
./diagnose.sh
```

### PostgreSQL Issues
```bash
# Check PostgreSQL status
docker exec rdi-postgres pg_isready -U postgres

# Access PostgreSQL directly
docker exec -it rdi-postgres psql -U postgres -d chinook

# View PostgreSQL logs
docker logs rdi-postgres

# Check configuration
docker exec rdi-postgres cat /etc/postgresql/postgresql.conf | grep -E "(wal_level|max_replication_slots|max_wal_senders)"
```

### Port Conflicts
```bash
# Check if ports are in use
netstat -tulpn | grep -E "(5432|5540|3001|3000|8080)"

# Kill processes using ports (if needed)
sudo lsof -ti:5432 | xargs kill -9
```

### Redis Cloud Connection
```bash
# Test Redis connection (replace with your details)
redis-cli -h your-redis-host.redns.redis-cloud.com -p your-port -a your-password ping
```

## Directory Structure

```
Redis_RDI_CTF/
├── README.md                          # This file
├── start.sh                           # Environment startup script
├── stop.sh                            # Environment shutdown script
├── docker-compose-cloud.yml           # Main Docker configuration
├── postgresql.conf                    # PostgreSQL configuration
├── create_track_table.sql             # Database initialization
├── init-postgres-for-debezium.sql     # PostgreSQL setup for CDC
└── web/                               # Web dashboard files
```

## Cleanup

### Stop Everything
```bash
./stop.sh
```

### Complete Removal
```bash
# Remove containers and volumes
docker-compose -f docker-compose-cloud.yml down -v

# Remove project directory
cd .. && rm -rf Redis_RDI_CTF
```

## License

This project is licensed under the MIT License.
