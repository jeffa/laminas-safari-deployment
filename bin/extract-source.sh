#!/usr/bin/env bash
set -Eeuo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
archive="$project_dir/input/laminas-app.tar.gz"
destination="$project_dir/app"

[[ -f "$archive" ]] || { echo "Missing source payload: $archive" >&2; exit 1; }
rm -rf "$destination"
mkdir -p "$destination"
tar -xzf "$archive" -C "$destination" --strip-components=1
echo "Extracted application source into $destination"

