FROM node:20-alpine AS builder
WORKDIR /app

COPY ./site/package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --no-audit --no-fund; else npm install --no-audit --no-fund; fi

COPY ./site/tsconfig.json ./tsconfig.json
COPY ./site/index.html ./index.html
COPY ./site/styles.css ./styles.css
COPY ./site/src ./src

RUN npm run build && \
    mkdir -p dist/assets && \
    cp index.html dist/index.html && \
    cp styles.css dist/assets/styles.css

FROM debian:bookworm

RUN apt update && apt upgrade -y && \
    apt install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default

RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/c=DE/st=Baden-wuerttemberg/l=Heilbronn/o=42/ou=student/cn=nweber.42.fr"

COPY --from=builder /app/dist /usr/share/nginx/html/dog
COPY ./default.conf /etc/nginx/conf.d/default.conf

EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]