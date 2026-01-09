#!/bin/bash
# Exit immediately if any command fails
set -e

# Create runtime directory for MariaDB socket and PID files
# Create data directory for database files
mkdir -p /run/mysqld

# Set correct ownership for MariaDB user on runtime and data directories
chown -R mysql:mysql /run/mysqld /var/lib/mysql

echo "Starting MariaDB server..."
# Start MariaDB service in background for initial setup
service mariadb start

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
# Ping MariaDB via Unix socket until it responds
until mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock ping &>/dev/null; do
    echo "MariaDB is not ready yet..."
    sleep 2
done
echo "MariaDB is ready."

# Initialize database and user idempotently
echo "Configuring database and users (idempotent)..."
# Check if root user can connect without password (first run)
if mariadb -u root -e "SELECT 1" &>/dev/null; then
	echo "Root has no password yet; setting it and creating DB/user..."
	# Execute SQL commands to set root password and create database/user
	mariadb -u root <<-EOSQL
		-- Set root password from environment variable
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		-- Create WordPress database if it doesn't exist
		CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
		-- Create WordPress user that can connect from any host (%)
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		-- Grant all privileges on the WordPress database to the user
		GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
		-- Reload privilege tables
		FLUSH PRIVILEGES;
EOSQL
else
	echo "Root password set; ensuring DB/user exist..."
	# Root password already set, use it to ensure database/user exist
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
		-- Create database if it doesn't exist (idempotent)
		CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
		-- Create user if it doesn't exist (idempotent)
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		-- Grant privileges (idempotent)
		GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
		-- Reload privilege tables
		FLUSH PRIVILEGES;
EOSQL
fi
echo "MariaDB setup completed."

# Stop MariaDB gracefully before restarting in foreground mode
# Try multiple methods to ensure it stops
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown 2>/dev/null || service mariadb stop || true

# Brief pause to ensure clean shutdown
sleep 1

# Start MariaDB in foreground (so Docker keeps container running)
# --user=mysql: Run as mysql user for security
# --bind-address=0.0.0.0: Listen on all network interfaces (allow remote connections)
# --port=3306: Listen on standard MySQL port
exec mariadbd --user=mysql --bind-address=0.0.0.0 --port=3306
