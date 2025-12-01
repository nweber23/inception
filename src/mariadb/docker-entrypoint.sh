#!/bin/bash
set -e

# Start MariaDB service temporarily for setup
service mariadb start

# Wait for MariaDB to be ready
until mariadb -e "SELECT 1" &>/dev/null; do
    echo "Waiting for MariaDB to be ready..."
    sleep 1
done

# Check if database already exists
if ! mariadb -e "USE ${MYSQL_DATABASE};" &>/dev/null; then
    echo "Setting up MariaDB database..."

    # Secure installation
    mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

    # Create database
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"

    # Create user and grant privileges
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

    echo "MariaDB setup completed."
else
    echo "MariaDB database already exists, skipping setup."
fi

# Stop MariaDB to restart it properly
service mariadb stop

# Start MariaDB in foreground with network binding
exec mariadbd --user=mysql --bind-address=0.0.0.0 --port=3306