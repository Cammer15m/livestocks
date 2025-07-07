#!/bin/bash

# Redis RDI Training Environment Startup Script
# Supports both local Redis Enterprise and Redis Cloud

# ---------------------------------------------------------------------------
# Set defaults if not provided
[ -z "$DOMAIN" ] && export DOMAIN=localhost
[ -z "$PASSWORD" ] && export PASSWORD=redislabs

echo "=========================================="
echo "Redis RDI Training Environment"
echo "=========================================="
echo ""

# Redis Cloud Configuration
echo "Redis Cloud Setup (Optional):"
echo "If you want to use Redis Cloud instead of local Redis Enterprise,"
echo "please provide your Redis Cloud connection details."
echo ""
read -p "Do you want to configure Redis Cloud? (y/N): " use_redis_cloud

if [[ "$use_redis_cloud" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Please provide your Redis Cloud connection string:"
    echo "Format: redis://default:password@host:port"
    echo "You can find this in your Redis Cloud dashboard under 'Connect'"
    echo ""
    read -p "Redis Cloud connection string: " redis_cloud_url

    if [[ -n "$redis_cloud_url" ]]; then
        echo "Testing Redis Cloud connection..."
        # Parse the connection string
        if [[ "$redis_cloud_url" =~ redis://([^:]+):([^@]+)@([^:]+):([0-9]+) ]]; then
            export REDIS_CLOUD_USER="${BASH_REMATCH[1]}"
            export REDIS_CLOUD_PASSWORD="${BASH_REMATCH[2]}"
            export REDIS_CLOUD_HOST="${BASH_REMATCH[3]}"
            export REDIS_CLOUD_PORT="${BASH_REMATCH[4]}"
            export REDIS_CLOUD_URL="$redis_cloud_url"

            echo "[SUCCESS] Redis Cloud configuration saved"
            echo "   Host: $REDIS_CLOUD_HOST:$REDIS_CLOUD_PORT"
            echo "   User: $REDIS_CLOUD_USER"
            echo ""
        else
            echo "[ERROR] Invalid Redis Cloud URL format"
            echo "Expected format: redis://default:password@host:port"
            exit 1
        fi
    fi
fi

echo ""
echo "Starting Redis RDI Training Environment..."
echo ""

sudo chmod -R 777 grafana/ 2>/dev/null || chmod -R 777 grafana/ 2>/dev/null || true

export HOSTNAME=$(hostname -s)
export PASSWORD=$PASSWORD
export HOST_IP=$(hostname -I | awk '{print $1}')
export RDI_VERSION=1.10.0
export RE_USER=admin@rl.org

envsubst < ./grafana_config/grafana.ini.template > ./grafana_config/grafana.ini 2>/dev/null || true
envsubst < ./prometheus/prometheus.yml.template > ./prometheus/prometheus.yml 2>/dev/null || true

#Total hack.  There are instances where /snap/bin is not ready before docker-compose leading to error
#So sleep a little.

while [ ! -x /snap/bin ]; do
    sleep 5
done

echo "Starting Docker containers..."
docker-compose up -d --build

echo ""
echo "Waiting for containers to start..."
sleep 10

# Simple progress check
EXPECTED_CONTAINERS=10
TIMEOUT=300  # 5 minutes
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    RUNNING=$(docker ps | grep -c "Up" || echo "0")
    echo "[$ELAPSED s] $RUNNING/$EXPECTED_CONTAINERS containers running..."

    if [ $RUNNING -ge $EXPECTED_CONTAINERS ]; then
        echo "✓ All containers are running!"
        break
    fi

    sleep 15
    ELAPSED=$((ELAPSED + 15))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "⚠ Warning: Not all containers started within 5 minutes"
    echo "Current status:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    echo ""
    echo "You can check logs with: docker-compose logs"
fi

echo ""
echo "Configuring Redis Enterprise cluster..."

main_nodes=( re-n1 )
all_nodes=( re-n1 )
ssh_nodes=( re-n1 )

for i in "${all_nodes[@]}"
do
   echo "  - Waiting for $i admin port to be ready..."
   #wait for admin port
   docker cp wait-for-code.sh $i:/tmp/wait-for-code.sh
   docker exec -e URL=https://$i:9443/v1/bootstrap -e CODE=200 $i /bin/bash /tmp/wait-for-code.sh
   echo "  ✓ $i admin port is ready"

   echo "  - Enabling DNS on $i..."
   #enable port 53
   docker exec --user root --privileged $i /bin/bash /tmp/init_script.sh
   echo "  ✓ DNS enabled on $i"
done

echo ""
echo "Creating Redis Enterprise cluster..."

#create cluster 1
export CLUSTER=re-cluster1.ps-redislabs.org
export IP=172.16.22.21
server="re-n1"

cluster_file="redis/create_cluster.json.template"

echo "  - Generating cluster configuration..."
envsubst < $cluster_file > create_cluster.json
docker cp create_cluster.json $server:/tmp/create_cluster.json

echo "  - Creating cluster (this may take 2-3 minutes)..."
docker exec $server curl -k -v --silent --fail -H 'Content-Type: application/json' -d @/tmp/create_cluster.json  https://$server:9443/v1/bootstrap/create_cluster
echo "  ✓ Cluster creation initiated"

echo "  - Waiting for cluster to be ready..."
#wait for admin port
docker cp wait-for-code.sh $server:/tmp/wait-for-code.sh
docker exec -e URL=https://$server:9443/v1/bootstrap -e CODE=200 $server /bin/bash /tmp/wait-for-code.sh
echo "  ✓ Cluster is ready"

echo ""
echo "Finalizing setup..."

#update license
if [[ -n $RE1_LICENSE ]]; then
   echo "  - Updating Redis Enterprise license..."
   docker exec re-n1 curl -v -k -d "{\"license\": \"$(echo $RE1_LICENSE | sed -z 's/\n/\\n/g')\"}" -u $RE_USER:$PASSWORD -H "Content-Type: application/json" -X PUT https://localhost:9443/v1/license
   echo "  ✓ License updated"
fi

echo "  - Starting remaining services..."
sleep 20
docker-compose up -d
sleep 20
echo "  ✓ All services started"

echo "  - Configuring Grafana dashboards..."
#configure Grafana
cd grafana
bash config_grafana.sh
cd ..
echo "  ✓ Grafana configured"

echo "  - Starting terminal service..."
sudo -u labuser nohup ttyd -W -p 7681 -t disableLeaveAlert=true -t fontSize=14 -t 'cursorStyle=bar' --client-option reconnect=true bash -c "cd /home/labuser && exec bash" &
echo "  ✓ Terminal service started on port 7681"

echo ""
echo "=========================================="
echo "✅ Redis RDI Training Environment Ready!"
echo "=========================================="
echo ""
echo "Services available:"
echo "  • Redis Enterprise: https://localhost:8443 (admin@rl.org / redislabs)"
echo "  • Redis Insight: http://localhost:5540"
echo "  • Grafana: http://localhost:3000 (admin / redislabs)"
echo "  • SQLPad: http://localhost:3001 (admin@rl.org / redislabs)"
echo "  • Terminal: http://localhost:7681"
echo ""

# Final health check
FINAL_RUNNING=$(docker ps | grep -c "Up" || echo "0")
echo "Status: $FINAL_RUNNING containers running"
if [ $FINAL_RUNNING -lt 8 ]; then
    echo "⚠ Warning: Some containers may not be running properly"
    echo "Run 'docker ps' to check container status"
fi

wait $!
