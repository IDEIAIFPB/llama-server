.PHONY: up down down-volumes update prune restart logs build check-gpu

PROJECT_NAME = llama-server

ifeq ($(platform),cpu)
  COMPOSE_FILE = docker-compose.cpu.yml
else ifeq ($(platform),cuda)
  COMPOSE_FILE = docker-compose.cuda.yml
else
  COMPOSE_FILE = docker-compose.cpu.yml
endif

COMPOSE_CMD = docker compose -p $(PROJECT_NAME) -f $(COMPOSE_FILE)

up:
	$(COMPOSE_CMD) up -d

down:
	$(COMPOSE_CMD) down

down-volumes:
	$(COMPOSE_CMD) down --volumes

update:
	$(COMPOSE_CMD) pull && $(COMPOSE_CMD) up -d

prune:
	docker system prune -a --volumes -f

restart:
	$(COMPOSE_CMD) down && $(COMPOSE_CMD) up -d

logs:
	$(COMPOSE_CMD) logs -f

build:
	$(COMPOSE_CMD) build --no-cache

check-gpu:
	docker run --rm --runtime=nvidia nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
