import random
import time
import os

import pandas as pd
from sqlalchemy import create_engine, text, text, text

# Use environment variables or defaults for local setup
DB_HOST = os.getenv("DB_HOST", "localhost")  # localhost when running outside Docker
DB_PORT = os.getenv("DB_PORT", 5432)
DB_NAME = os.getenv("DB_NAME", "chinook")  # Updated to match new schema
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")


def main():
    """A script to generate and insert random track data into the 'Track' table of the music database.

    Reads track names and composers from a CSV file, generates random track information,
    and inserts it into the database table indefinitely.

    This script connects to the PostgreSQL database and continuously inserts new track records
    with random data into the 'Track' table. It uses a CSV file containing track names and composers
    and generates random values for other track attributes such as genre, milliseconds, bytes, and unit price.
    """
    # Get the directory of this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(script_dir, "..", "seed", "track.csv")

    # read track data from CSV
    print(f"Loading track data from: {csv_path}")
    track_df = pd.read_csv(csv_path, usecols=["Name", "Composer"])

    # connect to database
    print(f"Connecting to PostgreSQL at {DB_HOST}:{DB_PORT}/{DB_NAME}")
    try:
        engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
        conn = engine.connect()
        print("✓ Database connection successful")
    except Exception as e:
        print(f"✗ Database connection failed: {e}")
        print("Make sure PostgreSQL is running and credentials are correct")
        return

    # fetch largest track id
    try:
        res = conn.execute(text("""SELECT COALESCE(MAX("TrackId"), 0) FROM "Track" """)).fetchall()
        track_id = res[0][0]
        print(f"Starting from TrackId: {track_id + 1}")
    except Exception as e:
        print(f"✗ Failed to get max TrackId: {e}")
        return

    print("🎵 Starting continuous track generation...")
    print("Press Ctrl+C to stop")

    try:
        while True:
            # Select random track from CSV
            track_rand_id = random.randrange(0, len(track_df))
            track_name = track_df.iloc[track_rand_id, 0]
            track_composer = track_df.iloc[track_rand_id, 1]

            # Generate random attributes
            track_genre = random.randrange(1, 9)  # 1-8 genres
            track_album = random.randrange(1, 9)  # 1-8 albums
            track_mediatype = random.randrange(1, 5)  # 1-4 media types
            track_milliseconds = random.randrange(120000, 400000)  # 2-6.5 minutes
            track_bytes = random.randrange(2000000, 8000000)  # 2-8 MB
            track_price = random.choice([0.99, 1.29, 1.99])  # Realistic prices
            track_id += 1

            insert_stmt = """INSERT INTO "Track"
                    ("TrackId", "Name", "AlbumId", "MediaTypeId", "GenreId", "Composer", "Milliseconds", "Bytes", "UnitPrice")
                    VALUES (:track_id, :track_name, :track_album, :track_mediatype, :track_genre, :track_composer, :track_milliseconds, :track_bytes, :track_price)"""

            try:
                conn.execute(text(insert_stmt), {
                    'track_id': track_id,
                    'track_name': track_name,
                    'track_album': track_album,
                    'track_mediatype': track_mediatype,
                    'track_genre': track_genre,
                    'track_composer': track_composer,
                    'track_milliseconds': track_milliseconds,
                    'track_bytes': track_bytes,
                    'track_price': track_price
                })
                conn.commit()

                # Show progress every 10 tracks
                if track_id % 10 == 0:
                    print(f"\n🎵 Added track {track_id}: {track_name[:30]}...")
                else:
                    print(".", end="", flush=True)

            except Exception as e:
                print(f"\n✗ Failed to insert track {track_id}: {e}")

            # Random delay between inserts
            time.sleep(random.randint(100, 500)/1000)

    except KeyboardInterrupt:
        print(f"\n\n🛑 Stopped. Generated {track_id} tracks total.")
        conn.close()
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        conn.close()


if __name__ == "__main__":
    main()
