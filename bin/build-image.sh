#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib/compose.sh"

require_env
[[ -f "$project_dir/app/composer.json" ]] || {
    echo "Application source is missing from $project_dir/app; run bin/extract-source.sh first." >&2
    exit 1
}

export LAMINAS_BUILD_MODE=1
source "$script_dir/lib/compose.sh"
compose_run build app

