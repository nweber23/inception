#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Create WordPress root directory if it doesn't exist
mkdir -p /var/www/html

# Check if WP-CLI (WordPress Command Line Interface) is installed
if ! command -v wp >/dev/null 2>&1; then
    # Download WP-CLI from official repository
    curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    # Make WP-CLI executable
    chmod +x /usr/local/bin/wp
fi

# Check if WordPress core files are already present
if [ ! -f /var/www/html/index.php ]; then
    echo "Bootstrapping WordPress core files..."
    # Download WordPress core files using WP-CLI
    (
        cd /var/www/html
        wp core download --allow-root
    )
fi

# Wait for MariaDB to be ready before proceeding
echo "Waiting for MariaDB..."
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    echo "MariaDB is unavailable - sleeping"
    sleep 3
done
echo "MariaDB is up and running!"

# Check if WordPress is already configured
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Configuring and installing WordPress..."

    # Create wp-config.php with database credentials
    wp --path=/var/www/html config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    # Install WordPress with site configuration
    wp --path=/var/www/html core install \
        --url="${WORDPRESS_URL}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --allow-root

    # Create additional WordPress user if specified
    if [ -n "${WORDPRESS_USER}" ]; then
        wp --path=/var/www/html user create \
            "${WORDPRESS_USER}" \
            "${WORDPRESS_USER_EMAIL}" \
            --user_pass="${WORDPRESS_USER_PASSWORD}" \
            --role=author \
            --allow-root || echo "User already exists"
    fi

    # Configure WordPress settings for FTP and Redis caching
    # FS_METHOD=direct: Use direct filesystem access (no FTP for updates)
    wp --path=/var/www/html config set FS_METHOD direct --type=constant --allow-root
    # Enable WordPress cache
    wp --path=/var/www/html config set WP_CACHE true --type=constant --raw --allow-root
    # Configure Redis connection settings
    wp --path=/var/www/html config set WP_REDIS_HOST redis --type=constant --allow-root
    wp --path=/var/www/html config set WP_REDIS_PORT 6379 --type=constant --raw --allow-root
    wp --path=/var/www/html config set WP_REDIS_CLIENT phpredis --type=constant --allow-root

    # Install and activate Redis object cache plugin
    wp --path=/var/www/html plugin install redis-cache --activate --force --allow-root || wp --path=/var/www/html plugin activate redis-cache --allow-root
    # Enable Redis cache integration
    wp --path=/var/www/html redis enable --allow-root || true

    echo "WordPress installation completed!"
else
    # If WordPress is already installed, update configuration
    echo "WordPress is already installed."
    # Reapply WordPress settings (in case of container restart)
    wp --path=/var/www/html config set FS_METHOD direct --type=constant --allow-root
    wp --path=/var/www/html config set WP_CACHE true --type=constant --raw --allow-root
    wp --path=/var/www/html config set WP_REDIS_HOST redis --type=constant --allow-root
    wp --path=/var/www/html config set WP_REDIS_PORT 6379 --type=constant --raw --allow-root
    wp --path=/var/www/html config set WP_REDIS_CLIENT phpredis --type=constant --allow-root
    wp --path=/var/www/html plugin install redis-cache --activate --force --allow-root || wp --path=/var//html plugin activate redis-cache --allow-root
    wp --path=/var/www/html redis enable --allow-root || true
fi

# Set ownership of all WordPress files to www-data user and group
# www-data is the user that runs Nginx and PHP-FPM
chown -R www-data:www-data /var/www/html

# Make all directories group-writable (775 = rwxrwxr-x)
# This allows the www-data group (including FTP users) to write to directories
find /var/www/html -type d -exec chmod 775 {} \;

# Make all files group-writable (664 = rw-rw-r--)
# This allows the www-data group (including FTP users) to modify files
find /var/www/html -type f -exec chmod 664 {} \;

# Start PHP-FPM in foreground mode
# exec replaces the shell process with PHP-FPM
exec php-fpm8.2 -F