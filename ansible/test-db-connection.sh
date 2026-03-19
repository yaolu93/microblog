#!/bin/bash

# Simple script to test PostgreSQL connectivity
# Run on web server to verify database configuration

DB_HOST=${1:-localhost}
DB_USER=${2:-microblog_user}
DB_NAME=${3:-microblog_db}

echo "Testing PostgreSQL connection..."
echo "Host: $DB_HOST"
echo "User: $DB_USER"
echo "Database: $DB_NAME"
echo ""

if ! command -v psql &> /dev/null; then
    echo "Error: psql not installed"
    echo "Install with: sudo apt-get install postgresql-client"
    exit 1
fi

# Try to connect
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT NOW();" 

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Database connection successful!"
else
    echo ""
    echo "✗ Database connection failed"
    echo "Check:"
    echo "1. Postgres server is running on $DB_HOST"
    echo "2. User credentials are correct"
    echo "3. Database $DB_NAME exists"
    echo "4. Firewall allows connection to port 5432"
fi
