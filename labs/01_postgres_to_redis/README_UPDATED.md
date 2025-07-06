# Lab 1: PostgreSQL to Redis Basic Sync 🎵

**Objective**: Learn how Redis Data Integration (RDI) synchronizes data from PostgreSQL to Redis in real-time.

## 🎯 What You'll Learn
- How RDI connects PostgreSQL and Redis
- Real-time data synchronization
- Redis data structures (Hashes, Sets)
- Basic monitoring and verification

## 📋 Prerequisites
- All services running (PostgreSQL, Redis, RDI)
- RDI connector active
- Basic understanding of databases

## 🚀 Lab Steps

### Step 1: Verify Initial Setup
Check that all services are running:

```bash
# Check Docker services
docker ps

# Verify PostgreSQL connection
psql -U postgres -d chinook -h localhost -c "SELECT COUNT(*) FROM \"Track\";"

# Verify Redis connection  
redis-cli ping
```

**Expected**: All services should be healthy and responding.

### Step 2: Start RDI Connector
Start the RDI connector to begin synchronization:

```bash
cd scripts
python3 rdi_connector.py
```

**What happens**: The connector reads all existing tracks from PostgreSQL and syncs them to Redis.

### Step 3: Verify Data in Redis
Check that tracks are now in Redis:

```bash
# Count tracks in Redis
redis-cli SCARD tracks

# View a specific track
redis-cli HGETALL track:1

# List first 10 track IDs
redis-cli SMEMBERS tracks | head -10
```

**Expected**: You should see the same number of tracks in Redis as PostgreSQL.

### Step 4: Test Real-time Sync
Generate new data and watch it sync:

```bash
# In a new terminal, start the load generator
cd scripts
python3 generate_load.py
```

**Watch**: The RDI connector should immediately detect and sync new tracks.

### Step 5: Monitor via Web Interface
Open the RDI web interface:

```bash
# Open in browser
open http://localhost:8080
```

**Observe**: Real-time statistics showing PostgreSQL vs Redis track counts.

### Step 6: Explore with RedisInsight
Use RedisInsight for visual exploration:

```bash
# Open RedisInsight
open http://localhost:5540
```

**Tasks**:
1. Connect to Redis (localhost:6379)
2. Browse the `tracks` set
3. Examine track hash structures
4. Watch new data appear in real-time

## 🏁 Lab Completion

### Find the Flag
The first flag is hidden in the Redis data. Look for a track with a special name pattern.

**Hint**: Check track names for anything that looks like `RDI{...}`

```bash
# Search for the flag
redis-cli --scan --pattern "track:*" | xargs -I {} redis-cli HGET {} Name | grep "RDI{"
```

### Verification
Once you find the flag, verify your completion:

```bash
cd scripts
python3 check_flags.py
```

**Expected Flag**: `RDI{pg_to_redis_success}`

## 🎓 Key Concepts Learned

1. **Data Synchronization**: How RDI maintains consistency between PostgreSQL and Redis
2. **Redis Data Structures**: Using hashes for structured data and sets for indexing
3. **Real-time Updates**: Continuous monitoring and immediate sync of new data
4. **Monitoring**: Using web interfaces and CLI tools to verify sync status

## 🔧 Troubleshooting

**RDI Connector Not Starting**:
- Check PostgreSQL and Redis are running
- Verify connection credentials
- Check Python dependencies are installed

**Data Not Syncing**:
- Restart the RDI connector
- Check for error messages in connector output
- Verify database permissions

**Can't Find Flag**:
- Make sure RDI connector has been running
- Check that all tracks are synced
- Use RedisInsight to browse data visually

## ➡️ Next Steps

Ready for Lab 2? Learn about **Snapshot vs CDC** patterns and advanced synchronization modes!

```bash
cd ../02_snapshot_vs_cdc
cat README.md
```

---

**🎉 Congratulations!** You've successfully set up basic PostgreSQL to Redis data integration!
