-- PostgreSQL initialization script for Redis RDI Training
-- Creates sample tables and data for RDI pipeline testing

-- Create Track table for music store demo
CREATE TABLE IF NOT EXISTS Track (
    TrackId SERIAL PRIMARY KEY,
    Name VARCHAR(200) NOT NULL,
    AlbumId INTEGER,
    MediaTypeId INTEGER NOT NULL,
    GenreId INTEGER,
    Composer VARCHAR(220),
    Milliseconds INTEGER NOT NULL,
    Bytes INTEGER,
    UnitPrice NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Album table
CREATE TABLE IF NOT EXISTS Album (
    AlbumId SERIAL PRIMARY KEY,
    Title VARCHAR(160) NOT NULL,
    ArtistId INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Artist table
CREATE TABLE IF NOT EXISTS Artist (
    ArtistId SERIAL PRIMARY KEY,
    Name VARCHAR(120),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Genre table
CREATE TABLE IF NOT EXISTS Genre (
    GenreId SERIAL PRIMARY KEY,
    Name VARCHAR(120),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create MediaType table
CREATE TABLE IF NOT EXISTS MediaType (
    MediaTypeId SERIAL PRIMARY KEY,
    Name VARCHAR(120),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO Artist (Name) VALUES 
    ('AC/DC'),
    ('Accept'),
    ('Aerosmith'),
    ('Alanis Morissette'),
    ('Alice In Chains')
ON CONFLICT DO NOTHING;

INSERT INTO Genre (Name) VALUES 
    ('Rock'),
    ('Jazz'),
    ('Metal'),
    ('Alternative & Punk'),
    ('Blues')
ON CONFLICT DO NOTHING;

INSERT INTO MediaType (Name) VALUES 
    ('MPEG audio file'),
    ('Protected AAC audio file'),
    ('Protected MPEG-4 video file'),
    ('Purchased AAC audio file'),
    ('AAC audio file')
ON CONFLICT DO NOTHING;

INSERT INTO Album (Title, ArtistId) VALUES 
    ('For Those About To Rock We Salute You', 1),
    ('Balls to the Wall', 2),
    ('Restless and Wild', 2),
    ('Let There Be Rock', 1),
    ('Big Ones', 3)
ON CONFLICT DO NOTHING;

INSERT INTO Track (Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES 
    ('For Those About To Rock (We Salute You)', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99),
    ('Balls to the Wall', 2, 1, 1, NULL, 342562, 5510424, 0.99),
    ('Fast As a Shark', 3, 1, 1, 'F. Baltes, S. Kaufman, U. Dirkscneider & W. Hoffmann', 230619, 3990994, 0.99),
    ('Restless and Wild', 3, 1, 1, 'F. Baltes, R.A. Smith-Diesel, S. Kaufman, U. Dirkscneider & W. Hoffmann', 252051, 4331779, 0.99),
    ('Princess of the Dawn', 3, 1, 1, 'Deaffy & R.A. Smith-Diesel', 375418, 6290521, 0.99)
ON CONFLICT DO NOTHING;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_track_updated_at BEFORE UPDATE ON Track FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_album_updated_at BEFORE UPDATE ON Album FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_artist_updated_at BEFORE UPDATE ON Artist FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable logical replication (needed for RDI CDC)
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 10;
ALTER SYSTEM SET max_wal_senders = 10;

-- Create replication user for RDI
CREATE USER rdi_user WITH REPLICATION PASSWORD 'rdi_password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rdi_user;
GRANT USAGE ON SCHEMA public TO rdi_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO rdi_user;

-- Grant permissions for RDI to read from tables
GRANT SELECT ON Track, Album, Artist, Genre, MediaType TO rdi_user;

-- Create publication for logical replication
CREATE PUBLICATION rdi_publication FOR ALL TABLES;

COMMIT;
