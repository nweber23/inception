#!/bin/bash
set -e

# Ensure runtime and data directories exist
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Initialize database if empty
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

# Start MariaDB (network enabled) in background
/usr/sbin/mariadbd --user=mysql --bind-address=0.0.0.0 --port=3306 &
MARIADB_PID=$!

# Wait for MariaDB to be ready
until mysqladmin ping --silent >/dev/null 2>&1; do
  echo "Waiting for MariaDB to be ready..."
  sleep 1
done

# Helper to execute SQL as root (try with password, then without)
mysql_exec() {
  mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "$1" 2>/dev/null || mariadb -u root -e "$1"
}

# Create database and user if needed (works with either root auth mode)
if [ -n "${MYSQL_DATABASE}" ] && [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
  echo "Creating database ${MYSQL_DATABASE}..."
  mysql_exec "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
fi

if [ -n "${MYSQL_USER}" ] && [ -n "${MYSQL_PASSWORD}" ]; then
  echo "Ensuring user ${MYSQL_USER} exists..."
  mysql_exec "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
  if [ -n "${MYSQL_DATABASE}" ]; then
    mysql_exec "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;"
  fi
fi

# Optionally set root password if provided (ignore if unix_socket auth is active)
if [ -n "${MYSQL_ROOT_PASSWORD}" ]; then
  mysql_exec "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" || true
fi

# Keep foreground process
wait ${MARIADB_PID}
