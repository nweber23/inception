#!/bin/bash
set -e

# Ensure runtime and data directories exist
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

echo "Starting MariaDB server..."
service mariadb start

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock ping &>/dev/null; do
    echo "MariaDB is not ready yet..."
    sleep 2
done
echo "MariaDB is ready."

# Initialize database and user idempotently
echo "Configuring database and users (idempotent)..."
if mariadb -u root -e "SELECT 1" &>/dev/null; then
	echo "Root has no password yet; setting it and creating DB/user..."
	mariadb -u root <<-EOSQL
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
EOSQL
else
	echo "Root password set; ensuring DB/user exist..."
	mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
		CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
EOSQL
fi
echo "MariaDB setup completed."

# Stop MariaDB to restart it properly
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown 2>/dev/null || service mariadb stop || true

sleep 1

# Start MariaDB in foreground with network binding
exec mariadbd --user=mysql --bind-address=0.0.0.0 --port=3306
