#!/bin/bash
# Exit on error, unset variables, and pipe failures
set -euo pipefail

# Start PHP built-in web server for Adminer database management tool
# -S 0.0.0.0:8080: Listen on all interfaces on port 8080
# -t /var/www/html: Set document root to /var/www/html
# exec replaces shell with php process (PID 1 for proper Docker signals)
exec php -S 0.0.0.0:8080 -t /var/www/html