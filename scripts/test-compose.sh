#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Use only the checked-in dummy environment and a separate Compose project.
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-tc03-integration}"
export COMPOSE_FILE="docker-compose.yaml:docker-compose.integration.yaml"
unset SERVICE_API_KEY
docker compose --env-file .env.example config --quiet
docker compose --env-file .env.example up --build -d --wait --wait-timeout 240
python3 scripts/integration/test-flow.py
