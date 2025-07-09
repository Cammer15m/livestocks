#!/bin/bash

echo "Stopping Redis Training Environment..."

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

# Stop and remove containers
$DOCKER_COMPOSE -f docker-compose-cloud.yml down -v --remove-orphans

echo "Environment stopped and cleaned up."
