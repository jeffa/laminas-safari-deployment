#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "$script_dir/.." && pwd)"

if [[ ! -f "$project_dir/.env" ]]; then
    echo "Missing $project_dir/.env; copy .env.example to .env and set local values." >&2
    exit 1
fi

if [[ ! -f "$project_dir/app/composer.json" ]]; then
    "$script_dir/extract-source.sh"
fi

"$script_dir/build-image.sh"

export LAMINAS_BUILD_MODE=1
source "$script_dir/lib/compose.sh"
compose_run up -d db
wait_for_service db

"$script_dir/restore-database.sh"

compose_run up -d app
wait_for_service app
compose_run exec app php bin/clear-config-cache.php

health_url="${APP_HEALTH_URL:-http://localhost/}"
attempts="${APP_HEALTH_ATTEMPTS:-30}"
for ((attempt = 1; attempt <= attempts; attempt++)); do
    if curl --fail --silent --show-error --output /dev/null "$health_url"; then
        printf '\nApplication is responding at %s\n' "$health_url"
        compose_run ps
        compose_run exec app composer check-platform-reqs --no-dev
        echo 'Local Laminas stack is running.'
        exit 0
    fi
    printf 'Waiting for HTTP readiness (%s/%s)...\n' "$attempt" "$attempts"
    sleep 2
done

echo "Timed out waiting for HTTP readiness at $health_url." >&2
compose_run logs --tail=100 app db >&2 || true
exit 1
