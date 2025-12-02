NAME = inception
DOCKER_COMPOSE_FILE = ./src/docker-compose.yml

all: up

up:
	@mkdir -p /home/nweber/data/mariadb
	@mkdir -p /home/nweber/data/wordpress
	@mkdir -p /home/nweber/data/redis
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d --build

down:
	docker compose -f $(DOCKER_COMPOSE_FILE) down

start:
	docker compose -f $(DOCKER_COMPOSE_FILE) start

stop:
	docker compose -f $(DOCKER_COMPOSE_FILE) stop

restart:
	docker compose -f $(DOCKER_COMPOSE_FILE) restart

logs:
	docker compose -f $(DOCKER_COMPOSE_FILE) logs -f

clean: down
	docker system prune -af

fclean: clean
	docker volume rm $$(docker volume ls -q) || true

re:
	$(MAKE) fclean
	$(MAKE) all

.PHONY: all up down start stop restart logs clean fclean re