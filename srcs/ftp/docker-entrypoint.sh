#!/bin/bash
# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error
# Fail on pipe errors
set -euo pipefail

# Set FTP user and password from environment variables or use defaults
FTP_USER="${FTP_USER:-ftpuser}"
FTP_PASSWORD="${FTP_PASSWORD:-changeme}"

# Ensure www-data group exists (should already exist from base image)
# This group is used by web servers like Nginx and PHP-FPM
getent group www-data >/dev/null || groupadd -r www-data

# Check if the FTP user already exists
if id "$FTP_USER" >/dev/null 2>&1; then
  # If user exists, update their home directory
  usermod -d /home/"$FTP_USER" "$FTP_USER" || true
else
  # If user doesn't exist, create it with:
  # -m: create home directory
  # -d: set home directory path
  # -s: set login shell
  useradd -m -d /home/"$FTP_USER" -s /bin/bash "$FTP_USER"
fi

# Set the FTP user's password
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

# Add FTP user to www-data group for WordPress write access
# This allows the FTP user to write to files owned by www-data
usermod -a -G www-data "$FTP_USER"

# Set ownership of FTP user's home directory
chown -R "$FTP_USER":"$FTP_USER" /home/"$FTP_USER"

# Start vsftpd FTP server in foreground mode
# exec replaces the shell process with vsftpd
exec /usr/sbin/vsftpd /etc/vsftpd.conf