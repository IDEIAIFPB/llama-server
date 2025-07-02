#!/bin/bash
set -e

CONFIG_FILE="${1:-default.yml}"

echo "[INFO] Starting TabbyAPI..."
echo "Using config file: /app/config/${CONFIG_FILE}"

cp "/app/config/${CONFIG_FILE}" /app/config.yml || {
  echo "[ERROR] Failed to copy ${CONFIG_FILE}"
  exit 1
}

if [ $# -ge 1 ]; then
  shift
fi

echo "[INFO] Launching TabbyAPI with args: $@"
exec python3 /app/main.py "$@"
