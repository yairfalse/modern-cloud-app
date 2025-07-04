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
    # Check if PostgreSQL service is running
    # First check if postgresql@15 formula exists
    if brew list --formula | grep -q "postgresql@15"; then
        if ! brew services list | grep postgresql@15 | grep -q started; then
            echo "PostgreSQL@15 is installed but not running. Starting it..."
            brew services start postgresql@15
        fi
    else
        # Maybe user has a different version of PostgreSQL
        if brew list --formula | grep -q "^postgresql$"; then
            if ! brew services list | grep "^postgresql" | grep -q started; then
                echo "PostgreSQL is installed but not running. Starting it..."
                brew services start postgresql
            fi
        fi
    fi
fi

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
for i in {1..10}; do
    if pg_isready -q; then
        echo "PostgreSQL is ready!"
        break
    fi
    echo "Waiting for PostgreSQL... ($i/10)"
    sleep 2
done

# Create database and user
echo "Creating database and user..."
psql postgres <<EOF || true
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'modernblog') THEN
        CREATE USER modernblog WITH PASSWORD 'dev_password_123';
    END IF;
END
\$\$;

-- Create database if not exists  
SELECT 'CREATE DATABASE modernblog_dev OWNER modernblog' 
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'modernblog_dev')\gexec

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