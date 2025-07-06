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

        # Inject CTF flags after initial sync
        if self.last_track_id > 0 and not self.redis_client.exists("ctf:flags_injected"):
            self.inject_ctf_flags()

        return len(new_tracks)

    def inject_ctf_flags(self):
        """Inject CTF flags into Redis"""
        print("🏴 Injecting CTF flags...")

        # Flag 1: Basic sync completion
        flag1_track = {
            "TrackId": "999001",
            "Name": "RDI{pg_to_redis_success}",
            "AlbumId": "1",
            "MediaTypeId": "1",
            "GenreId": "1",
            "Composer": "CTF Challenge",
            "Milliseconds": "180000",
            "Bytes": "5000000",
            "UnitPrice": "0.99"
        }

        self.redis_client.hset("track:999001", mapping=flag1_track)
        self.redis_client.sadd("tracks", "999001")

        # Flag 2: CDC detection
        flag2_track = {
            "TrackId": "999002",
            "Name": "RDI{snapshot_vs_cdc_detected}",
            "AlbumId": "2",
            "MediaTypeId": "1",
            "GenreId": "2",
            "Composer": "CTF Challenge",
            "Milliseconds": "240000",
            "Bytes": "6000000",
            "UnitPrice": "1.29"
        }

        self.redis_client.hset("track:999002", mapping=flag2_track)
        self.redis_client.sadd("tracks", "999002")

        # Flag 3: Advanced features
        flag3_track = {
            "TrackId": "999003",
            "Name": "RDI{advanced_features_mastered}",
            "AlbumId": "3",
            "MediaTypeId": "1",
            "GenreId": "3",
            "Composer": "CTF Challenge",
            "Milliseconds": "300000",
            "Bytes": "7000000",
            "UnitPrice": "1.99"
        }

        self.redis_client.hset("track:999003", mapping=flag3_track)
        self.redis_client.sadd("tracks", "999003")

        # Mark flags as injected
        self.redis_client.set("ctf:flags_injected", "true")
        print("✅ CTF flags injected successfully!")
    
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
