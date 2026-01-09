FROM debian:bookworm

RUN apt update && apt upgrade -y && \
    apt install -y redis-server redis-tools && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Configure Redis to listen on Docker network and persist to /data
RUN sed -ri "s/^bind .*/bind 0.0.0.0/" /etc/redis/redis.conf && \
    sed -ri "s/^protected-mode .*/protected-mode no/" /etc/redis/redis.conf && \
    sed -ri "s/^supervised .*/supervised no/" /etc/redis/redis.conf && \
    sed -ri "s|^dir .*|dir /data|" /etc/redis/redis.conf && \
    mkdir -p /data

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
EXPOSE 6379
HEALTHCHECK --interval=5s --timeout=3s --retries=10 CMD redis-cli -h 127.0.0.1 -p 6379 ping | grep -q PONG || exit 1
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]