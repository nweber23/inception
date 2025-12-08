# Developer Documentation

This documentation is intended for developers who wish to modify, debug, or understand the internal workings of the Inception infrastructure.

## 1. Environment Setup

To set up the development environment from scratch, follow these steps.

### Prerequisites
Ensure the following tools are installed on your host machine:
*   **Docker Engine** (v20.10+)
*   **Docker Compose** (v2.0+)
*   **Make**
*   **Git**

### Configuration & Secrets
The project relies on environment variables for configuration and secrets. These are **not** committed to the repository.

1.  **Create the Secrets File**:
    Copy the example configuration file to the `secret/` directory:
    ```sh
    cp .env.example secret/.env
    ```

2.  **Configure Variables**:
    Edit `secret/.env` to set your local development credentials.
    *   **Database**: `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`
    *   **WordPress**: `WORDPRESS_URL` (e.g., `nweber.42.fr`), `WORDPRESS_ADMIN_PASSWORD`, etc.
    *   **FTP**: `FTP_USER`, `FTP_PASSWORD` used by the [`ftp`](src/docker-compose.yml) service.

### Host Configuration
The project is configured to run on the domain `nweber.42.fr`. You must map this domain to your local machine.
*   Edit your `/etc/hosts` file:
    ```
    127.0.0.1 nweber.42.fr
    ```

## 2. Building and Launching

The project uses a `Makefile` to abstract Docker Compose commands.

### Build and Start
To build the Docker images (if they don't exist) and start the containers in detached mode:
```sh
make up
```
*   This command reads `src/docker-compose.yml`.
*   It automatically creates the required data directories on the host at `/home/nweber/data/`.

### Rebuild
To force a rebuild of the containers (useful if you modified a `Dockerfile` or configuration file):
```sh
make re
```

## 3. Management Commands

### Service Management
Use the following `Make` targets to manage the lifecycle of the stack:

*   `make stop`: Stop running containers without removing them.
*   `make start`: Start stopped containers.
*   `make restart`: Restart all containers.
*   `make down`: Stop containers and remove the network.

### Debugging & Logs
*   **View Logs**: To stream logs from all services:
    ```sh
    make logs
    ```
*   **Shell Access**: To open a shell inside a running container (e.g., WordPress) for debugging:
    ```sh
    docker exec -it wordpress /bin/bash
    ```
    *(Replace `wordpress` with `nginx`, `mariadb`, etc.)*

### Cleaning
*   **Full Clean**: To remove all containers, networks, images, and volumes:
    ```sh
    make fclean
    ```

## 4. Data Storage & Persistence

Data persistence is handled using **Docker Volumes** backed by **Bind Mounts**. This ensures that critical data survives container restarts and removals.

### Storage Locations
The `docker-compose.yml` defines named volumes that map directly to specific directories on the host machine.

| Service | Docker Volume | Host Path | Description |
| :--- | :--- | :--- | :--- |
| **MariaDB** | `mariadb_data` | `/home/nweber/data/mariadb` | Stores raw database files. |
| **WordPress** | `wordpress_data` | `/home/nweber/data/wordpress` | Stores WP core files, plugins, and uploads. |
| **Redis** | `redis_data` | `/home/nweber/data/redis` | Stores Redis dump files (if persistence is enabled). |

### Persistence Behavior
*   **`make down`**: Removes containers and networks, but **preserves** the data in the host directories.
*   **`make fclean`**: Removes Docker volume definitions. However, because these are bind mounts, the actual files in `/home/nweber/data/` on the host

## 5. FTP Service (vsftpd)
The FTP service is defined in [`src/docker-compose.yml`](src/docker-compose.yml) and built from:
* [`src/ftp/Dockerfile`](src/ftp/Dockerfile)
* [`src/ftp/vsftpd.conf`](src/ftp/vsftpd.conf)
* [`src/ftp/docker-entrypoint.sh`](src/ftp/docker-entrypoint.sh)

Behavior:
* Passive mode ports: 30000–30009
* Root: `/var/www/html` (mounted `wordpress_data` volume)
* Users: provisioned from [secret/.env](secret/.env) via `FTP_USER`/`FTP_PASSWORD`

Local demo (VS Code terminal):
```sh
make up
# connect with any FTP client:
# host: 127.0.0.1, port: 21, passive mode on
# user/pass: from secret/.env
```

Security:
* Current config has `ssl_enable=NO` in [`src/ftp/vsftpd.conf`](src/ftp/vsftpd.conf) for local dev.
* For external use: enable TLS, restrict ports 21 and 30000–30009, and prefer SFTP if available.
