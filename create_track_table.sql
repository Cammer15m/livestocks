-- PostgreSQL Database Initialization Script
-- This script creates the Chinook music database schema and seed data
-- for Redis RDI training environment

\echo 'Starting database initialization...'
\echo 'Creating tables for Chinook music database...'

-- Create Table for "Album"
\echo 'Creating Album table...'
CREATE TABLE "Album" (
  "AlbumId" SERIAL PRIMARY KEY,
  "Title" TEXT NOT NULL,
  "Artist" TEXT NOT NULL
);
\echo 'Album table created successfully.'

-- Create Table for "MediaType"
\echo 'Creating MediaType table...'
CREATE TABLE "MediaType" (
  "MediaTypeId" SERIAL PRIMARY KEY,
  "Name" TEXT NOT NULL
);
\echo 'MediaType table created successfully.'

-- Create Table for "Genre"
\echo 'Creating Genre table...'
CREATE TABLE "Genre" (
  "GenreId" SERIAL PRIMARY KEY,
  "Name" TEXT NOT NULL
);
\echo 'Genre table created successfully.'

-- Create Table for "Track"
\echo 'Creating Track table...'
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
\echo 'Track table created successfully.'

-- Seed Data
\echo 'Inserting seed data...'

\echo 'Inserting Album data...'
INSERT INTO "Album" ("AlbumId", "Title", "Artist")
VALUES
(1, 'For Those About to Rock We Salute You', 'AC/DC'),
(2, 'Balls to the Wall', 'Accept'),
(3, 'Restless and Wild', 'Accept'),
(4, 'Let There Be Rock', 'AC/DC'),
(5, 'Slide It In', 'Cloverdale'),
(6, 'Master of Puppets', 'Metallica');
\echo 'Album data inserted successfully.'

\echo 'Inserting MediaType data...'
INSERT INTO "MediaType" ("MediaTypeId", "Name")
VALUES
(1, 'MPEG audio file'),
(2, 'Advanced Audio Codec (AAC)');
\echo 'MediaType data inserted successfully.'

\echo 'Inserting Genre data...'
INSERT INTO "Genre" ("GenreId", "Name")
VALUES
(1, 'Rock'),
(2, 'Metal'),
(3, 'Hip Hop'),
(4, 'Jazz'),
(5, 'Electric Dance Music');
\echo 'Genre data inserted successfully.'

\echo 'Inserting Track data...'
INSERT INTO "Track" ("TrackId", "Name", "AlbumId", "MediaTypeId", "GenreId", "Composer", "Milliseconds", "Bytes", "UnitPrice")
VALUES
(1, 'For Those About To Rock (We Salute You)', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99),
(2, 'Balls to the Wall', 2, 2, 1, '', 342562, 5510424, 0.99),
(3, 'Fast As a Shark', 3, 2, 1, 'F. Baltes, S. Kaufman, U. Dirkscneider & W. Hoffman', 230619, 3990994, 0.99),
(4, 'Restless and Wild', 3, 2, 1, 'F. Baltes, R.A. Smith-Diesel, S. Kaufman, U. Dirkscneider & W. Hoffman', 252051, 4331779, 0.99),
(5, 'Princess of the Dawn', 3, 2, 1, 'Deaffy & R.A. Smith-Diesel', 375418, 6290521, 0.99),
(6, 'Put The Finger On You', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 205662, 6713451, 0.99),
(7, 'Let''s Get It Up', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 233926, 7636561, 0.99),
(8, 'Inject The Venom', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 210834, 6852860, 0.99),
(9, 'Snowballed', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 203102, 6599424, 0.99),
(10, 'Evil Walks', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 263497, 8611245, 0.99);
\echo 'Track data inserted successfully.'

\echo 'Database initialization completed successfully!'
\echo 'Tables created: Album, MediaType, Genre, Track'
\echo 'Seed data inserted for all tables.'
