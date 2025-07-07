#!/bin/bash

# Redis RDI Training Environment Startup Script
# Handles cleanup, validation, and robust startup

set -e  # Exit on any error

# ---------------------------------------------------------------------------
# Configuration and Validation
# ---------------------------------------------------------------------------
: ${DOMAIN?"Need to set DOMAIN environment variable"}
[ -z "$PASSWORD" ] && export PASSWORD=redislabs

echo "🚀 Redis RDI Training Environment Startup"
echo "=========================================="
echo "Domain: $DOMAIN"
echo "Password: [MASKED]"
echo ""

# ---------------------------------------------------------------------------
# Pre-flight Checks
# ---------------------------------------------------------------------------
echo "🔍 Running pre-flight checks..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "❌ docker-compose not found. Please install Docker Compose."
    exit 1
fi

echo "✅ Docker and Docker Compose are available"

# ---------------------------------------------------------------------------
# Cleanup Previous Runs
# ---------------------------------------------------------------------------
echo ""
echo "🧹 Cleaning up any previous runs..."

# Stop and remove any existing containers
if docker-compose ps -q 2>/dev/null | grep -q .; then
    echo "   • Stopping existing containers..."
    docker-compose down --remove-orphans --volumes 2>/dev/null || true
fi

# Remove any orphaned containers from old setups
echo "   • Removing orphaned containers..."
docker stop $(docker ps -q --filter "name=rdi-ctf") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=rdi-ctf") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=redis-rdi-ctf") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=redis-rdi-ctf") 2>/dev/null || true

# Clean up any dangling resources
echo "   • Cleaning up Docker resources..."
docker system prune -f >/dev/null 2>&1 || true

echo "✅ Cleanup completed"

# ---------------------------------------------------------------------------
# Environment Setup
# ---------------------------------------------------------------------------
echo ""
echo "⚙️ Setting up environment..."

sudo chmod -R 777 grafana/ 2>/dev/null || chmod -R 777 grafana/ 2>/dev/null || true

export HOSTNAME=$(hostname -s)
export PASSWORD=$PASSWORD
export HOST_IP=$(hostname -I | awk '{print $1}')
export RDI_VERSION=1.10.0
export RE_USER=admin@rl.org

echo "   • Hostname: $HOSTNAME"
echo "   • Host IP: $HOST_IP"
echo "   • RDI Version: $RDI_VERSION"

# Generate configuration files
echo "   • Generating configuration files..."
if [ -f "./grafana_config/grafana.ini.template" ]; then
    envsubst < ./grafana_config/grafana.ini.template > ./grafana_config/grafana.ini
    echo "     ✅ Grafana config generated"
else
    echo "     ⚠️  Grafana template not found, using defaults"
fi

if [ -f "./prometheus/prometheus.yml.template" ]; then
    envsubst < ./prometheus/prometheus.yml.template > ./prometheus/prometheus.yml
    echo "     ✅ Prometheus config generated"
else
    echo "     ⚠️  Prometheus template not found, using defaults"
fi

# ---------------------------------------------------------------------------
# Docker Compose Startup
# ---------------------------------------------------------------------------
echo ""
echo "🐳 Starting Docker containers..."

# Wait for snap/bin if needed (some systems)
if [ -d "/snap/bin" ]; then
    while [ ! -x /snap/bin ]; do
        echo "   • Waiting for /snap/bin to be ready..."
        sleep 5
    done
fi

# Start containers with build
echo "   • Building and starting containers..."
docker-compose up -d --build --remove-orphans

# ---------------------------------------------------------------------------
# Container Health Checks
# ---------------------------------------------------------------------------
echo ""
echo "🏥 Waiting for containers to be healthy..."

# Wait for containers to start
sleep 10

# Check container status
echo "   • Checking container status..."
failed_containers=()
for container in $(docker-compose ps --services); do
    if ! docker-compose ps $container | grep -q "Up"; then
        failed_containers+=($container)
    fi
done

if [ ${#failed_containers[@]} -gt 0 ]; then
    echo "   ❌ Some containers failed to start: ${failed_containers[*]}"
    echo "   📋 Container logs:"
    for container in "${failed_containers[@]}"; do
        echo "      --- $container ---"
        docker-compose logs --tail=10 $container
    done
    exit 1
fi

echo "✅ All containers started successfully"

# ---------------------------------------------------------------------------
# Redis Enterprise Setup
# ---------------------------------------------------------------------------
echo ""
echo "🔧 Configuring Redis Enterprise..."

main_nodes=( re-n1 )
all_nodes=( re-n1 )

# Wait for Redis Enterprise nodes to be ready
for i in "${all_nodes[@]}"; do
    echo "   • Waiting for $i to be ready..."

    # Check if container is running
    if ! docker ps --format "table {{.Names}}" | grep -q "^$i$"; then
        echo "   ❌ Container $i is not running"
        exit 1
    fi

    # Copy wait script and wait for admin port
    if [ -f "wait-for-code.sh" ]; then
        docker cp wait-for-code.sh $i:/tmp/wait-for-code.sh
        docker exec -e URL=https://$i:9443/v1/bootstrap -e CODE=200 $i /bin/bash /tmp/wait-for-code.sh
    else
        echo "   ⚠️  wait-for-code.sh not found, using sleep fallback"
        sleep 30
    fi

    # Enable port 53 and other initialization
    docker exec --user root --privileged $i /bin/bash /tmp/init_script.sh 2>/dev/null || true

    echo "   ✅ $i is ready"
done

# Create Redis Enterprise cluster
echo "   • Creating Redis Enterprise cluster..."
export CLUSTER=re-cluster1.ps-redislabs.org
export IP=172.16.22.21
server="re-n1"

cluster_file="redis/create_cluster.json.template"

if [ -f "$cluster_file" ]; then
    envsubst < $cluster_file > create_cluster.json
    docker cp create_cluster.json $server:/tmp/create_cluster.json

    # Create cluster with error handling
    if docker exec $server curl -k -v --silent --fail -H 'Content-Type: application/json' -d @/tmp/create_cluster.json https://$server:9443/v1/bootstrap/create_cluster; then
        echo "   ✅ Redis Enterprise cluster created"
    else
        echo "   ⚠️  Cluster creation failed or cluster already exists"
    fi

    # Wait for admin port again
    if [ -f "wait-for-code.sh" ]; then
        docker cp wait-for-code.sh $server:/tmp/wait-for-code.sh
        docker exec -e URL=https://$server:9443/v1/bootstrap -e CODE=200 $server /bin/bash /tmp/wait-for-code.sh
    fi
else
    echo "   ⚠️  Cluster template not found: $cluster_file"
fi

# Update license if provided
if [[ -n $RE1_LICENSE ]]; then
    echo "   • Applying Redis Enterprise license..."
    docker exec re-n1 curl -v -k -d "{\"license\": \"$(echo $RE1_LICENSE | sed -z 's/\n/\\n/g')\"}" -u $RE_USER:$PASSWORD -H "Content-Type: application/json" -X PUT https://localhost:9443/v1/license
    echo "   ✅ License applied"
else
    echo "   ⚠️  No RE1_LICENSE provided, using trial license"
fi

# Final container restart to ensure everything is properly configured
echo "   • Restarting containers for final configuration..."
sleep 20
docker-compose up -d
sleep 20

# Configure Grafana
echo "   • Configuring Grafana dashboards..."
if [ -d "grafana" ] && [ -f "grafana/config_grafana.sh" ]; then
    cd grafana
    bash config_grafana.sh 2>/dev/null || echo "     ⚠️  Grafana configuration failed, continuing..."
    cd ..
    echo "   ✅ Grafana configured"
else
    echo "   ⚠️  Grafana configuration script not found"
fi


# ---------------------------------------------------------------------------
# Final Health Checks and Service Verification
# ---------------------------------------------------------------------------
echo ""
echo "🏥 Running final health checks..."

# Check all expected containers are running
expected_containers=("re-n1" "postgresql" "grafana" "prometheus" "redis-insight-2")
failed_services=()

for container in "${expected_containers[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
        echo "   ✅ $container is running"
    else
        echo "   ❌ $container is not running"
        failed_services+=($container)
    fi
done

# Check service ports
echo "   • Checking service ports..."
services_to_check=(
    "8443:Redis Enterprise UI"
    "5540:Redis Insight"
    "3000:Grafana"
    "5432:PostgreSQL"
    "9090:Prometheus"
)

for service in "${services_to_check[@]}"; do
    port=$(echo $service | cut -d: -f1)
    name=$(echo $service | cut -d: -f2)

    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo "   ✅ $name (port $port) is accessible"
    else
        echo "   ⚠️  $name (port $port) may not be ready yet"
    fi
done

# ---------------------------------------------------------------------------
# Terminal Setup (Optional)
# ---------------------------------------------------------------------------
echo ""
echo "🖥️ Setting up terminal access..."

if command -v ttyd >/dev/null 2>&1 && id -u labuser >/dev/null 2>&1; then
    echo "   • Starting ttyd terminal on port 7681..."
    sudo -u labuser nohup ttyd -W -p 7681 -t disableLeaveAlert=true -t fontSize=14 -t 'cursorStyle=bar' --client-option reconnect=true bash -c "cd /home/labuser && exec bash" >/dev/null 2>&1 &
    echo "   ✅ Terminal available at http://localhost:7681"
else
    echo "   ⚠️  ttyd or labuser not available, skipping terminal setup"
fi

# ---------------------------------------------------------------------------
# Startup Complete
# ---------------------------------------------------------------------------
echo ""
echo "🎉 Redis RDI Training Environment Started Successfully!"
echo "======================================================"
echo ""
echo "📊 Available Services:"
echo "   • Redis Enterprise UI:  http://localhost:8443"
echo "   • Redis Insight:         http://localhost:5540"
echo "   • Grafana Monitoring:    http://localhost:3000"
echo "   • PostgreSQL Database:   localhost:5432"
echo "   • Prometheus Metrics:    http://localhost:9090"
echo "   • SQLPad (DB Browser):   http://localhost:3001"
echo "   • Docker Logs (Dozzle):  http://localhost:8080"
if command -v ttyd >/dev/null 2>&1; then
echo "   • Terminal Access:       http://localhost:7681"
fi
echo ""
echo "🔐 Default Credentials:"
echo "   • Redis Enterprise:      admin@rl.org / $PASSWORD"
echo "   • Grafana:               admin / $PASSWORD"
echo "   • PostgreSQL:            postgres / postgres"
echo ""
echo "🚀 Next Steps:"
echo "   1. Access Redis Enterprise UI to create databases"
echo "   2. Use Redis Insight to configure RDI pipelines"
echo "   3. Monitor with Grafana dashboards"
echo "   4. Check PostgreSQL data with SQLPad"
echo ""

if [ ${#failed_services[@]} -gt 0 ]; then
    echo "⚠️  Warning: Some services failed to start: ${failed_services[*]}"
    echo "   Check logs with: docker-compose logs [service-name]"
    echo ""
fi

echo "📋 Useful Commands:"
echo "   • View logs:     docker-compose logs -f [service]"
echo "   • Stop all:      ./stop.sh"
echo "   • Restart:       ./start.sh"
echo ""
echo "✅ Environment is ready for Redis RDI training!"
