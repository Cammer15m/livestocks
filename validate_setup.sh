#!/bin/bash

# Redis RDI CTF Setup Validation Script
# Validates file structure and configuration without requiring Docker

echo "🔍 Validating Redis RDI CTF Setup..."
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
passed=0
failed=0
warnings=0

# Test functions
test_passed() {
    echo -e "${GREEN}✅ $1${NC}"
    ((passed++))
}

test_failed() {
    echo -e "${RED}❌ $1${NC}"
    ((failed++))
}

test_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((warnings++))
}

# Test 1: Check required files
echo "📁 Checking required files..."
required_files=(
    "docker-compose.yml"
    "Dockerfile.loadgen"
    "Dockerfile.web"
    "rdi-config/config.yaml.template"
    "rdi-config/README.md"
    "seed/music_database.sql"
    "seed/track.csv"
    "start_ctf.sh"
    "stop_ctf.sh"
    "web/index.html"
    "web/nginx.conf"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        test_passed "Found $file"
    else
        test_failed "Missing required file: $file"
    fi
done

# Test 2: Check required directories
echo ""
echo "📂 Checking directory structure..."
required_dirs=(
    "rdi-config"
    "seed"
    "web"
    "scripts"
    "labs"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        test_passed "Found directory: $dir"
    else
        test_failed "Missing required directory: $dir"
    fi
done

# Test 3: Check script permissions
echo ""
echo "🔐 Checking script permissions..."
scripts=("start_ctf.sh" "stop_ctf.sh" "test_rdi_setup.sh")

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            test_passed "$script is executable"
        else
            test_warning "$script is not executable (run: chmod +x $script)"
        fi
    fi
done

# Test 4: Validate Docker Compose syntax
echo ""
echo "🐳 Checking Docker Compose configuration..."
if command -v docker-compose >/dev/null 2>&1; then
    if docker-compose config >/dev/null 2>&1; then
        test_passed "docker-compose.yml syntax is valid"
    else
        test_failed "docker-compose.yml has syntax errors"
    fi
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    if docker compose config >/dev/null 2>&1; then
        test_passed "docker-compose.yml syntax is valid"
    else
        test_failed "docker-compose.yml has syntax errors"
    fi
else
    test_warning "Docker/Docker Compose not available - cannot validate compose file"
fi

# Test 5: Check database initialization file
echo ""
echo "🗄️ Checking database setup..."
if [ -f "seed/music_database.sql" ]; then
    # Check for key tables
    if grep -q "CREATE TABLE.*Album" seed/music_database.sql; then
        test_passed "Album table creation found"
    else
        test_failed "Album table creation not found"
    fi
    
    if grep -q "CREATE TABLE.*Track" seed/music_database.sql; then
        test_passed "Track table creation found"
    else
        test_failed "Track table creation not found"
    fi
    
    if grep -q "INSERT INTO.*Track" seed/music_database.sql; then
        test_passed "Sample track data found"
    else
        test_failed "Sample track data not found"
    fi
    
    if grep -q "ctf_flags" seed/music_database.sql; then
        test_passed "CTF flags table found"
    else
        test_failed "CTF flags table not found"
    fi
fi

# Test 6: Check RDI configuration template
echo ""
echo "⚙️ Checking RDI configuration..."
if [ -f "rdi-config/config.yaml.template" ]; then
    if grep -q "connections:" rdi-config/config.yaml.template; then
        test_passed "RDI connections configuration found"
    else
        test_failed "RDI connections configuration missing"
    fi
    
    if grep -q "target:" rdi-config/config.yaml.template; then
        test_passed "Redis target configuration found"
    else
        test_failed "Redis target configuration missing"
    fi
    
    if grep -q "source:" rdi-config/config.yaml.template; then
        test_passed "PostgreSQL source configuration found"
    else
        test_failed "PostgreSQL source configuration missing"
    fi
fi

# Test 7: Check web interface
echo ""
echo "🌐 Checking web interface..."
if [ -f "web/index.html" ]; then
    if grep -q "Redis RDI CTF" web/index.html; then
        test_passed "Web interface title found"
    else
        test_failed "Web interface title missing"
    fi
    
    if grep -q "localhost:5540" web/index.html; then
        test_passed "Redis Insight link found"
    else
        test_failed "Redis Insight link missing"
    fi
fi

# Test 8: Check load generator
echo ""
echo "📊 Checking load generator..."
if [ -f "scripts/generate_load.py" ]; then
    if grep -q "musicstore" scripts/generate_load.py; then
        test_passed "Load generator uses correct database name"
    else
        test_failed "Load generator database name incorrect"
    fi
fi

# Test 9: Check track data file
echo ""
echo "🎵 Checking track data..."
if [ -f "seed/track.csv" ]; then
    line_count=$(wc -l < seed/track.csv)
    if [ "$line_count" -gt 100 ]; then
        test_passed "Track CSV has $line_count lines"
    else
        test_warning "Track CSV has only $line_count lines (may be insufficient)"
    fi
else
    test_failed "Track CSV file missing"
fi

# Summary
echo ""
echo "📊 Validation Summary:"
echo "======================"
echo -e "${GREEN}✅ Passed: $passed${NC}"
echo -e "${RED}❌ Failed: $failed${NC}"
echo -e "${YELLOW}⚠️  Warnings: $warnings${NC}"

if [ $failed -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Setup validation completed successfully!${NC}"
    echo ""
    echo "📋 Ready to proceed:"
    echo "1. Install Docker and Docker Compose if not already installed"
    echo "2. Run ./start_ctf.sh to start the environment"
    echo "3. Sign up for Redis Cloud at https://redis.com/try-free/"
    echo "4. Configure RDI and start the labs!"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Setup validation failed with $failed errors${NC}"
    echo "Please fix the issues above before proceeding."
    exit 1
fi
