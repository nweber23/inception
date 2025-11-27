FROM debian:bookworm

RUN apt update && apt upgrade -y && \
    apt install -y php8.3-fpm php8.3-mysql curl wget mariadb-client && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN sed -i 's|listen = /run/php/php8.3-fpm.sock|listen = 9000|' /etc/php/8.3/fpm/pool.d/www.conf

RUN mkdir -p /var/www/html

COPY ./setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 9000

CMD ["php-fpm8.3", "-F"]