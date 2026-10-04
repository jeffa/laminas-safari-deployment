#!/usr/bin/env bash

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
compose_files=(-f "$project_dir/compose.yaml")

if [[ "${LAMINAS_BUILD_MODE:-0}" == "1" ]]; then
    compose_files+=(-f "$project_dir/compose.build.yaml")
fi

if docker compose version >/dev/null 2>&1; then
    compose=(docker compose "${compose_files[@]}")
elif command -v docker-compose >/dev/null 2>&1; then
    compose=(docker-compose "${compose_files[@]}")
else
    echo 'Docker Compose was not found. Install Docker Desktop or Docker Compose.' >&2
    return 1
fi

compose_run() {
    "${compose[@]}" "$@"
}

require_env() {
    if [[ ! -f "$project_dir/.env" ]]; then
        echo "Missing $project_dir/.env; copy .env.example to .env and set local values." >&2
        return 1
    fi
}

wait_for_service() {
    local service="$1"
    local attempts="${2:-60}"
    local container_id status health attempt

    for ((attempt = 1; attempt <= attempts; attempt++)); do
        container_id="$(compose_run ps -q "$service" 2>/dev/null || true)"
        if [[ -n "$container_id" ]]; then
            status="$(docker inspect -f '{{.State.Status}}' "$container_id" 2>/dev/null || true)"
            health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container_id" 2>/dev/null || true)"
            if [[ "$status" == running && ( "$health" == healthy || "$health" == none ) ]]; then
                echo "$service is ready ($health)."
                return 0
            fi
        fi
        printf 'Waiting for %s (%s/%s)...\n' "$service" "$attempt" "$attempts"
        sleep 2
    done

    echo "Timed out waiting for $service." >&2
    return 1
}

