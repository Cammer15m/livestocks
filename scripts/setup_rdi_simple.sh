#!/usr/bin/env bash
set -e

# Redis RDI CTF - Simple RDI Setup using Redis Stack
# Since official RDI image isn't available, we'll use Redis Stack with custom scripts

echo "🔗 Redis RDI CTF - Simple RDI Setup"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if services are running
check_services() {
    print_status "Checking required services..."
    
    # Check PostgreSQL
    if docker ps | grep -q postgres; then
        print_success "✓ PostgreSQL is running"
    else
        print_error "✗ PostgreSQL is not running"
        print_status "Please run: docker-compose up -d postgres"
        exit 1
    fi
    
    # Check Redis
    if docker ps | grep -q redis; then
        print_success "✓ Redis is running"
    else
        print_error "✗ Redis is not running"
        print_status "Please run: docker-compose up -d redis"
        exit 1
    fi
}

# Create RDI simulation scripts
create_rdi_scripts() {
    print_status "Creating RDI simulation scripts..."
    
    # Create RDI connector script
    cat > rdi_connector.py << 'EOF'
#!/usr/bin/env python3
"""
Simple RDI Connector - Simulates Redis Data Integration
Continuously syncs PostgreSQL Track table to Redis
"""

import os
import time
import json
import redis
import psycopg2
from psycopg2.extras import RealDictCursor

# Configuration
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", 5432))
DB_NAME = os.getenv("DB_NAME", "chinook")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

class SimpleRDI:
    def __init__(self):
        self.redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB, decode_responses=True)
        self.pg_conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        self.last_track_id = 0
        
    def get_last_synced_id(self):
        """Get the last synced track ID from Redis"""
        try:
            return int(self.redis_client.get("rdi:last_track_id") or 0)
        except:
            return 0
    
    def sync_tracks(self):
        """Sync new tracks from PostgreSQL to Redis"""
        cursor = self.pg_conn.cursor(cursor_factory=RealDictCursor)
        
        # Get new tracks since last sync
        cursor.execute('''
            SELECT * FROM "Track" 
            WHERE "TrackId" > %s 
            ORDER BY "TrackId"
        ''', (self.last_track_id,))
        
        new_tracks = cursor.fetchall()
        
        if new_tracks:
            print(f"🔄 Syncing {len(new_tracks)} new tracks...")
            
            for track in new_tracks:
                # Store track as Redis hash
                track_key = f"track:{track['TrackId']}"
                track_data = dict(track)
                
                # Convert to strings for Redis
                for key, value in track_data.items():
                    if value is not None:
                        track_data[key] = str(value)
                
                self.redis_client.hset(track_key, mapping=track_data)
                
                # Add to tracks set
                self.redis_client.sadd("tracks", track['TrackId'])
                
                # Update last synced ID
                self.last_track_id = track['TrackId']
                self.redis_client.set("rdi:last_track_id", self.last_track_id)
                
                print(f"  ✓ Synced track {track['TrackId']}: {track['Name'][:30]}...")
        
        cursor.close()
        return len(new_tracks)
    
    def run_continuous(self):
        """Run continuous sync"""
        print("🚀 Starting Simple RDI Connector...")
        print("Press Ctrl+C to stop")
        
        # Initial sync
        self.last_track_id = self.get_last_synced_id()
        print(f"📍 Starting from track ID: {self.last_track_id}")
        
        try:
            while True:
                synced_count = self.sync_tracks()
                if synced_count > 0:
                    print(f"✅ Synced {synced_count} tracks. Total in Redis: {self.redis_client.scard('tracks')}")
                
                time.sleep(2)  # Check every 2 seconds
                
        except KeyboardInterrupt:
            print("\n🛑 RDI Connector stopped")
        except Exception as e:
            print(f"\n❌ Error: {e}")
        finally:
            self.pg_conn.close()

if __name__ == "__main__":
    rdi = SimpleRDI()
    rdi.run_continuous()
EOF

    chmod +x rdi_connector.py
    print_success "✓ RDI connector script created"
}

# Create RDI web interface
create_web_interface() {
    print_status "Creating simple RDI web interface..."
    
    cat > rdi_web.py << 'EOF'
#!/usr/bin/env python3
"""
Simple RDI Web Interface
Provides basic monitoring and control for the RDI connector
"""

from flask import Flask, render_template_string, jsonify
import redis
import psycopg2
import os

app = Flask(__name__)

# Configuration
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", 5432))
DB_NAME = os.getenv("DB_NAME", "chinook")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>Redis RDI CTF - Simple RDI Interface</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .stat-card { background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #007bff; }
        .stat-number { font-size: 2em; font-weight: bold; color: #007bff; }
        .stat-label { color: #666; margin-top: 5px; }
        .status { padding: 10px; border-radius: 5px; margin: 10px 0; }
        .status.success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .status.error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .refresh-btn { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; }
        .refresh-btn:hover { background: #0056b3; }
    </style>
    <script>
        function refreshStats() {
            fetch('/api/stats')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('pg-tracks').textContent = data.pg_tracks;
                    document.getElementById('redis-tracks').textContent = data.redis_tracks;
                    document.getElementById('last-sync').textContent = data.last_sync_id;
                    document.getElementById('sync-status').textContent = data.sync_status;
                });
        }
        
        setInterval(refreshStats, 5000); // Refresh every 5 seconds
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔗 Redis RDI CTF - Simple RDI Interface</h1>
            <p>Real-time PostgreSQL to Redis Data Integration</p>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-number" id="pg-tracks">{{ stats.pg_tracks }}</div>
                <div class="stat-label">PostgreSQL Tracks</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="redis-tracks">{{ stats.redis_tracks }}</div>
                <div class="stat-label">Redis Tracks</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="last-sync">{{ stats.last_sync_id }}</div>
                <div class="stat-label">Last Synced ID</div>
            </div>
        </div>
        
        <div class="status {{ 'success' if stats.sync_status == 'In Sync' else 'error' }}">
            <strong>Status:</strong> <span id="sync-status">{{ stats.sync_status }}</span>
        </div>
        
        <button class="refresh-btn" onclick="refreshStats()">🔄 Refresh Stats</button>
        
        <h3>🎯 CTF Instructions</h3>
        <ol>
            <li>Start the load generator: <code>python3 generate_load.py</code></li>
            <li>Watch tracks sync from PostgreSQL to Redis in real-time</li>
            <li>Check RedisInsight at <a href="http://localhost:5540" target="_blank">localhost:5540</a></li>
            <li>Find the hidden flags in the synced data!</li>
        </ol>
    </div>
</body>
</html>
'''

@app.route('/')
def dashboard():
    stats = get_stats()
    return render_template_string(HTML_TEMPLATE, stats=stats)

@app.route('/api/stats')
def api_stats():
    return jsonify(get_stats())

def get_stats():
    try:
        # Get PostgreSQL track count
        conn = psycopg2.connect(
            host=DB_HOST, port=DB_PORT, database=DB_NAME,
            user=DB_USER, password=DB_PASSWORD
        )
        cursor = conn.cursor()
        cursor.execute('SELECT COUNT(*) FROM "Track"')
        pg_tracks = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        # Get Redis track count
        redis_tracks = redis_client.scard('tracks') or 0
        
        # Get last sync ID
        last_sync_id = redis_client.get('rdi:last_track_id') or 0
        
        # Determine sync status
        sync_status = "In Sync" if pg_tracks == redis_tracks else f"Behind by {pg_tracks - redis_tracks}"
        
        return {
            'pg_tracks': pg_tracks,
            'redis_tracks': redis_tracks,
            'last_sync_id': last_sync_id,
            'sync_status': sync_status
        }
    except Exception as e:
        return {
            'pg_tracks': 'Error',
            'redis_tracks': 'Error',
            'last_sync_id': 'Error',
            'sync_status': f'Error: {str(e)}'
        }

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
EOF

    chmod +x rdi_web.py
    print_success "✓ RDI web interface created"
}

# Install Python dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    cat > requirements_rdi.txt << 'EOF'
redis>=4.0.0
psycopg2-binary>=2.9.0
flask>=2.0.0
pandas>=1.3.0
sqlalchemy>=1.4.0
EOF

    if command -v pip3 >/dev/null 2>&1; then
        pip3 install -r requirements_rdi.txt
        print_success "✓ Python dependencies installed"
    else
        print_error "✗ pip3 not found. Please install Python dependencies manually:"
        cat requirements_rdi.txt
    fi
}

# Show setup completion
show_completion() {
    echo ""
    print_success "🎉 Simple RDI setup complete!"
    echo ""
    print_status "Available services:"
    echo "  • RDI Web Interface: http://localhost:8080"
    echo "  • RedisInsight: http://localhost:5540"
    echo "  • SQLPad: http://localhost:3001"
    echo ""
    print_status "To start RDI connector:"
    echo "  cd scripts && python3 rdi_connector.py"
    echo ""
    print_status "To start RDI web interface:"
    echo "  cd scripts && python3 rdi_web.py"
    echo ""
    print_status "To generate test data:"
    echo "  cd scripts && python3 generate_load.py"
}

# Main function
main() {
    check_services
    create_rdi_scripts
    create_web_interface
    install_dependencies
    show_completion
}

# Run main function
main "$@"
