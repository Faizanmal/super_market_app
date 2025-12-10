-- SuperMart Pro Database Initialization Script
-- This script runs automatically when the PostgreSQL container starts

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text search

-- Create indexes for better performance (Django will create tables)
-- These are additional indexes for common query patterns

-- Note: Add any custom database initialization here
-- The Django migrations will handle table creation

-- Example: Create read-only user for analytics
-- CREATE USER analytics_reader WITH PASSWORD 'analytics_password';
-- GRANT CONNECT ON DATABASE supermart_db TO analytics_reader;
-- GRANT USAGE ON SCHEMA public TO analytics_reader;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_reader;

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'SuperMart Pro database initialized successfully';
END $$;
