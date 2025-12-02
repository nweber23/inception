#!/bin/bash
set -euo pipefail

redis-server --version

mkdir -p /data
chown -R redis:redis /data

exec redis-server /etc/redis/redis.conf \
  --daemonize no \
  --supervised no \
  --protected-mode no \
  --appendonly yes \
  --dir /data \
  --bind 0.0.0.0 \
  --port 6379 \
  --loglevel verbose