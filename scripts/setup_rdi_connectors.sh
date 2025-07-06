#!/usr/bin/env bash
set -e

echo "Setting up RDI connectors..."

# Lab 1 snapshot
redis-cli -p 6379 JSON.SET connector:lab1 . '{
  "connector": "postgres",
  "uri": "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@postgres:5432/$POSTGRES_DB",
  "table": "users",
  "mode": "snapshot",
  "keyPrefix": "user:"
}'

# Lab 2 CDC connector
redis-cli -p 6379 JSON.SET streams:pg_cdc . '{
  "connector": "postgres",
  "uri": "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@postgres:5432/$POSTGRES_DB",
  "table": "users",
  "mode": "cdc",
  "keyPrefix": "cdc_user:",
  "streamName": "user_changes"
}'

# Lab 3 Advanced RDI pipelines
redis-cli -p 6379 JSON.SET rdi:pipeline:orders . '{
  "source": {
    "type": "postgresql",
    "connection": "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@postgres:5432/$POSTGRES_DB",
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

redis-cli -p 6379 JSON.SET rdi:pipeline:profiles . '{
  "source": {
    "type": "postgresql",
    "connection": "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@postgres:5432/$POSTGRES_DB",
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

echo "Connectors configured."
