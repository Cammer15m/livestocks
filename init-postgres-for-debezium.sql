-- PostgreSQL initialization script for Debezium support
-- This script sets up the required permissions and configurations for logical replication

-- Grant replication permissions to the postgres user
ALTER USER postgres WITH REPLICATION;

-- Create a dedicated replication user (optional, but recommended)
-- CREATE USER debezium_user WITH REPLICATION PASSWORD 'debezium_password';
-- GRANT CONNECT ON DATABASE chinook TO debezium_user;
-- GRANT USAGE ON SCHEMA public TO debezium_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium_user;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO debezium_user;

-- Enable logical replication for the chinook database
-- This is handled by the postgresql.conf file, but we can verify settings here

-- Show current WAL level (should be 'logical')
SHOW wal_level;

-- Show max replication slots
SHOW max_replication_slots;

-- Show max WAL senders  
SHOW max_wal_senders;

-- Create a test publication for all tables (Debezium will create its own)
-- CREATE PUBLICATION test_publication FOR ALL TABLES;

-- Log successful initialization
SELECT 'PostgreSQL configured for Debezium logical replication' AS status;
