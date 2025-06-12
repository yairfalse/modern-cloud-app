-- ModernBlog Development Database Initialization
-- Creates additional databases and users for development

-- Create test database
CREATE DATABASE modernblog_test;

-- Create staging database  
CREATE DATABASE modernblog_staging;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE modernblog_dev TO modernblog;
GRANT ALL PRIVILEGES ON DATABASE modernblog_test TO modernblog;
GRANT ALL PRIVILEGES ON DATABASE modernblog_staging TO modernblog;

-- Enable extensions
\c modernblog_dev;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

\c modernblog_test;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

\c modernblog_staging;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";