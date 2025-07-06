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

First, let's start our local PostgreSQL database with the music data:

```bash
# Navigate to the CTF directory
cd /path/to/Redis_RDI_CTF

# Start the infrastructure
docker-compose up -d postgres sqlpad redisinsight

# Verify services are running
docker-compose ps
```

### 1.2 Verify Database Content

Open SQLPad in your browser at `http://localhost:3001` and login with:
- **Username**: `admin@ctf.local`
- **Password**: `ctfpassword`

Run this query to explore the music database:

```sql
-- Check the Track table structure and data
SELECT
    t."TrackId",
    t."Name",
    a."Title" as "Album",
    a."Artist",
    g."Name" as "Genre",
    t."Composer",
    t."Milliseconds",
    t."UnitPrice"
FROM "Track" t
JOIN "Album" a ON t."AlbumId" = a."AlbumId"
JOIN "Genre" g ON t."GenreId" = g."GenreId"
ORDER BY t."TrackId"
LIMIT 10;
```

**🔍 What you should see**: A list of music tracks with details like track name, album, artist, genre, and other metadata.

## 🔧 Step 2: Configure Redis RDI

### 2.1 Access Your Redis Cloud RDI Instance

1. Log into your Redis Cloud console
2. Navigate to your RDI-enabled database
3. Open the RDI configuration interface

### 2.2 Create the RDI Pipeline Configuration

In the RDI configuration interface, create a new pipeline with this configuration:

```yaml
# config.yaml
targets:
  target:
    connection:
      type: redis
      host: <your-redis-cloud-endpoint>
      port: <your-redis-port>
      password: <your-redis-password>
      # Add SSL configuration if required
      ssl: true

sources:
  postgres_music:
    type: cdc
    logging:
      level: info
    connection:
      type: postgresql
      host: <your-public-ip>  # Your machine's public IP
      port: 5432
      database: chinook
      user: postgres
      password: postgres
```

**💡 Important Notes**:
- Replace `<your-redis-cloud-endpoint>`, `<your-redis-port>`, and `<your-redis-password>` with your actual Redis Cloud details
- Replace `<your-public-ip>` with your machine's public IP address (you can find this by running `curl ifconfig.me`)
- Ensure your firewall allows connections on port 5432

### 2.3 Create the Job Configuration

Create a job to migrate track data with transformations:

```yaml
# jobs/track_migration.yaml
source:
  table: Track

transform:
  # Add a new field with uppercase track name
  - uses: add_field
    with:
      field: NameUpper
      expression: upper("Name")
      language: sql

  # Filter to only include Rock and Metal tracks (GenreId 1 and 2)
  - uses: filter
    with:
      expression: "GenreId" IN (1, 2)
      language: sql

  # Add a price category field
  - uses: add_field
    with:
      field: PriceCategory
      expression: |
        CASE
          WHEN "UnitPrice" < 1.00 THEN 'Budget'
          WHEN "UnitPrice" < 1.50 THEN 'Standard'
          ELSE 'Premium'
        END
      language: sql

output:
  - uses: redis.write
    with:
      connection: target
      key:
        expression: concat('track:', "TrackId")
        language: sql
      value:
        expression: to_json(.)
        language: sql
```

## 📊 Step 3: Deploy and Test the Pipeline

### 3.1 Deploy the Pipeline

1. In the RDI interface, deploy your pipeline
2. Monitor the deployment status
3. Check for any configuration errors

### 3.2 Verify the Migration

Once deployed, verify that data is being migrated:

1. **Check Redis Cloud**: Use RedisInsight or the Redis CLI to verify data:
   ```bash
   # Connect to your Redis Cloud instance
   redis-cli -h <your-endpoint> -p <your-port> -a <your-password>

   # Check for migrated tracks
   KEYS track:*

   # Examine a specific track
   JSON.GET track:1
   ```

2. **Expected Output**: You should see JSON objects with track data including the new fields:
   ```json
   {
     "TrackId": 1,
     "Name": "For Those About To Rock (We Salute You)",
     "NameUpper": "FOR THOSE ABOUT TO ROCK (WE SALUTE YOU)",
     "AlbumId": 1,
     "GenreId": 1,
     "Composer": "Angus Young, Malcolm Young, Brian Johnson",
     "Milliseconds": 343719,
     "Bytes": 11170334,
     "UnitPrice": 0.99,
     "PriceCategory": "Budget"
   }
   ```

### 3.3 Test Real-time Updates

Generate some new data to test real-time synchronization:

```bash
# Run the load generator to add new tracks
docker-compose exec loadgen python generate_load.py --batch 5
```

Check if the new tracks appear in Redis Cloud (only Rock/Metal tracks should appear due to our filter).

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

```sql
-- In SQLPad, run this query:
SELECT flag_value FROM ctf_flags WHERE lab_id = '01';
```

**🏁 Flag**: `RDI{pg_to_redis_snapshot_success}`

## 🧠 Key Concepts Learned

1. **Snapshot Migration**: How to perform one-time data migration from PostgreSQL to Redis
2. **Data Transformation**: Adding computed fields and applying business logic during migration
3. **Filtering**: Selectively migrating data based on conditions
4. **RDI Configuration**: Setting up sources, targets, and transformation jobs
5. **Real-time Sync**: Understanding how RDI can handle ongoing data changes

## 🔧 Troubleshooting

### Common Issues:

1. **Connection Failed**:
   - Verify your public IP address
   - Check firewall settings for port 5432
   - Ensure PostgreSQL is accepting external connections

2. **No Data in Redis**:
   - Check RDI pipeline status
   - Verify filter conditions aren't too restrictive
   - Review RDI logs for errors

3. **Transformation Errors**:
   - Validate SQL syntax in transformation expressions
   - Check data types and field names
   - Test transformations with sample data

## 🎉 Congratulations!

You've successfully completed Lab 01! You've learned how to:
- Set up an RDI pipeline for PostgreSQL to Redis migration
- Apply transformations and filters during data ingestion
- Verify data migration and handle real-time updates

**Next**: Proceed to [Lab 02: Snapshot vs CDC](../02_snapshot_vs_cdc/README.md) to learn about Change Data Capture!
