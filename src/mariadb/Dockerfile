FROM debian:bookworm

RUN apt update && apt upgrade -y && \
    apt install -y mariadb-server mariadb-client && \
    apt clean && rm -rf /var/lib/apt/lists/*

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["mariadb"]