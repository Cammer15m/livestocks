# Lab 01: PostgreSQL to Redis - Snapshot Migration

## 🎯 Learning Objectives

By completing this lab, you will:
- Understand the fundamentals of Redis Data Integration (RDI)
- Learn how to perform a snapshot migration from PostgreSQL to Redis
- Configure RDI pipelines using Redis Cloud
- Verify data migration and transformation
- Apply filters and transformations during data ingestion

## 📋 Prerequisites

- Redis Cloud account with RDI enabled
- Docker and Docker Compose installed
- Basic understanding of PostgreSQL and Redis

## 🏗️ Lab Architecture

```
PostgreSQL (Source) → Redis RDI → Redis Cloud (Target)
     ↓                    ↓              ↓
  Music Database    Data Pipeline    Transformed Data
```

In this lab, we'll migrate music track data from a PostgreSQL database to Redis Cloud using RDI's snapshot feature.

## 🚀 Step 1: Environment Setup

### 1.1 Start the Lab Infrastructure

First, start the complete RDI CTF environment:

```bash
# Navigate to the CTF directory
cd /path/to/Redis_RDI_CTF

# Start all services
./start_ctf.sh

# Verify services are running
docker ps | grep rdi-ctf
```

### 1.2 Verify Database Content

Connect to PostgreSQL to explore the music database:

```bash
# Connect to PostgreSQL
docker exec -it rdi-ctf-postgres psql -U postgres -d musicstore

# List tables
\dt

# Check track count
SELECT COUNT(*) FROM "Track";

# View sample tracks
SELECT "TrackId", "Name", "Artist" FROM "Track"
JOIN "Album" ON "Track"."AlbumId" = "Album"."AlbumId"
LIMIT 5;

# Exit PostgreSQL
\q
```

**🔍 Expected Result**: You should see 15 sample tracks with details like track name, album, artist, genre, and metadata.

## 🔧 Step 2: Configure Redis RDI

### 2.1 Set Up Redis Cloud Connection

First, ensure you have a Redis Cloud account and database:

1. Sign up at [redis.com/try-free](https://redis.com/try-free/)
2. Create a new database
3. Get your connection details by clicking "Connect" → "Redis CLI"
4. Note the connection string format: `redis://default:password@host:port`

### 2.2 Configure RDI Pipeline

Access the RDI CLI container and configure the pipeline:

```bash
# Enter the RDI CLI container
docker exec -it rdi-ctf-cli bash

# Copy the configuration template
cp /config/config.yaml.template /config/config.yaml

# Edit the configuration with your Redis Cloud details
nano /config/config.yaml
```

Update the configuration with your Redis Cloud connection details:

```yaml
connections:
  target:
    type: redis
    host: your-redis-host.redns.redis-cloud.com
    port: your-port-number
    password: your-password
    username: default
    tls: true
    tls_skip_verify: true

  source:
    type: postgresql
    host: postgresql
    port: 5432
    database: musicstore
    user: postgres
    password: postgres
    logical_replication: true
source:
  connection: source
  tables:
    - name: "Track"
      key_pattern: "track:${TrackId}"
      columns: "*"

applier:
  batch: 100
  duration: 100
  error_handling: dlq
  target_data_type: hash

transforms:
  - name: add_uppercase_name
    type: add_field
    table: "Track"
    field: "NameUpper"
    value: "${upper(Name)}"

  - name: add_price_category
    type: add_field
    table: "Track"
    field: "PriceCategory"
    value: "${UnitPrice < 1.00 ? 'Budget' : UnitPrice < 1.50 ? 'Standard' : 'Premium'}"
```

### 2.3 Deploy and Start RDI Pipeline

Deploy the configuration and start the pipeline:

```bash
# Deploy the RDI configuration
redis-di deploy --config /config/config.yaml

# Start the pipeline
redis-di start

# Check the status
redis-di status
```

**🔍 Expected Output**: You should see the pipeline status as "running" and no errors.
## 📊 Step 3: Verify the Migration

### 3.1 Check RDI Status

Monitor your RDI pipeline:

```bash
# Check pipeline status
redis-di status

# View logs
redis-di logs

# List deployed configurations
redis-di list
```

### 3.2 Verify Data in Redis Cloud

Use Redis Insight to verify the migration:

1. **Open Redis Insight**: http://localhost:5540
2. **Add your Redis Cloud database** using your connection details
3. **Browse the data**: Look for keys with pattern `track:*`
4. **Examine a track**: Click on `track:1` to see the migrated data

**Expected Data Structure**: You should see hash data with fields like:
- `TrackId`: 1
- `Name`: "For Those About To Rock (We Salute You)"
- `NameUpper`: "FOR THOSE ABOUT TO ROCK (WE SALUTE YOU)"
- `AlbumId`: 1
- `GenreId`: 1
- `Composer`: "Angus Young, Malcolm Young, Brian Johnson"
- `PriceCategory`: "Budget"

### 3.3 Test with Load Generator

Generate new data to test the pipeline:

```bash
# Start the load generator
docker exec -it rdi-ctf-loadgen python /scripts/generate_load.py

# Let it run for 30 seconds, then stop with Ctrl+C
```

Check Redis Insight to see if new tracks appear in real-time.

## 🎯 Step 4: Capture the Flag

### 4.1 Verify Your Success

To complete this lab, verify that:

1. ✅ Your RDI pipeline is successfully deployed
2. ✅ Track data is migrated to Redis Cloud
3. ✅ Only Rock and Metal tracks are included (GenreId 1 and 2)
4. ✅ Transformed fields (NameUpper, PriceCategory) are present
5. ✅ Real-time updates are working

### 4.2 Get Your Flag

Query the PostgreSQL database for your flag:

```bash
# Connect to PostgreSQL
docker exec -it rdi-ctf-postgres psql -U postgres -d musicstore

# Get your flag
SELECT flag_value FROM ctf_flags WHERE lab_id = '01';

# Exit
\q
```

**🏁 Flag**: `RDI{pg_to_redis_snapshot_success}`

**Alternative**: Check if the flag was synced to Redis:
```bash
# In Redis Insight, look for key: flag:01
# Or use Redis CLI in your Redis Cloud instance:
GET flag:01
```

## 🧠 Key Concepts Learned

1. **Snapshot Migration**: How to perform one-time data migration from PostgreSQL to Redis
2. **Data Transformation**: Adding computed fields and applying business logic during migration
3. **Filtering**: Selectively migrating data based on conditions
4. **RDI Configuration**: Setting up sources, targets, and transformation jobs
5. **Real-time Sync**: Understanding how RDI can handle ongoing data changes

## 🔧 Troubleshooting

### Common Issues:

1. **RDI Connection Failed**:
   - Verify Redis Cloud connection details in config.yaml
   - Check if TLS is properly configured
   - Test Redis connection manually: `redis-cli -u your-redis-url ping`

2. **No Data in Redis**:
   - Check RDI pipeline status: `redis-di status`
   - Review RDI logs: `redis-di logs`
   - Verify PostgreSQL connection from RDI container

3. **Configuration Errors**:
   - Validate YAML syntax in config.yaml
   - Check table names match exactly (case-sensitive)
   - Ensure all required fields are present

4. **Container Issues**:
   - Restart containers: `docker-compose restart`
   - Check container logs: `docker logs rdi-ctf-cli`
   - Verify all containers are running: `docker ps`

## 🎉 Congratulations!

You've successfully completed Lab 01! You've learned how to:
- Set up an RDI pipeline for PostgreSQL to Redis migration
- Apply transformations and filters during data ingestion
- Verify data migration and handle real-time updates

**Next**: Proceed to [Lab 02: Snapshot vs CDC](../02_snapshot_vs_cdc/README.md) to learn about Change Data Capture!
