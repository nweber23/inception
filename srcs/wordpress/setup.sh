#!/bin/bash
# Exit immediately if any command fails
set -e

# Create WordPress root directory if it doesn't exist
mkdir -p /var/www/html

# Check if WP-CLI is installed, download if not
if ! command -v wp >/dev/null 2>&1; then
    # Download WP-CLI (WordPress command-line interface) from official repository
    curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    # Make WP-CLI executable
    chmod +x /usr/local/bin/wp
fi

# Check if WordPress core files are already downloaded
if [ ! -f /var/www/html/index.php ]; then
    echo "Bootstrapping WordPress core files..."
    # Run in subshell to avoid changing current directory
    (
        cd /var/www/html
        # Download latest WordPress core files
        wp core download --allow-root
    )
fi

echo "Waiting for MariaDB..."
# Wait for MariaDB to be available before proceeding
# -h mariadb: connect to MariaDB service by Docker service name
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    echo "MariaDB is unavailable - sleeping"
    sleep 3
done
echo "MariaDB is up and running!"

# Check if WordPress is already configured
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Configuring and installing WordPress..."

    # Create wp-config.php with database connection details
    wp --path=/var/www/html config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    # Install WordPress and create admin user
    wp --path=/var/www/html core install \
        --url="${WORDPRESS_URL}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --allow-root

    # Create additional non-admin user if specified in environment
    if [ -n "${WORDPRESS_USER}" ]; then
        wp --path=/var/www/html user create \
            "${WORDPRESS_USER}" \
            "${WORDPRESS_USER_EMAIL}" \
            --user_pass="${WORDPRESS_USER_PASSWORD}" \
            --role=author \
            --allow-root || echo "User already exists"
    fi

    # Configure WordPress constants in wp-config.php
    # FS_METHOD=direct: Allow WordPress to write files directly (no FTP)
    wp --path=/var/www/html config set FS_METHOD direct --type=constant --allow-root
    # WP_CACHE=true: Enable object caching
    wp --path=/var/www/html config set WP_CACHE true --type=constant --raw --allow-root
    # WP_REDIS_HOST: Redis server hostname (Docker service name)
    wp --path=/var/www/html config set WP_REDIS_HOST redis --type=constant --allow-root
    # WP_REDIS_PORT: Redis port number
    wp --path=/var/www/html config set WP_REDIS_PORT 6379 --type=constant --raw --allow-root
    # WP_REDIS_CLIENT: Use phpredis extension for Redis connection
    wp --path=/var/www/html config set WP_REDIS_CLIENT phpredis --type=constant --allow-root

    # Install and activate Redis object cache plugin
    wp --path=/var/www/html plugin install redis-cache --activate --force --allow-root || wp --path=/var/www/html plugin activate redis-cache --allow-root
    # Enable Redis object caching
    wp --path=/var/www/html redis enable --allow-root || true

    echo "WordPress installation completed!"
else
    echo "WordPress is already installed."

    # Ensure Redis configuration is set (idempotent for container restarts)
    wp --path=/var/www/html config set FS_METHOD direct --type=constant --allow-root
    wp --path=/var/www/html config set WP_CACHE true --type=constant --raw --allow-root
    wp --path=/var/www/html config set WP_REDIS_HOST redis --type=constant --allow-root
    wp --path=/var/www/html config set WP_REDIS_PORT 6379 --type=constant --raw --allow-root
    wp --path=/var/www/html config set WP_REDIS_CLIENT phpredis --type=constant --allow-root
    # Ensure Redis plugin is activated
    wp --path=/var/www/html plugin install redis-cache --activate --force --allow-root || wp --path=/var/www/html plugin activate redis-cache --allow-root
    wp --path=/var/www/html redis enable --allow-root || true
fi

# Set correct ownership for PHP-FPM user (www-data)
chown -R www-data:www-data /var/www/html
# Set directory permissions to 755 (rwxr-xr-x)
find /var/www/html -type d -exec chmod 755 {} \;
# Set file permissions to 644 (rw-r--r--)
find /var/www/html -type f -exec chmod 644 {} \;

# Start PHP-FPM in foreground mode
# -F: Run in foreground (so Docker keeps container running)
exec php-fpm8.2 -F