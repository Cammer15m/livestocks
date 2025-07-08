#!/bin/bash 

# ---------------------------
# Redis Enterprise Bootstrap Script
# For RDI Lab Automation
# ---------------------------

# Configurable Variables
CLUSTER_NAME="cluster.local"
ADMIN_USER="admin@rl.org"
ADMIN_PASS="redislabs"
DB_NAME="rdi-db"
DB_PORT=12001
DB_PASS="redislabs"
COOKIE_FILE="/tmp/cookie.txt"

echo "🔧 Creating Redis Enterprise Cluster..."
/opt/redislabs/bin/rladmin cluster create name $CLUSTER_NAME username $ADMIN_USER password $ADMIN_PASS

echo "⏳ Waiting for cluster to be fully ready..."
sleep 10

echo "🔐 Authenticating and retrieving session cookie..."
curl -sk -X POST https://localhost:9443/v1/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$ADMIN_USER\", \"password\":\"$ADMIN_PASS\"}" \
  -c $COOKIE_FILE

echo "🧪 Creating RDI-compatible database: $DB_NAME..."
curl -sk -X POST https://localhost:9443/v1/bdbs \
  -H "Content-Type: application/json" \
  -b $COOKIE_FILE \
  -d "{
    \"name\": \"$DB_NAME\",
    \"type\": \"redis\",
    \"memory_size\": 268435456,
    \"port\": $DB_PORT,
    \"oss_cluster\": false,
    \"replication\": true,
    \"sharding\": false,
    \"data_persistence\": \"aof_every_write\",
    \"authentication_redis_pass\": \"$DB_PASS\",
    \"roles\": [\"active\"],
    \"rdi\": {
      \"enabled\": true,
      \"source\": true
    }
  }"

echo "✅ Done! DB '$DB_NAME' created and ready for RDI."

# Test the database connection
echo "🧪 Testing database connection..."
sleep 5
redis-cli -h localhost -p $DB_PORT -a $DB_PASS ping

echo "🎉 Redis Enterprise setup complete!"
