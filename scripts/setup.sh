#!/bin/bash
set -euo pipefail

echo "[INFO] Checking host environment..."

if ! command -v docker &>/dev/null; then
  echo "[ERROR] Docker not installed. Install Docker first: https://docs.docker.com/get-docker/"
  exit 1
fi

if ! docker info | grep -q nvidia; then
  echo "[WARNING] NVIDIA Container Runtime not detected in Docker."
  echo "Follow this guide to install: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
  exit 1
fi

echo "[INFO] Pulling images..."
docker pull ghcr.io/mostlygeek/llama-swap:cuda
docker pull ghcr.io/ggml-org/llama.cpp:server-cuda

echo "[✅] Host setup complete. You're ready to run:"
echo "   docker compose up --build"
