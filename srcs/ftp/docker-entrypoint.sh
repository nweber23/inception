#!/bin/bash
# Exit on error, unset variables, and pipe failures
set -euo pipefail

# Load FTP credentials from environment variables (with defaults)
# These come from secret/.env file
FTP_USER="${FTP_USER:-ftpuser}"
FTP_PASSWORD="${FTP_PASSWORD:-changeme}"

# Create or modify FTP user account
if id "$FTP_USER" >/dev/null 2>&1; then
  # User exists, update home directory
  usermod -d /home/"$FTP_USER" "$FTP_USER" || true
else
  # User doesn't exist, create new user
  # -m: create home directory
  # -d: specify home directory path
  # -s /bin/bash: set default shell
  useradd -m -d /home/"$FTP_USER" -s /bin/bash "$FTP_USER"
fi

# Set user password using chpasswd (reads user:password format from stdin)
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

# Set ownership of FTP user's home directory
chown -R "$FTP_USER":"$FTP_USER" /home/"$FTP_USER"
# Note: WordPress volume (/var/www/html) stays owned by www-data
# vsftpd will allow writes if file permissions permit

# Start vsftpd FTP server in foreground mode
# exec replaces shell with vsftpd process (PID 1 for proper Docker signals)
exec /usr/sbin/vsftpd /etc/vsftpd.conf