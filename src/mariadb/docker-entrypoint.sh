#!/bin/bash
set -e

# Start MariaDB service temporarily for setup
service mariadb start

# Wait for MariaDB to be ready
until mysqladmin ping &>/dev/null; do
	echo "Waiting for MariaDB to be ready..."
	sleep 1
done

# Check if database already exists
if ! mariadb -e "USE ${MYSQL_DATABASE};" &>/dev/null; then
	echo "Setting up MariaDB database..."

	mariadb <<-EOSQL
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
	EOSQL

	echo "MariaDB setup completed."
else
	echo "MariaDB database already exists, skipping setup."
fi

# Stop MariaDB to restart it properly
service mariadb stop

# Start MariaDB in foreground with network binding
exec mariadbd --user=mysql --bind-address=0.0.0.0 --port=3306