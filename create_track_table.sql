-- CREATE TABLE "Track" (
-- 	"TrackId" integer PRIMARY KEY,
-- 	"Name" character varying(255) NOT NULL,
-- 	"AlbumId" integer NOT NULL,
-- 	"MediaTypeId" integer NOT NULL,
-- 	"GenreId" integer NOT NULL,
-- 	"Composer" character varying(255) NOT NULL,
-- 	"Milliseconds" integer NOT NULL,
-- 	"Bytes" integer NOT NULL,
-- 	"UnitPrice" numeric(10,2) NOT NULL
-- );

-- /*
-- Putting this insert as generate_load gives an error when there are no records in
-- the file
-- */
-- INSERT INTO "Track" VALUES (1,'Init Track',1,1,1,'Fela Kuti',1000,1000,19.99)

-- Create Table for "Album"
CREATE TABLE "Album" (
  "AlbumId" SERIAL PRIMARY KEY,
  "Title" TEXT NOT NULL,
  "Artist" TEXT NOT NULL
);

-- Create Table for "MediaType"
CREATE TABLE "MediaType" (
  "MediaTypeId" SERIAL PRIMARY KEY,
  "Name" TEXT NOT NULL
);

-- Create Table for "Genre"
CREATE TABLE "Genre" (
  "GenreId" SERIAL PRIMARY KEY,
  "Name" TEXT NOT NULL
);

-- Create Table for "Track"
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

-- Seed Data
INSERT INTO "Album" ("AlbumId", "Title", "Artist") 
VALUES 
(1, 'For Those About to Rock We Salute You', 'AC/DC'),
(2, 'Balls to the Wall', 'Accept'),
(3, 'Restless and Wild', 'Accept'),
(4, 'Let There Be Rock', 'AC/DC'),
(5, 'Slide It In', 'Cloverdale'),
(6, 'Master of Puppets', 'Metallica');

INSERT INTO "MediaType" ("MediaTypeId", "Name")
VALUES 
(1, 'MPEG audio file'),
(2, 'Advanced Audio Codec (AAC)');

INSERT INTO "Genre" ("GenreId", "Name")
VALUES 
(1, 'Rock'),
(2, 'Metal'),
(3, 'Hip Hop'),
(4, 'Jazz'),
(5, 'Electric Dance Music');

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
