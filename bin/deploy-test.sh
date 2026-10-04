#!/usr/bin/env bash
set -Eeuo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

: "${EC2_USER:?Set EC2_USER before running this script.}"
: "${EC2_HOST:?Set EC2_HOST before running this script.}"

remote_dir="${EC2_DIR:-/home/${EC2_USER}/laminas-safari-deployment}"
target="${EC2_USER}@${EC2_HOST}"

if [[ ! "$remote_dir" =~ ^[A-Za-z0-9_./-]+$ ]]; then
    echo "EC2_DIR contains unsupported characters: $remote_dir" >&2
    exit 1
fi

required_files=(
    Dockerfile
    .dockerignore
    compose.yaml
    compose.build.yaml
    apache-vhost.conf
    .env.example
    runtime-config/local.php
    input/laminas-app.tar.gz
    input/horsesns_safari-dev.sql.gz
)

for relative_path in "${required_files[@]}"; do
    if [[ ! -e "$project_dir/$relative_path" ]]; then
        echo "Missing deployment file: $project_dir/$relative_path" >&2
        exit 1
    fi
done

command -v ssh >/dev/null 2>&1 || { echo 'ssh is required.' >&2; exit 1; }
command -v scp >/dev/null 2>&1 || { echo 'scp is required.' >&2; exit 1; }

echo "Creating $remote_dir on $target..."
ssh "$target" "mkdir -p -- '$remote_dir'"

echo "Copying deployment configuration..."
scp \
    "$project_dir/Dockerfile" \
    "$project_dir/.dockerignore" \
    "$project_dir/compose.yaml" \
    "$project_dir/compose.build.yaml" \
    "$project_dir/apache-vhost.conf" \
    "$project_dir/.env.example" \
    "$target:$remote_dir/"

echo "Copying scripts, runtime configuration, and payloads..."
scp -r \
    "$project_dir/bin" \
    "$project_dir/runtime-config" \
    "$project_dir/input" \
    "$target:$remote_dir/"

ssh "$target" "chmod +x '$remote_dir'/bin/*.sh '$remote_dir'/bin/lib/*.sh"

echo
echo "Temporary deployment completed: $target:$remote_dir"
echo "Next steps on the EC2 instance:"
echo "  cd '$remote_dir'"
echo "  cp .env.example .env"
echo "  chmod 600 .env"
echo "  vi .env"
echo "  bash bin/run-local.sh"
