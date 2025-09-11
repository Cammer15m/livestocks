-- PostgreSQL initialization script for Debezium support
-- This script sets up the required permissions and configurations for logical replication

\echo 'Starting Debezium configuration...'

\echo 'Granting replication permissions to postgres user...'
ALTER USER postgres WITH REPLICATION;
\echo 'Replication permissions granted successfully.'

-- Create a dedicated replication user (optional, but recommended)
-- CREATE USER debezium_user WITH REPLICATION PASSWORD 'debezium_password';
-- GRANT CONNECT ON DATABASE chinook TO debezium_user;
-- GRANT USAGE ON SCHEMA public TO debezium_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium_user;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO debezium_user;

\echo 'Verifying PostgreSQL configuration for logical replication...'

\echo 'Current WAL level (should be logical):'
SHOW wal_level;

\echo 'Max replication slots:'
SHOW max_replication_slots;

\echo 'Max WAL senders:'
SHOW max_wal_senders;

-- Create a test publication for all tables (Debezium will create its own)
-- CREATE PUBLICATION test_publication FOR ALL TABLES;

\echo 'Fixing Track sequence to match existing data...'
-- Fix Track sequence to match existing data (prevents duplicate key errors)
-- This ensures new INSERTs get the correct next TrackId
SELECT setval('"Track_TrackId_seq"', (SELECT MAX("TrackId") FROM "Track"));
\echo 'Track sequence updated successfully.'

\echo 'Verifying table counts...'
SELECT 'Album' as table_name, COUNT(*) as record_count FROM "Album"
UNION ALL
SELECT 'MediaType' as table_name, COUNT(*) as record_count FROM "MediaType"
UNION ALL
SELECT 'Genre' as table_name, COUNT(*) as record_count FROM "Genre"
UNION ALL
SELECT 'Track' as table_name, COUNT(*) as record_count FROM "Track";

-- Log successful initialization
\echo 'PostgreSQL configured for Debezium logical replication successfully!'
SELECT 'PostgreSQL configured for Debezium logical replication' AS status;
