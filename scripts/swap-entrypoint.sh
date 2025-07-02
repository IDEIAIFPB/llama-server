#!/bin/bash
set -euo pipefail

echo "[INFO] Starting llama-swap..."

if ! command -v nvidia-smi &>/dev/null; then
  echo "[WARNING] NVIDIA runtime not available inside the container."
else
  echo "[INFO] NVIDIA runtime detected:"
  nvidia-smi
fi

echo "[INFO] Launching app with args: $@"
exec /app/llama-swap "$@"
