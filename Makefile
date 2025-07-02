PROJECT_NAME = llm-server

ifeq ($(platform),cpu)
  COMPOSE_FILE = docker-compose.cpu.yml
else ifeq ($(platform),cuda)
  COMPOSE_FILE = docker-compose.cuda.yml
else
  COMPOSE_FILE = docker-compose.cpu.yml
endif

COMPOSE_CMD = docker compose -p $(PROJECT_NAME) -f $(COMPOSE_FILE)


######### Comandos auxiliares #########
.PHONY: help clean
help: ## Mostrar make targets e args
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf " \033[36m%-20s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo "\nArgs:"
	@printf "  \033[36m%-18s\033[0m  %s\n" "platform" "$(platform) (default: cpu). Para comandos relacionados ao docker compose, passe com 'make up platform=cuda' \
	para usar docker-compose.cuda.yml. Por padrão é utilizado docker-compose.cpu.yml"


######### Comandos para Docker Compose #########
.PHONY: up down down-volumes update prune restart logs build check-gpu
up: ## Inicia os containers com Docker Compose
	$(COMPOSE_CMD) up -d

down: ## Para os containers com Docker Compose
	$(COMPOSE_CMD) down

down-volumes: ## Remove volumes junto com os containers com Docker Compose
	$(COMPOSE_CMD) down --volumes

update: ## Atualiza imagens utilizadas nos serviços com Docker Compose
	$(COMPOSE_CMD) pull && $(COMPOSE_CMD) up -d

restart: ## Reinicia todos os serviços com Docker Compose
	$(COMPOSE_CMD) down && $(COMPOSE_CMD) up -d

logs: ## Mostra os logs em tempo real com Docker Compose
	$(COMPOSE_CMD) logs -f

build: ## Build sem cache utilizando Docker Compose
	$(COMPOSE_CMD) build --no-cache

######### Comandos para Docker #########
.PHONY: prune check-gpu
prune: ## Remove containers, volumes e imagens não utilizadas do docker
	docker system prune -a --volumes -f

check-gpu: ## Verifica se docker consegue acessar GPU
	docker run --rm --runtime=nvidia nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
