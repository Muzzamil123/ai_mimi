#!/usr/bin/env bash
# One-command local setup: prepares env, builds images, starts the stack,
# and waits for the API health endpoint to report ready.
set -euo pipefail

cd "$(dirname "$0")/../.."

if [ ! -f .env ]; then
  echo "==> Creating .env from .env.example"
  cp .env.example .env
fi

echo "==> Building images"
docker compose build

echo "==> Starting stack"
docker compose up -d

API_PORT="${API_PORT_HOST:-3000}"
echo "==> Waiting for API health at http://localhost:${API_PORT}/api/v1/health"
for _ in $(seq 1 60); do
  if curl -fsS "http://localhost:${API_PORT}/api/v1/health" >/dev/null 2>&1; then
    echo "==> API is healthy"
    curl -fsS "http://localhost:${API_PORT}/api/v1/health"; echo
    echo "==> Frontend: http://localhost:${WEB_PORT_HOST:-5173}"
    exit 0
  fi
  sleep 2
done

echo "!! API did not become healthy in time. Check: docker compose logs api" >&2
exit 1
