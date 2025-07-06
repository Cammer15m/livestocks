# Lab 02: Snapshot vs CDC

This lab demonstrates the key difference between **Snapshot** and **Change Data Capture (CDC)** modes in Redis Data Integration.

## Learning Objectives
- Understand snapshot mode: one-time data copy
- Understand CDC mode: continuous replication of changes
- Observe how CDC captures live database updates

## Prerequisites
- Complete Lab 01 first
- Ensure all services are running: `docker-compose up -d`

## Part A: Review Snapshot Mode (from Lab 1)

1. **Verify existing snapshot data**:
   ```sh
   redis-cli KEYS "user:*"
   redis-cli HGETALL user:1
   redis-cli HGETALL user:2
   ```

2. **Add new data to PostgreSQL**:
   ```sh
   docker exec -i postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c \
     "INSERT INTO users (name, email) VALUES ('Charlie', 'charlie@example.com');"
   ```

3. **Check Redis - new data NOT replicated**:
   ```sh
   redis-cli KEYS "user:*"  # Should still only show user:1 and user:2
   ```

   **Key Point**: Snapshot mode only copies data once. New changes are ignored.

## Part B: Configure CDC Mode

1. **Set up CDC connector**:
   ```sh
   redis-cli -p 6379 \
     JSON.SET streams:pg_cdc . '{
       "connector": "postgres",
       "uri": "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@postgres:5432/$POSTGRES_DB",
       "table": "users",
       "mode": "cdc",
       "keyPrefix": "cdc_user:",
       "streamName": "user_changes"
     }'
   ```

2. **Verify CDC connector configuration**:
   ```sh
   redis-cli JSON.GET streams:pg_cdc
   ```

## Part C: Test CDC Live Updates

1. **Monitor the CDC stream** (open in separate terminal):
   ```sh
   redis-cli XREAD BLOCK 0 STREAMS user_changes $
   ```

2. **Insert new user in PostgreSQL**:
   ```sh
   docker exec -i postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c \
     "INSERT INTO users (name, email) VALUES ('Diana', 'diana@example.com');"
   ```

3. **Update existing user**:
   ```sh
   docker exec -i postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c \
     "UPDATE users SET email = 'alice.updated@example.com' WHERE name = 'Alice';"
   ```

4. **Check CDC captured changes**:
   ```sh
   redis-cli XRANGE user_changes - +
   redis-cli KEYS "cdc_user:*"
   redis-cli HGETALL cdc_user:4  # Diana's record
   ```

## Part D: Compare Results

1. **Snapshot data** (static):
   ```sh
   redis-cli KEYS "user:*"      # Only original users
   ```

2. **CDC data** (live):
   ```sh
   redis-cli KEYS "cdc_user:*"  # Includes all changes
   redis-cli XLEN user_changes  # Number of change events
   ```

## Part E: Retrieve Lab Flag

1. **Inject flags** (simulates CDC detection):
   ```sh
   redis-cli EVAL "$(cat ../../flags/flag_injector.lua)" 0
   ```

2. **Get Lab 2 flag**:
   ```sh
   redis-cli GET flag:02  # Should return RDI{snapshot_vs_cdc_detected}
   ```

## Summary

| Mode | Behavior | Use Case |
|------|----------|----------|
| **Snapshot** | One-time copy | Initial data migration, reporting |
| **CDC** | Continuous sync | Real-time replication, live dashboards |

**Key Insight**: CDC mode enables real-time data synchronization by capturing and replicating database changes as they happen, while snapshot mode provides a point-in-time copy.
