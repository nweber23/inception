#!/bin/bash
set -e

mkdir -p /var/www/html

if ! command -v wp >/dev/null 2>&1; then
    curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x /usr/local/bin/wp
fi

if [ ! -f /var/www/html/index.php ]; then
    echo "Bootstrapping WordPress core files..."
    (
        cd /var/www/html
        wp core download --allow-root
    )
fi

echo "Waiting for MariaDB..."
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    echo "MariaDB is unavailable - sleeping"
    sleep 3
done
echo "MariaDB is up and running!"

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

    # Ensure direct filesystem writes and Redis config
    wp --path=/var/www/html config set FS_METHOD direct --type=constant --allow-root
    wp --path=/var/www/html config set WP_CACHE true --type=constant --raw --allow-root
    wp --path=/var/www/html config set WP_REDIS_HOST redis --type=constant --allow-root
    wp --path=/var/www/html config set WP_REDIS_PORT 6379 --type=constant --raw --allow-root
    wp --path=/var/www/html config set WP_REDIS_CLIENT phpredis --type=constant --allow-root

    wp --path=/var/www/html plugin install redis-cache --activate --force --allow-root || wp --path=/var/www/html plugin activate redis-cache --allow-root
    wp --path=/var/www/html redis enable --allow-root || true

    echo "WordPress installation completed!"
else
    echo "WordPress is already installed."

    wp --path=/var/www/html config set FS_METHOD direct --type=constant --allow-root
    wp --path=/var/www/html config set WP_CACHE true --type=constant --raw --allow-root
    wp --path=/var/www/html config set WP_REDIS_HOST redis --type=constant --allow-root
    wp --path=/var/www/html config set WP_REDIS_PORT 6379 --type=constant --raw --allow-root
    wp --path=/var/www/html config set WP_REDIS_CLIENT phpredis --type=constant --allow-root
    wp --path=/var/www/html plugin install redis-cache --activate --force --allow-root || wp --path=/var/www/html plugin activate redis-cache --allow-root
    wp --path=/var/www/html redis enable --allow-root || true
fi

# Fix ownership/permissions so PHP-FPM (www-data) can write wp-content
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Start PHP-FPM
exec php-fpm8.2 -F