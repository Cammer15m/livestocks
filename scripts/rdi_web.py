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
