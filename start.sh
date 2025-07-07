#!/bin/bash

# Redis RDI Training Environment Startup Script
# Supports both local Redis Enterprise and Redis Cloud

set -e

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

# Progress bar functions
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))  # 20 chars max width for bar
    local empty=$((20 - filled))

    printf "\r\033[K"  # Clear line
    printf "[%3d%%] [" $percent
    printf "%*s" $filled | tr ' ' '='
    printf "%*s" $empty | tr ' ' '-'
    printf "] %s" "$message"
}

complete_step() {
    local step=$1
    local message=$2
    printf "\r\033[K[DONE] [%d/10] %s\n" $step "$message"
}

echo ""
echo "Starting Redis RDI Training Environment..."
echo "This will take approximately 3-5 minutes"
echo ""

# Step 1: Prepare environment
show_progress 1 10 "Preparing environment..."
sleep 1
sudo chmod -R 777 grafana/ 2>/dev/null || chmod -R 777 grafana/ 2>/dev/null || true

complete_step 1 "Environment prepared"

# Step 2: Configure services
show_progress 2 10 "Configuring services..."
sleep 1
export HOSTNAME=$(hostname -s)
export PASSWORD=$PASSWORD
export HOST_IP=$(hostname -I | awk '{print $1}')
export RDI_VERSION=1.10.0
export RE_USER=admin@rl.org

envsubst < ./grafana_config/grafana.ini.template > ./grafana_config/grafana.ini 2>/dev/null || true
envsubst < ./prometheus/prometheus.yml.template > ./prometheus/prometheus.yml 2>/dev/null || true
complete_step 2 "Services configured"

# Step 3: Starting Docker containers
show_progress 3 10 "Starting Docker containers (using pre-built images)..."

#Total hack.  There are instances where /snap/bin is not ready before docker-compose leading to error
#So sleep a little.

while [ ! -x /snap/bin ]; do
    sleep 5
done

echo ""
echo "Step 3a: Starting pre-built containers..."
# Start containers that don't need building first
docker-compose up -d grafana docs prometheus redis-insight-2 dozzle postgresql postgres-exporter sqlpad

echo "Step 3b: Starting Redis Enterprise (using official image)..."
docker-compose up -d re-n1

echo "Step 3c: Building remaining containers..."
docker-compose up -d --build app loadgen

echo "Step 3d: Final container startup..."
docker-compose up -d

# Final health check
echo "Checking container health..."
sleep 5
RUNNING_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -c "Up")
echo "  - $RUNNING_CONTAINERS containers are running"

complete_step 3 "Docker containers started ($RUNNING_CONTAINERS running)"

# Step 4: Configuring Redis Enterprise
show_progress 4 10 "Configuring Redis Enterprise..."
sleep 1

main_nodes=( re-n1 )
all_nodes=( re-n1 )
ssh_nodes=( re-n1 )

for i in "${all_nodes[@]}"
do
   #wait for admin port
   docker cp wait-for-code.sh $i:/tmp/wait-for-code.sh
   docker exec -e URL=https://$i:9443/v1/bootstrap -e CODE=200 $i /bin/bash /tmp/wait-for-code.sh

   #enable port 53
   docker exec --user root --privileged $i /bin/bash /tmp/init_script.sh
done

#create cluster 1
export CLUSTER=re-cluster1.ps-redislabs.org
export IP=172.16.22.21
server="re-n1"

cluster_file="redis/create_cluster.json.template"

envsubst < $cluster_file > create_cluster.json
docker cp create_cluster.json $server:/tmp/create_cluster.json
docker exec $server curl -k -v --silent --fail -H 'Content-Type: application/json' -d @/tmp/create_cluster.json  https://$server:9443/v1/bootstrap/create_cluster

#wait for admin port
docker cp wait-for-code.sh $server:/tmp/wait-for-code.sh
docker exec -e URL=https://$server:9443/v1/bootstrap -e CODE=200 $server /bin/bash /tmp/wait-for-code.sh

complete_step 4 "Redis Enterprise configured"

# Step 5: Updating license and finalizing setup
show_progress 5 10 "Updating license and finalizing setup..."
sleep 1

#update license
if [[ -n $RE1_LICENSE ]];
then
   docker exec re-n1 curl -v -k -d "{\"license\": \"$(echo $RE1_LICENSE | sed -z 's/\n/\\n/g')\"}" -u $RE_USER:$PASSWORD -H "Content-Type: application/json" -X PUT https://localhost:9443/v1/license
fi

sleep 20
docker-compose up -d
sleep 20

complete_step 5 "License updated and setup finalized"

# Step 6: Configuring Grafana
show_progress 6 10 "Configuring Grafana dashboards..."
sleep 1

#configure Grafana
cd grafana
bash config_grafana.sh
cd ..

complete_step 6 "Grafana dashboards configured"

# Step 7: Starting terminal services
show_progress 7 10 "Starting terminal services..."
sleep 1

#export GRAFANA_VERSION=$(docker exec grafana grafana server -v | grep -oP 'Version \K[^\s]+')
#export RE_VERSION=$(docker exec re-n1 bash -c "curl -u $RE_USER:$PASSWORD https://localhost:9443/v1/nodes -k --fail | jq '.'" | grep software_version | uniq | awk -F ":" '{print $2}' | awk -F '\"' '{print $2}')

#export HOST_IP=$(hostname -I | awk '{print $1}')
#export REDIS_INSIGHT_VERSION=2.64


#create instructions
#cd about
#bash create_about.sh
#cd ..

#nohup npm run dev &

echo '----------------------------------'
echo "Starting ttyd with labuser on port 7681..."

sudo -u labuser nohup ttyd -W -p 7681 -t disableLeaveAlert=true -t fontSize=14 -t 'cursorStyle=bar' --client-option reconnect=true bash -c "cd /home/labuser && exec bash" &

echo '----------------------------------'

complete_step 7 "Terminal services started"

# Step 8: Final setup completion
show_progress 8 10 "Completing final setup..."
sleep 2
complete_step 8 "Setup completed successfully"

echo ""
echo "[SUCCESS] Redis RDI Training Environment is ready!"
echo ""

wait $!
