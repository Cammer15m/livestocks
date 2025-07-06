#!/bin/bash

# Setup check script - runs once to verify everything is working

echo "🔍 Running CTF setup verification..."

sleep 10  # Wait for services to start

# Check PostgreSQL
if PGPASSWORD='rdi_password' psql -U rdi_user -d rdi_db -h localhost -c "SELECT COUNT(*) FROM \"Track\";" >/dev/null 2>&1; then
    echo "✅ PostgreSQL connection successful"
else
    echo "❌ PostgreSQL connection failed"
fi

# Check if .env exists
if [ -f /app/.env ]; then
    echo "✅ Environment file exists"
else
    echo "⚠️ No .env file found - copy from .env.template"
fi

# Check Python dependencies
if python3 -c "import redis, psycopg2, flask" 2>/dev/null; then
    echo "✅ Python dependencies installed"
else
    echo "❌ Python dependencies missing"
fi

echo "🎯 CTF setup verification complete"
