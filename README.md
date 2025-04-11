# Llama Server

This project hosts a GPU-enabled Llama server container using llama.cpp and llama-swap. It is designed to quickly set up and serve LLM models using Docker and NVIDIA CUDA. The server configuration is flexible via environment variables and configuration files.

## Features

- **GPU-Acceleration:** Uses NVIDIA CUDA for high-performance inference.
- **Configurable:** Choose your configuration file dynamically.
- **Modular:** Easily swap configurations and models.
- **Local Development:** Includes a simple NGINX reverse proxy for local testing.


## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)
- NVIDIA drivers and [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) for GPU access

### Configuration

By default, the service mounts the configuration file located at `./config/simple.yaml` onto `/app/config.yaml` in the container.

If you wish to use a different configuration file, you can do so by setting the `CONFIG_FILE` environment variable in the `.env` file.

### Running the Project

To build and run the containers, use the provided Makefile commands. You can instead, use the docker compose commands directly, but the Makefile simplify some of the most common commands.

```makefile
up            # Start services
down          # Stop all services
down-volumes  # Stop all services and remove volumes
update        # Update container images
prune         # Prune unused images, containers and volumes
restart       # Rebuild and restart
logs          # Stream all logs
build         # Force rebuild all images
check-gpu     # Verify GPU access
```

### Health Checks

Both the Llama server and NGINX have health-checks configured. If the health-check fails, Docker Compose will restart the container automatically.

## Local Testing

You can access the active Llama server via:

- **http://llama-server.local** (proxied by `nginx-proxy`)

Make sure to add this to your `/etc/hosts`:

```bash
127.0.0.1 llama-server.local
```

## Troubleshooting

- **GPU Not Detected:** Use `make check-gpu` to test GPU visibility.
- **Configuration Issues:** Ensure you set the correct `CONFIG_FILE` variable or use the proper default in your `.env`.
- **Port Conflicts:** Verify that port mappings in the Compose file do not conflict with other services.

## Contributing

If you find any issues or want to contribute improvements, please open an issue or submit a pull request.