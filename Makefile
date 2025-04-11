.PHONY: up down down-volumes update prune restart logs build check-gpu
PROJECT_NAME=llama-server

up:
	docker compose -p $(PROJECT_NAME) up -d

down:
	docker compose -p $(PROJECT_NAME) down

down-volumes:
	docker compose -p $(PROJECT_NAME) down --volumes

update:
	docker-compose pull && docker-compose up -d

prune:
	docker system prune -a --volumes -f

restart:
	docker compose -p $(PROJECT_NAME) down && docker compose -p $(PROJECT_NAME) up -d

logs:
	docker compose -p $(PROJECT_NAME) logs -f

build:
	docker compose -p $(PROJECT_NAME) build --no-cache

check-gpu:
	docker run --rm --runtime=nvidia nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
