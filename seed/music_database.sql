-- Redis RDI CTF Sample Data - Music Store (Chinook Database)
-- Based on the proven RDI training repository music data

-- Create Album table
CREATE TABLE "Album" (
  "AlbumId" SERIAL PRIMARY KEY,
  "Title" TEXT NOT NULL,
  "Artist" TEXT NOT NULL
);

-- Create MediaType table
CREATE TABLE "MediaType" (
  "MediaTypeId" SERIAL PRIMARY KEY,
  "Name" TEXT NOT NULL
);

-- Create Genre table
CREATE TABLE "Genre" (
  "GenreId" SERIAL PRIMARY KEY,
  "Name" TEXT NOT NULL
);

-- Create Track table
CREATE TABLE "Track" (
  "TrackId" SERIAL PRIMARY KEY,
  "Name" character varying(255) NOT NULL,
  "AlbumId" INTEGER NOT NULL REFERENCES "Album"("AlbumId"),
  "MediaTypeId" INTEGER NOT NULL REFERENCES "MediaType"("MediaTypeId"),
  "GenreId" INTEGER NOT NULL REFERENCES "Genre"("GenreId"),
  "Composer" character varying(255) NOT NULL,
  "Milliseconds" INTEGER NOT NULL,
  "Bytes" INTEGER NOT NULL,
  "UnitPrice" NUMERIC(10, 2) NOT NULL
);

-- Insert sample albums
INSERT INTO "Album" ("AlbumId", "Title", "Artist")
VALUES
(1, 'For Those About to Rock We Salute You', 'AC/DC'),
(2, 'Balls to the Wall', 'Accept'),
(3, 'Restless and Wild', 'Accept'),
(4, 'Let There Be Rock', 'AC/DC'),
(5, 'Big Ones', 'Aerosmith'),
(6, 'Master of Puppets', 'Metallica'),
(7, 'The Dark Side of the Moon', 'Pink Floyd'),
(8, 'Abbey Road', 'The Beatles');

-- Insert media types
INSERT INTO "MediaType" ("MediaTypeId", "Name")
VALUES
(1, 'MPEG audio file'),
(2, 'Advanced Audio Codec (AAC)'),
(3, 'MPEG video file'),
(4, 'Purchased AAC audio file');

-- Insert genres
INSERT INTO "Genre" ("GenreId", "Name")
VALUES
(1, 'Rock'),
(2, 'Metal'),
(3, 'Hip Hop'),
(4, 'Jazz'),
(5, 'Electronic'),
(6, 'Blues'),
(7, 'Classical'),
(8, 'Pop');

-- Insert sample tracks
INSERT INTO "Track" ("TrackId", "Name", "AlbumId", "MediaTypeId", "GenreId", "Composer", "Milliseconds", "Bytes", "UnitPrice")
VALUES
(1, 'For Those About To Rock (We Salute You)', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99),
(2, 'Balls to the Wall', 2, 2, 1, 'U.D. Dirkschneider, W. Hoffmann, H. Frank, P. Baltes, S. Kaufmann, G. Hoffmann', 342562, 5510424, 0.99),
(3, 'Fast As a Shark', 3, 2, 1, 'F. Baltes, S. Kaufman, U. Dirkscneider & W. Hoffman', 230619, 3990994, 0.99),
(4, 'Restless and Wild', 3, 2, 1, 'F. Baltes, R.A. Smith-Diesel, S. Kaufman, U. Dirkscneider & W. Hoffman', 252051, 4331779, 0.99),
(5, 'Princess of the Dawn', 3, 2, 1, 'Deaffy & R.A. Smith-Diesel', 375418, 6290521, 0.99),
(6, 'Put The Finger On You', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 205662, 6713451, 0.99),
(7, 'Let''s Get It Up', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 233926, 7636561, 0.99),
(8, 'Inject The Venom', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 210834, 6852860, 0.99),
(9, 'Snowballed', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 203102, 6599424, 0.99),
(10, 'Evil Walks', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 263497, 8611245, 0.99),
(11, 'Walk On Water', 5, 1, 1, 'Steven Tyler, Joe Perry, Jack Blades, Tommy Shaw', 295680, 9719579, 0.99),
(12, 'Love In An Elevator', 5, 1, 1, 'Steven Tyler, Joe Perry', 321828, 10552051, 0.99),
(13, 'Master of Puppets', 6, 1, 2, 'Kirk Hammett, Lars Ulrich, James Hetfield, Cliff Burton', 515442, 16852860, 0.99),
(14, 'Money', 7, 1, 1, 'Roger Waters', 382834, 12545866, 0.99),
(15, 'Come Together', 8, 1, 1, 'John Lennon, Paul McCartney', 259721, 8489536, 0.99);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_track_album ON "Track"("AlbumId");
CREATE INDEX IF NOT EXISTS idx_track_genre ON "Track"("GenreId");
CREATE INDEX IF NOT EXISTS idx_track_mediatype ON "Track"("MediaTypeId");
CREATE INDEX IF NOT EXISTS idx_album_artist ON "Album"("Artist");

-- Create CTF flags table
CREATE TABLE ctf_flags (
    lab_id VARCHAR(10) PRIMARY KEY,
    flag_value VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert CTF flags
INSERT INTO ctf_flags (lab_id, flag_value, description) VALUES
('01', 'RDI{pg_to_redis_snapshot_success}', 'Successfully performed PostgreSQL to Redis snapshot migration'),
('02', 'RDI{cdc_streaming_master}', 'Mastered Change Data Capture streaming from PostgreSQL'),
('03', 'RDI{transformation_ninja}', 'Applied advanced transformations and filters in RDI pipeline');

-- Create a view for easy flag retrieval
CREATE VIEW lab_flags AS
SELECT
    lab_id,
    flag_value,
    description,
    'flag:' || lab_id AS redis_key
FROM ctf_flags;

-- Display summary
SELECT 'Music store data loaded successfully!' as message;
SELECT 'Albums: ' || COUNT(*) as count FROM "Album";
SELECT 'Tracks: ' || COUNT(*) as count FROM "Track";
SELECT 'Genres: ' || COUNT(*) as count FROM "Genre";
SELECT 'Media Types: ' || COUNT(*) as count FROM "MediaType";
SELECT 'CTF Flags: ' || COUNT(*) as count FROM ctf_flags;
