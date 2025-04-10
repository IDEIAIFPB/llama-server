.PHONY: up down restart build logs check-gpu
PROJECT_NAME=llama-server

down:
	docker compose -p $(PROJECT_NAME) down

up:
	docker compose -p $(PROJECT_NAME) up -d

update:
	docker compose -p $(PROJECT_NAME) pull

restart:
	docker compose -p $(PROJECT_NAME) down && docker compose -p $(PROJECT_NAME) up -d

logs:
	docker compose -p $(PROJECT_NAME) logs -f

build:
	docker compose -p $(PROJECT_NAME) build --no-cache

check-gpu:
	docker run --rm --runtime=nvidia nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
