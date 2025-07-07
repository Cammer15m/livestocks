#!/bin/bash

# Wait for HTTP endpoint to return expected status code
# Usage: wait-for-code.sh
# Environment variables:
#   URL - The URL to check
#   CODE - Expected HTTP status code (default: 200)
#   TIMEOUT - Timeout in seconds (default: 300)

URL=${URL:-"http://localhost"}
CODE=${CODE:-200}
TIMEOUT=${TIMEOUT:-300}

echo "Waiting for $URL to return HTTP $CODE..."

start_time=$(date +%s)
while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -gt $TIMEOUT ]; then
        echo "Timeout after ${TIMEOUT}s waiting for $URL"
        exit 1
    fi
    
    # Check if URL returns expected status code
    if curl -k -s -o /dev/null -w "%{http_code}" "$URL" | grep -q "^$CODE$"; then
        echo "✅ $URL returned HTTP $CODE after ${elapsed}s"
        exit 0
    fi
    
    echo "⏳ Waiting for $URL (${elapsed}s elapsed)..."
    sleep 5
done
