*This project has been created as part of the 42 curriculum by nweber.*

# Inception

## Description

This project aims to broaden knowledge of system administration by using Docker to virtualize several services. Instead of using a single virtual machine, this project orchestrates a small infrastructure composed of different services running in separate containers.

The infrastructure includes:
*   **Nginx**: Serves as the entry point, handling TLS (HTTPS) and routing requests.
*   **WordPress**: The main Content Management System (CMS), running on PHP-FPM.
*   **MariaDB**: The database management system storing WordPress data.
*   **Redis**: An in-memory data structure store used as a cache for WordPress.
*   **Adminer**: A lightweight database management tool.
*   **Static Site**: A custom TypeScript-based "Random Dog Generator" served via Nginx.
*   **FTP**: A vsftpd server to manage WordPress files via FTP (optional for legacy workflows).

## Instructions

### Prerequisites
*   Docker Engine & Docker Compose
*   Make
*   Root privileges (for creating data directories)

### Installation

1.  **Clone the repository:**
    ```sh
    git clone <repository_url>
    cd inception
    ```

2.  **Configure Environment Variables:**
    Create a `.env` file in the `secret/` directory based on the example provided.
    ```sh
    cp .env.example secret/.env
    # Edit secret/.env with your specific passwords and usernames
    ```
    See [.env.example](.env.example) for the required variables.
    FTP credentials are defined by `FTP_USER` and `FTP_PASSWORD` in [secret/.env](secret/.env).

### Execution

To build and start the infrastructure, use the [`Makefile`](Makefile):

```sh
make up
```

This command will:
1.  Create the necessary data directories on the host (`/home/nweber/data/...`).
2.  Build the Docker images for Nginx, MariaDB, WordPress, Redis, and Adminer.
3.  Start the containers in the background.

### Access

Once the containers are running, you can access the services at:
*   **WordPress:** `https://nweber.42.fr`
*   **Adminer:** `https://nweber.42.fr/adminer`
*   **Static Site:** `https://nweber.42.fr/dog`
*   **FTP:** Host `127.0.0.1`, Port `21`, Passive ports `30000–30009`. Use credentials from [secret/.env](secret/.env). The FTP root maps to WordPress files at `/var/www/html`.

### Cleanup

To stop the containers and remove the network:
```sh
make down
```

To stop containers, remove images, networks, and volumes (deep clean):
```sh
make fclean
```

## Project Description & Design Choices

This project uses **Docker Compose** to orchestrate the services defined in [`src/docker-compose.yml`](src/docker-compose.yml).

**Key Design Choices:**
*   **OS Base:** `debian:bookworm` is used as the base image for most services to ensure stability and compliance with the subject.
*   **Nginx Reverse Proxy:** Nginx is the only container exposing ports (443) to the host. It routes traffic internally to WordPress (port 9000) or Adminer (port 8080) via the Docker network.
*   **Multi-stage Build:** The static site in [`src/nginx/Dockerfile`](src/nginx/Dockerfile) uses a multi-stage build. It compiles TypeScript assets in a Node.js container before copying the static files to the final Nginx image, keeping the final image size small.
*   **Resilience:** The `setup.sh` scripts (e.g., in [`src/wordpress/setup.sh`](src/wordpress/setup.sh)) are written to be idempotent, checking if configuration exists before attempting to write it, ensuring containers can restart without data loss or errors.
*   **FTP Integration:** The `ftp` service in [`src/docker-compose.yml`](src/docker-compose.yml) exposes port 21 and passive range 30000–30009, and mounts the WordPress volume to allow uploads directly into `/var/www/html`. Config is in [`src/ftp/vsftpd.conf`](src/ftp/vsftpd.conf). For external exposure, enable TLS and firewall the passive ports.

### Technical Comparisons

#### Virtual Machines vs Docker
*   **Virtual Machines (VMs):** Emulate an entire physical computer, including the hardware. Each VM runs a full Operating System (kernel + user space) on top of a hypervisor. This is resource-heavy and slow to boot.
*   **Docker (Containers):** Utilizes OS-level virtualization. Containers share the host system's kernel but keep user spaces isolated. This makes them extremely lightweight, fast to start, and efficient in resource usage compared to VMs.

#### Secrets vs Environment Variables
*   **Environment Variables:** The simplest way to pass configuration (like passwords) to containers. However, they can be inspected via `docker inspect` and are visible in the process list inside the container.
*   **Secrets:** A more secure mechanism (specifically in Docker Swarm, though mimicked in Compose) where sensitive data is mounted as a file into the container (usually `/run/secrets/`). This prevents passwords from leaking into logs or environment inspections. *Note: This project uses environment variables via an `.env` file for simplicity as per the subject requirements.*

#### Docker Network vs Host Network
*   **Docker Network (Bridge):** The default mode used in this project. Containers get their own IP addresses inside a private virtual network. They can communicate using service names (DNS) but are isolated from the host's network interface unless ports are explicitly mapped.
*   **Host Network:** The container shares the networking namespace of the host. It uses the host's IP address and ports directly. This removes network isolation and can cause port conflicts if multiple services try to bind to the same port (e.g., port 80).

#### Docker Volumes vs Bind Mounts
*   **Docker Volumes:** Managed by Docker and stored in a part of the host filesystem owned by Docker (`/var/lib/docker/volumes/`). They are the preferred mechanism for persisting data generated by and used by Docker containers.
*   **Bind Mounts:** Map a specific file or directory on the host machine to a path in the container. In this project, we use bind mounts (defined in the `volumes` section of the Compose file pointing to `/home/nweber/data`) to strictly control where the database and website files are stored on the host machine.

## Resources

### References
*   [Docker Documentation](https://docs.docker.com/)
*   [Nginx Documentation](https://nginx.org/en/docs/)
*   [WP-CLI Documentation](https://make.wordpress.org/cli/handbook/)
*   [TypeScript Documentation](https://www.typescriptlang.org/docs/)

### AI Usage
I utilized AI tools (such as ChatGPT/Gemini) in conjunction with **roadmap.sh** to answer open questions.