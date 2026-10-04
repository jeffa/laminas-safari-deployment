#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib/compose.sh"

require_env
dump="$project_dir/input/horsesns_safari-dev.sql.gz"
[[ -f "$dump" ]] || { echo "Missing database payload: $dump" >&2; exit 1; }

set -a
# The project .env uses shell-compatible assignments and is also consumed by Compose.
# shellcheck disable=SC1091
source "$project_dir/.env"
set +a

compose_run up -d db
wait_for_service db

table_count="$(compose_run exec -e MYSQL_PWD="${DB_PASSWORD:-}" -T db mariadb \
    -u"${DB_USER:-horsesns_safari}" -N -B \
    -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME:-horsesns_safari}' AND table_name='tblSessions';" \
    | tr -d '[:space:]')"

if [[ "${FORCE_DB_RESTORE:-0}" != 1 && "$table_count" == 1 ]]; then
    echo 'Database schema is already present; skipping restore.'
    exit 0
fi

echo "Restoring $dump into the db service..."
gzip -dc "$dump" | compose_run exec -e MYSQL_PWD="${DB_ROOT_PASSWORD:-}" -T db mariadb -uroot
touch "$project_dir/.db-restored"
echo 'Database restore completed.'

