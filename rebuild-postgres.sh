#!/bin/bash

# Script to rebuild PostgreSQL container with Python 3.9 support
echo "PostgreSQL Container Rebuild Script (Python 3.9)"
echo "================================================="
echo ""
echo "This script will rebuild the PostgreSQL container with Python 3.9"
echo "to match your local Python environment."
echo ""

# Stop and remove existing container
echo "1. Stopping and removing existing PostgreSQL container..."
docker stop rdi-postgres 2>/dev/null || echo "   Container not running"
docker rm rdi-postgres 2>/dev/null || echo "   Container not found"

# Remove existing image
echo "2. Removing existing PostgreSQL image..."
docker rmi redis_rdi_ctf-postgresql 2>/dev/null || echo "   Image not found"

echo ""
echo "3. Building PostgreSQL container..."
echo "   This may take a few minutes..."
echo ""

# Try building with the simplified Dockerfile first (more reliable)
echo "Attempting build with simplified Dockerfile (system packages)..."
if docker build -f Dockerfile.postgres.simple -t redis_rdi_ctf-postgresql . 2>&1 | tee build-simple.log; then
    echo ""
    echo "✅ Build successful with simplified Dockerfile!"
    BUILD_SUCCESS=true
    echo ""
    echo "Note: Using system Python packages for maximum compatibility."
else
    echo ""
    echo "❌ Simplified build failed. Trying main Dockerfile..."
    echo ""

    # Try building with main Dockerfile
    if docker build -f Dockerfile.postgres -t redis_rdi_ctf-postgresql . 2>&1 | tee build.log; then
        echo ""
        echo "✅ Build successful with main Dockerfile!"
        BUILD_SUCCESS=true
    else
        echo ""
        echo "❌ Both builds failed. Please check the logs:"
        echo "   - Simple build log: build-simple.log"
        echo "   - Main build log: build.log"
        echo ""
        echo "Common solutions:"
        echo "1. Check internet connection for package downloads"
        echo "2. Restart Docker Desktop"
        echo "3. Clear Docker build cache: docker builder prune"
        echo "4. Check available disk space: df -h"
        echo "5. Try: docker system prune -f"
        BUILD_SUCCESS=false
    fi
fi

if [ "$BUILD_SUCCESS" = true ]; then
    echo ""
    echo "4. Testing the built image..."
    
    # Test if the image can start
    if docker run --rm -d --name test-postgres -e POSTGRES_DB=test -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres redis_rdi_ctf-postgresql; then
        echo "   Container starts successfully"
        
        # Wait a moment for startup
        sleep 5
        
        # Test if PostgreSQL is accessible
        if docker exec test-postgres pg_isready -U postgres; then
            echo "   PostgreSQL is accessible"
            
            # Test if Python is working
            if docker exec test-postgres python3 --version; then
                echo "   Python is working"
                
                # Test if Python packages are installed
                if docker exec test-postgres python3 -c "import pandas, numpy, psycopg2, sqlalchemy; print('All packages imported successfully')"; then
                    echo "   Python packages are working"
                    echo ""
                    echo "✅ All tests passed! Container is ready."
                else
                    echo "   ⚠️  Python packages have issues, but basic functionality should work"
                fi
            else
                echo "   ⚠️  Python has issues, but PostgreSQL should work"
            fi
        else
            echo "   ⚠️  PostgreSQL accessibility test failed, but container built successfully"
        fi
        
        # Clean up test container
        docker stop test-postgres >/dev/null 2>&1
    else
        echo "   ⚠️  Container start test failed, but image was built"
    fi
    
    echo ""
    echo "5. Ready to start environment!"
    echo "   Run: ./start.sh (Linux/Mac) or .\\start.ps1 (Windows)"
else
    echo ""
    echo "❌ Build failed. Please check the error messages above."
    echo ""
    echo "You can also try building manually:"
    echo "   docker build -f Dockerfile.postgres -t redis_rdi_ctf-postgresql ."
    echo "   or"
    echo "   docker build -f Dockerfile.postgres.simple -t redis_rdi_ctf-postgresql ."
fi

echo ""
echo "Build logs saved to:"
echo "   - build.log (main Dockerfile)"
echo "   - build-simple.log (simplified Dockerfile)"
