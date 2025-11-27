FROM debian:bookworm

RUN apt upgrade -y && \
    apt install -y nginx && openssl \
    rm -rf /var/lib/apt/lists/*

RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj"/c=DE/st=Baden-wuerttemberg/l=Heilbronn/o=42/ou=student/cn=nweber.42.fr"

COPY ./default.conf /etc/nginx/conf.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]