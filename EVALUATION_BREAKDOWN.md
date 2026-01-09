# Inception Evaluation Breakdown & Solutions

This guide provides a step-by-step breakdown of how to validate the Inception project against the evaluation sheet.

## ⚠️ Important Note
**Do not modify the project files during evaluation unless asked.**
**If files are missing or in the wrong place (e.g., `src` instead of `srcs`), the evaluation usually stops.**

---

## 1. Preliminaries
**Decision:** Start or Stop.

*   **Cheat / Git:** Verify the repository has been cloned correctly.
*   **Credentials:** Check if `.env` is used.
    *   **Check:** Look at `src/docker-compose.yml`. Does it have `env_file:`?
    *   **Check:** Look for passwords hardcoded in `docker-compose.yml` or `Dockerfile`. They should **not** be there. They should be in `.env` (passed via variables).
    *   **Action:** If passwords are in the repo (and not ignored by `.gitignore` or separate), grade is 0.

## 2. General Instructions

*   **Folder Structure:**
    *   **Requirement:** `srcs` folder at root.
    *   **Check:** Run `ls -F`. You should see `srcs/` containing the configuration files.
    *   **Note:** Your current workspace has `src/`. Strictly speaking, this might be a fail if the subject requires `srcs`.
*   **Makefile:**
    *   **Check:** `cat Makefile` at root.
*   **Clean Start:**
    *   **Action:** Run the provided docker cleanup command line (stop/rm/rmi/volume rm etc.) before starting.
*   **Docker Compose Config:**
    *   **Check:** `grep "network: host" src/docker-compose.yml` -> Should be empty.
    *   **Check:** `grep "links:" src/docker-compose.yml` -> Should be empty.
    *   **Check:** `grep "networks:" src/docker-compose.yml` -> Should find matches.
*   **Dockerfiles:**
    *   **Check:** Open all Dockerfiles (`ls src/*/Dockerfile`).
    *   **Forbidden:** `tail -f`, `sleep infinity`, infinite loops in ENTRYPOINT.
    *   **Running Background:** Ensure `nginx` or `php-fpm` are not running with `&` in a script that stays alive artificially. They should utilize foreground flags (e.g., `nginx -g 'daemon off;'`, `php-fpm -F`).
*   **OS Version:**
    *   **Check:** `grep FROM src/*/Dockerfile`.
    *   **Requirement:** Penultimate stable version (Alpine 3.19 or Debian Bullseye/Oldstable).
    *   **Current State:** If you use `bookworm` (Debian 12) or `alpine:latest` / `3.20`, ensure to explain why if the evaluator questions it, or verify the exact "penultimate" requirement date.

---

## 3. Mandatory Part

### Activity Overview
*   **Dialog:** Explain Docker vs VMs (Docker uses host kernel, lighter; VM uses full OS). Explain directory structure (segregation of services).

### README Check
*   **Check:** `cat README.md`. First line must follow format. Sections: Description, Instructions, Resources + AI Usage.

### Documentation Check
*   **Check:** `ls USER_DOC.md DEV_DOC.md`. Inspect contents strictly.

### Simple Setup
*   **Action:** `make` or `make up`. Wait for build.
*   **Check:** Open `https://login.42.fr` (replace `login` with yours).
    *   **Success:** WordPress site loads.
    *   **Success:** HTTPS warning (Self-signed) appears.
    *   **Failure:** Connection refused, or HTTP works (it shouldn't).

### Docker Basics
*   **Check:** `ls src/*/Dockerfile` (One per service).
*   **Check:** `docker images`. Look for custom image names (e.g., `inception-nginx`, `inception-wordpress`).
*   **Constraint:** DO NOT use `FROM wordpress` or `FROM nginx` directly. Must be `FROM alpine/debian` + install commands.

### Docker Network
*   **Check:** `docker network ls`. Verify a network named `inception` (or project name) exists.
*   **Check:** `docker inspect inception-nginx` -> check "Networks" section.

### NGINX with SSL/TLS
*   **Tool:** `src/nginx/Dockerfile`.
*   **Verification:**
    1.  `docker compose ps` -> Check nginx is Up.
    2.  Check port 443 open.
    3.  Check port 80 closed.
    4.  **TLS Check:** In browser dev tools > Security, or run:
        ```bash
        openssl s_client -connect localhost:443 -tls1_2
        openssl s_client -connect localhost:443 -tls1_3
        ```
        Both should succeed (or at least one).

### WordPress & MariaDB Volumes
*   **Check:** `docker volume ls`.
*   **Inspect:** `docker volume inspect <mariadb_vol_name>`.
    *   **Requirement:** Mountpoint should be `/home/login/data/mariadb` (on host).
*   **Inspect:** `docker volume inspect <wordpress_vol_name>`.
    *   **Requirement:** Mountpoint should be `/home/login/data/wordpress` (on host).
*   **Action:**
    1.  Login to WP Admin. Create a post.
    2.  `docker exec -it mariadb mariadb -u <user> -p` -> Login SQL -> `SHOW TABLES;`.

### Persistence Check
*   **Action:** `make down` -> Restart VM (optional but recommended) -> `make up`.
*   **Verification:** Is the post you created still there? (It should be).

### Configuration Modification
*   **Challenge:** Evaluator asks to change a port (e.g., Nginx 443 -> 8443).
*   **Solution Strategy:**
    1.  Modify `src/docker-compose.yml`: `ports: - "8443:443"`.
    2.  Modify `src/nginx/default.conf` (if strictly internal port change requested).
    3.  Run `make re` (rebuild).
    4.  Access valid on new port.

---

## 4. Bonus Verification

### 1. Redis Cache
*   **Check:** `src/redis/Dockerfile` exists.
*   **Verify Functionality:**
    1.  Go to WordPress Admin.
    2.  Plugins -> Redis Object Cache -> Settings.
    3.  Status should be **"Connected"**.
    4.  Alternatively: `docker exec -it redis redis-cli monitor` and browse the site. You should see commands flying by.

### 2. FTP Server (Detailed Check)
This checks if you can upload files to the WordPress volume via FTP.

*   **Dockerfile:** `src/ftp/Dockerfile` exists.
*   **Port:** 21.
*   **Client:** Use FileZilla (GUI) or `ftp` (CLI).

**Testing Steps (CLI):**
1.  **Install client:** `sudo apt-get install ftp` (if not installed).
2.  **Connect:**
    ```bash
    ftp -p localhost 21
    ```
    *(If running locally. If in VM, use IP).*
3.  **Login:**
    *   **User:** (Check .env, likely `ftpuser` or similar).
    *   **Pass:** (Check .env, `rootpass` or similar).
    *   *Result:* `230 Login successful.`
4.  **List Files:**
    ```ftp
    ls
    ```
    *   *Result:* You should see `index.php`, `wp-config.php`, etc.
5.  **Upload File:**
    ```bash
    # (On host machine)
    touch test_ftp.txt
    ```
    ```ftp
    # (Inside ftp prompt)
    put test_ftp.txt
    ```
    *   *Result:* `226 Transfer complete.`
6.  **Verify file appears in WordPress:**
    ```bash
    docker exec -it wordpress ls -l /var/www/html/test_ftp.txt
    ```
    *   *Result:* File exists.
7.  **Delete File:**
    ```ftp
    delete test_ftp.txt
    ```
    *   *Result:* `250 Delete operation successful.`
8.  **Verify deletion:**
    ```bash
    docker exec -it wordpress ls -l /var/www/html/test_ftp.txt
    ```
    *   *Result:* `No such file or directory`.

### 3. Static Website
*   **Check:** Access `https://login.42.fr/site` (or configured route).
*   **Result:** Should show resume/showcase site. NOT PHP info, NOT WordPress.

### 4. Adminer
*   **Check:** Access `https://login.42.fr/adminer`.
*   **Action:** Login using MariaDB credentials (server: `mariadb`, user: `...`, pass: `...`).
*   **Result:** View database tables UI.

### 5. Choice Service
*   **Check:** Explain what it is (e.g., Portainer, Uptime Kuma) and how it helps.
