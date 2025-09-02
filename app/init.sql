-- Initialization script for PostgreSQL
-- This script will run when the database container starts for the first time

-- Create database if it doesn't exist (handled by POSTGRES_DB env var)
-- CREATE DATABASE IF NOT EXISTS taskdb;

-- Create user if it doesn't exist (handled by POSTGRES_USER env var)
-- CREATE USER IF NOT EXISTS taskuser WITH PASSWORD 'taskpass';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE taskdb TO taskuser;

-- Connect to taskdb
\c taskdb;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO taskuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO taskuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO taskuser;

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Optional: Create indexes for better performance (Flask-SQLAlchemy will handle table creation)
-- These will be created after tables exist, so we'll add them as a separate migration later
