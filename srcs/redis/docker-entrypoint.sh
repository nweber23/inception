#!/bin/bash
# Exit on error, unset variables, and pipe failures
set -euo pipefail

# Display Redis version for logging/debugging
redis-server --version

# Create data directory for Redis persistence
mkdir -p /data

# Set correct ownership for Redis user
chown -R redis:redis /data

# Start Redis server with configuration
# exec replaces shell with redis-server (PID 1 for proper Docker signals)
exec redis-server /etc/redis/redis.conf \
  --daemonize no \
  --supervised no \
  --protected-mode no \
  --appendonly yes \
  --dir /data \
  --bind 0.0.0.0 \
  --port 6379 \
  --loglevel verbose