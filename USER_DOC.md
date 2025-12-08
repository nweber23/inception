# User Documentation

This guide provides clear instructions for administrators and end users on how to operate, access, and manage the Inception infrastructure stack.

## 1. Services Overview

This project provides a complete web infrastructure stack composed of the following interconnected services:

*   **WordPress**: A popular Content Management System (CMS) for building websites.
*   **Nginx**: The web server acting as the secure entry point (HTTPS) for all traffic.
*   **MariaDB**: The database server where WordPress stores its content and settings.
*   **Redis**: A high-performance caching service to speed up WordPress.
*   **Adminer**: A web-based interface for managing the MariaDB database.
*   **Static Site**: A custom "Random Dog Generator" website.
*   **FTP**: A file transfer service to manage WordPress files (themes, plugins, uploads).

## 2. Configuration & Credentials

Before starting the project, you must configure the security credentials.

1.  **Locate the Configuration File**:
    The project uses environment variables stored in a file named `.env` located in the `secret/` directory.

2.  **Create/Edit Credentials**:
    If the file `secret/.env` does not exist, create it by copying the example template:
    ```sh
    cp .env.example secret/.env
    ```

3.  **Manage Variables**:
    Open `secret/.env` in a text editor. You can set the following sensitive values here:
    *   `MYSQL_ROOT_PASSWORD`: Password for the database root user.
    *   `MYSQL_USER` / `MYSQL_PASSWORD`: Credentials for the WordPress database user.
    *   `WORDPRESS_ADMIN_PASSWORD`: Login password for the WordPress dashboard.
    *   `FTP_USER` / `FTP_PASSWORD`: Credentials for FTP access to WordPress files.

    *Note: Do not commit the `secret/.env` file to version control (git).*

## 3. Starting and Stopping the Project

The project is managed via a `Makefile` at the root of the repository.

### Start the Stack
To build the Docker images and start all services in the background:
```sh
make up
```
*This command automatically creates necessary data folders on your host machine.*

### Stop the Stack
To stop the running containers and remove the virtual network:
```sh
make down
```

### Clean Up
To stop everything and remove all data (database files, website files) and Docker images:
```sh
make fclean
```

## 4. Accessing the Services

Once the stack is running (`make up`), you can access the services via your web browser.

*   **WordPress Website**: [https://nweber.42.fr](https://nweber.42.fr)
*   **Database Management (Adminer)**: [https://nweber.42.fr/adminer](https://nweber.42.fr/adminer)
    *   *Login using the credentials defined in your `.env` file.*
    *   *Server: `mariadb`*
*   **Random Dog Generator**: [https://nweber.42.fr/dog](https://nweber.42.fr/dog)
*   **FTP (local clients)**:
    - Host: `127.0.0.1`
    - Port: `21`
    - Passive ports: `30000–30009`
    - Username/Password: from [secret/.env](secret/.env)
    - Root directory: `/var/www/html`

**Security Note**: Since this project uses a self-signed SSL certificate, your browser will likely display a security warning ("Your connection is not private"). You must manually accept the risk/proceed to access the site.

For FTP, this setup uses plain FTP (no TLS) for local development. Do not expose it publicly without enabling TLS in [`src/ftp/vsftpd.conf`](src/ftp/vsftpd.conf) and restricting firewall rules.

## 5. Verifying Service Status

To check if the services are running correctly, you can use the following commands in your terminal:

### Check Container Status
View the list of running containers and their state:
```sh
docker compose -f src/docker-compose.yml ps
```
*You should see `nginx`, `wordpress`, `mariadb`, `redis`, and `adminer`