#!/bin/bash
set -euo pipefail

# Expect: FTP_USER, FTP_PASSWORD (from secret/.env)
FTP_USER="${FTP_USER:-ftpuser}"
FTP_PASSWORD="${FTP_PASSWORD:-changeme}"

# Ensure the user exists and set password
if id "$FTP_USER" >/dev/null 2>&1; then
  usermod -d /home/"$FTP_USER" "$FTP_USER" || true
else
  useradd -m -d /home/"$FTP_USER" -s /bin/bash "$FTP_USER"
fi
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

# Ensure proper permissions for FTP access
chown -R "$FTP_USER":"$FTP_USER" /home/"$FTP_USER"
# WordPress volume stays owned by www-data; vsftpd will allow writes if perms permit

# Start vsftpd in foreground
exec /usr/sbin/vsftpd /etc/vsftpd.conf