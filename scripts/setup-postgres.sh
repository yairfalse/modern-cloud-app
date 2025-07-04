#!/bin/bash
set -e

echo "Setting up PostgreSQL for local development..."

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL not found. Installing via Homebrew..."
    brew install postgresql@15
    brew services start postgresql@15
else
    echo "PostgreSQL is already installed."
fi

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
sleep 3

# Create database and user
echo "Creating database and user..."
psql postgres <<EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'modernblog') THEN
        CREATE USER modernblog WITH PASSWORD 'dev_password_123';
    END IF;
END
\$\$;

-- Create database if not exists
CREATE DATABASE modernblog_dev OWNER modernblog;

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE modernblog_dev TO modernblog;
EOF

echo "PostgreSQL setup complete!"
echo "Connection details:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: modernblog_dev"
echo "  User: modernblog"
echo "  Password: dev_password_123"