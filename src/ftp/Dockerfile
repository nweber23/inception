FROM debian:bookworm

RUN apt update && apt upgrade -y && \
    apt install -y vsftpd openssl && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home && useradd -m -d /home/ftpuser -s /bin/bash ftpuser || true

RUN mkdir -p /var/run/vsftpd/empty
COPY ./vsftpd.conf /etc/vsftpd.conf

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 21 30000-30009
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]