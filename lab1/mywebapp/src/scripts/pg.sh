#!/bin/bash
set -e

DB_NAME="mywebappdb"
DB_USER="mywebapp"
DB_PASS="mywebapp"

echo "Initializing PostgreSQL..."

sudo -u postgres psql <<EOF
DO \$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '$DB_USER') THEN
        CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';
    END IF;
END \$$;

SELECT 'CREATE DATABASE $DB_NAME' 
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

ALTER DATABASE $DB_NAME OWNER TO $DB_USER;
EOF

sudo mkdir -p /etc/mywebapp
cat <<EOF | sudo tee /etc/mywebapp/config.json
{
  "database": {
    "user": "$DB_USER",
    "host": "127.0.0.1",
    "database": "$DB_NAME",
    "password": "$DB_PASS",
    "port": 5432
  },
  "server": {
    "port": 5000
  }
}
EOF

echo "Database environment ready."