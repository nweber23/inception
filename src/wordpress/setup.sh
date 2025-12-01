#!/bin/bash
set -e

# Ensure document root exists
mkdir -p /var/www/html

# Install WP-CLI if missing
if ! command -v wp >/dev/null 2>&1; then
    curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x /usr/local/bin/wp
fi

# Ensure WordPress core files exist so Nginx doesn't 403 on empty volume
if [ ! -f /var/www/html/index.php ]; then
    echo "Bootstrapping WordPress core files..."
    (
        cd /var/www/html
        wp core download --allow-root
    )
fi

# Wait for MariaDB to be ready (needed for config/install)
echo "Waiting for MariaDB..."
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    echo "MariaDB is unavailable - sleeping"
    sleep 3
done
echo "MariaDB is up and running!"

# Configure and install WordPress if not already configured
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Configuring and installing WordPress..."

    wp --path=/var/www/html config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    wp --path=/var/www/html core install \
        --url="${WORDPRESS_URL}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --allow-root

    if [ -n "${WORDPRESS_USER}" ]; then
        wp --path=/var/www/html user create \
            "${WORDPRESS_USER}" \
            "${WORDPRESS_USER_EMAIL}" \
            --user_pass="${WORDPRESS_USER_PASSWORD}" \
            --role=author \
            --allow-root || echo "User already exists"
    fi

    echo "WordPress installation completed!"
else
    echo "WordPress is already installed."
fi

# Start PHP-FPM
exec php-fpm8.2 -F