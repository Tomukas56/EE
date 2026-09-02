#!/usr/bin/env bash
# Start Colima (if needed) and the lab Postgres from docker-compose.yml.
# Host port 5433. Point backend/.env DATABASE_URL at 127.0.0.1:5433.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export DOCKER_HOST="${DOCKER_HOST:-unix://${HOME}/.colima/default/docker.sock}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker CLI not found. Install Colima and Docker CLI, then retry." >&2
  exit 1
fi

if command -v colima >/dev/null 2>&1; then
  if ! colima status >/dev/null 2>&1; then
    echo "Starting Colima..."
    colima start --vm-type vz
  fi
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker engine is not reachable at ${DOCKER_HOST}." >&2
  exit 1
fi

cd "$ROOT"
echo "Starting Postgres on host port 5433..."
docker compose up -d db

echo "Waiting for Postgres to accept connections..."
for _ in $(seq 1 40); do
  if docker compose exec -T db sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' >/dev/null 2>&1; then
    echo "Postgres is ready on 127.0.0.1:5433"
    docker compose ps db
    exit 0
  fi
  sleep 1
done

echo "Postgres did not become ready in time. Check: docker compose logs db" >&2
exit 1
