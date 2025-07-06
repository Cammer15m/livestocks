# Lab 03: Advanced RDI Features

This lab demonstrates advanced **Redis Data Integration** capabilities including data transformations, multiple table replication, and monitoring.

## Learning Objectives
- Configure data transformations in RDI pipelines
- Set up multiple table replication
- Monitor RDI pipeline performance
- Understand advanced RDI configuration patterns

## Prerequisites
- Complete Labs 01 and 02
- Redis Cloud instance with RDI enabled
- Local PostgreSQL with sample data
- RedisInsight for monitoring

## Part A: Set Up Advanced Schema

1. **Create additional tables in PostgreSQL**:
   ```sql
   -- Connect to your local PostgreSQL
   psql -U rdi_user -d rdi_db -h localhost

   -- Create orders table
   CREATE TABLE orders (
       id SERIAL PRIMARY KEY,
       user_id INTEGER REFERENCES users(id),
       product_name VARCHAR(100),
       quantity INTEGER,
       price DECIMAL(10,2),
       order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );

   -- Create user_profiles table
   CREATE TABLE user_profiles (
       user_id INTEGER PRIMARY KEY REFERENCES users(id),
       first_name VARCHAR(50),
       last_name VARCHAR(50),
       age INTEGER,
       city VARCHAR(50),
       country VARCHAR(50)
   );
   ```

2. **Insert sample data**:
   ```sql
   -- Add sample orders
   INSERT INTO orders (user_id, product_name, quantity, price) VALUES
   (1, 'Laptop', 1, 999.99),
   (2, 'Mouse', 2, 25.50),
   (1, 'Keyboard', 1, 75.00);

   -- Add user profiles
   INSERT INTO user_profiles (user_id, first_name, last_name, age, city, country) VALUES
   (1, 'Alice', 'Johnson', 28, 'New York', 'USA'),
   (2, 'Bob', 'Smith', 35, 'London', 'UK');
   ```

## Part B: Configure Multi-Table RDI Pipeline

1. **Set up RDI pipeline for multiple tables**:
   ```bash
   # Load environment variables
   source ../../.env

   # Configure RDI pipeline for orders table
   redis-cli -u "$REDIS_URL" \
     JSON.SET rdi:pipeline:orders . '{
       "source": {
         "type": "postgresql",
         "connection": "postgres://rdi_user:rdi_password@localhost:5432/rdi_db",
         "table": "orders"
       },
       "target": {
         "type": "redis",
         "key_pattern": "order:{id}",
         "data_type": "hash"
       },
       "transformations": {
         "total_value": "quantity * price",
         "order_status": "pending"
       }
     }'
   ```

2. **Configure user profiles pipeline**:
   ```bash
   # Configure RDI pipeline for user_profiles table
   redis-cli -u "$REDIS_URL" \
     JSON.SET rdi:pipeline:profiles . '{
       "source": {
         "type": "postgresql",
         "connection": "postgres://rdi_user:rdi_password@localhost:5432/rdi_db",
         "table": "user_profiles"
       },
       "target": {
         "type": "redis",
         "key_pattern": "profile:{user_id}",
         "data_type": "hash"
       },
       "transformations": {
         "full_name": "first_name || \" \" || last_name",
         "location": "city || \", \" || country"
       }
     }'
   ```

## Part C: Test Data Transformations

1. **Simulate RDI data processing**:
   ```bash
   # Simulate processing orders with transformations
   redis-cli -u "$REDIS_URL" HSET order:1 \
     id 1 \
     user_id 1 \
     product_name "Laptop" \
     quantity 1 \
     price 999.99 \
     total_value 999.99 \
     order_status "pending"

   redis-cli -u "$REDIS_URL" HSET order:2 \
     id 2 \
     user_id 2 \
     product_name "Mouse" \
     quantity 2 \
     price 25.50 \
     total_value 51.00 \
     order_status "pending"
   ```

2. **Simulate processing user profiles with transformations**:
   ```bash
   # Process user profiles with computed fields
   redis-cli -u "$REDIS_URL" HSET profile:1 \
     user_id 1 \
     first_name "Alice" \
     last_name "Johnson" \
     age 28 \
     city "New York" \
     country "USA" \
     full_name "Alice Johnson" \
     location "New York, USA"

   redis-cli -u "$REDIS_URL" HSET profile:2 \
     user_id 2 \
     first_name "Bob" \
     last_name "Smith" \
     age 35 \
     city "London" \
     country "UK" \
     full_name "Bob Smith" \
     location "London, UK"
   ```

## Part D: Advanced RDI Monitoring

1. **Monitor pipeline performance**:
   ```bash
   # Check pipeline configurations
   redis-cli -u "$REDIS_URL" JSON.GET rdi:pipeline:orders
   redis-cli -u "$REDIS_URL" JSON.GET rdi:pipeline:profiles

   # Monitor data flow metrics (simulated)
   redis-cli -u "$REDIS_URL" HSET rdi:metrics:orders \
     records_processed 3 \
     last_sync "2025-07-03T12:00:00Z" \
     status "active"

   redis-cli -u "$REDIS_URL" HSET rdi:metrics:profiles \
     records_processed 2 \
     last_sync "2025-07-03T12:00:00Z" \
     status "active"
   ```

2. **Verify data relationships**:
   ```bash
   # Check that related data is properly linked
   echo "User 1 profile:"
   redis-cli -u "$REDIS_URL" HGETALL profile:1

   echo "User 1 orders:"
   redis-cli -u "$REDIS_URL" KEYS "order:*" | while read key; do
     user_id=$(redis-cli -u "$REDIS_URL" HGET "$key" user_id)
     if [ "$user_id" = "1" ]; then
       echo "Order: $key"
       redis-cli -u "$REDIS_URL" HGETALL "$key"
     fi
   done
   ```

## Part E: Retrieve Lab Flag

1. **Inject flags using Redis Cloud**:
   ```bash
   redis-cli -u "$REDIS_URL" EVAL "$(cat ../../flags/flag_injector.lua)" 0
   ```

2. **Get Lab 3 flag**:
   ```bash
   redis-cli -u "$REDIS_URL" GET flag:03  # Should return RDI{advanced_features_mastered}
   ```

3. **Explore in RedisInsight**:
   - Open RedisInsight and connect to your Redis Cloud instance
   - Browse the advanced data structures: `order:*`, `profile:*`
   - Examine the RDI pipeline configurations: `rdi:pipeline:*`
   - View the monitoring metrics: `rdi:metrics:*`

## Part F: Cleanup (Optional)

1. **Clean up test data**:
   ```bash
   # Remove test data (optional)
   redis-cli -u "$REDIS_URL" DEL $(redis-cli -u "$REDIS_URL" KEYS "order:*")
   redis-cli -u "$REDIS_URL" DEL $(redis-cli -u "$REDIS_URL" KEYS "profile:*")
   redis-cli -u "$REDIS_URL" DEL $(redis-cli -u "$REDIS_URL" KEYS "rdi:*")
   ```

## Summary

This lab demonstrated:
- **Multi-table Replication**: Synchronizing multiple PostgreSQL tables to Redis
- **Data Transformations**: Computing derived fields during replication
- **Pipeline Configuration**: Setting up complex RDI workflows
- **Performance Monitoring**: Tracking RDI pipeline metrics
- **Data Relationships**: Maintaining referential integrity across Redis structures

**Key Insight**: Advanced RDI features enable sophisticated data integration patterns with real-time transformations, making Redis a powerful operational data store for modern applications.
