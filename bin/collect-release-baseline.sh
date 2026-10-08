#!/usr/bin/env bash
set -Eeuo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
output_file="${1:-$project_dir/docs/RELEASE_BASELINE-$(date +%Y%m%d-%H%M%S).md}"

die() {
    echo "Error: $*" >&2
    exit 1
}

prompt_value() {
    local label="$1"
    local default_value="${2:-}"
    local value

    if [[ -n "$default_value" ]]; then
        read -r -p "$label [$default_value]: " value
        printf '%s' "${value:-$default_value}"
    else
        read -r -p "$label: " value
        printf '%s' "$value"
    fi
}

sha256_file() {
    local file="$1"
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    else
        die 'Neither shasum nor sha256sum is available.'
    fi
}

valid_sha256() {
    [[ "$1" =~ ^[[:xdigit:]]{64}$ ]]
}

valid_commit_sha() {
    [[ "$1" =~ ^[[:xdigit:]]{40}$ ]]
}

echo 'Release baseline wizard'
echo 'This records public identifiers and checksums only; do not enter secrets.'
echo

default_commit=''
if git -C "$project_dir" rev-parse HEAD >/dev/null 2>&1; then
    default_commit="$(git -C "$project_dir" rev-parse HEAD)"
fi
deployment_sha="$(prompt_value 'Deployment project commit SHA' "$default_commit")"
valid_commit_sha "$deployment_sha" || die 'Deployment SHA must be 40 hexadecimal characters.'

source_file="$(prompt_value 'Source archive path' "$project_dir/input/laminas-app.tar.gz")"
[[ -f "$source_file" ]] || die "Source archive not found: $source_file"
source_sha="$(sha256_file "$source_file")"
echo "Source archive SHA-256: $source_sha"

database_file="$(prompt_value 'Database dump path' "$project_dir/input/horsesns_safari-dev.sql.gz")"
[[ -f "$database_file" ]] || die "Database dump not found: $database_file"
database_sha="$(sha256_file "$database_file")"
echo "Database dump SHA-256: $database_sha"

default_image=''
if [[ -f "$project_dir/.env" ]]; then
    default_image="$(sed -n 's/^APP_IMAGE=//p' "$project_dir/.env" | head -n 1 | sed "s/^['\"]//; s/['\"]$//")"
fi
image_ref="$(prompt_value 'ECR image reference' "$default_image")"
[[ -n "$image_ref" ]] || die 'An image reference is required.'

image_tag="$(sed 's/.*://' <<< "$image_ref")"
image_digest=''
if command -v docker >/dev/null 2>&1 && docker image inspect "$image_ref" >/dev/null 2>&1; then
    repo_digest="$(docker image inspect "$image_ref" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)"
    if [[ "$repo_digest" == *@sha256:* ]]; then
        image_digest="${repo_digest##*@}"
    fi
fi
if [[ -z "$image_digest" ]]; then
    image_digest="$(prompt_value 'ECR image digest (sha256:...)')"
fi
[[ "$image_digest" =~ ^sha256:[[:xdigit:]]{64}$ ]] || die 'Image digest must look like sha256 followed by 64 hexadecimal characters.'

mkdir -p "$(dirname -- "$output_file")"
cat > "$output_file" <<EOF
# Release Baseline

Recorded: $(date +%Y-%m-%d)

## Deployment project

```text
Commit SHA: $deployment_sha
```

## Application image

```text
Image reference: $image_ref
Image tag: $image_tag
Image digest: $image_digest
```

## Input payloads

```text
Source archive: $(basename -- "$source_file")
Source archive SHA-256: $source_sha
Database dump: $(basename -- "$database_file")
Database dump SHA-256: $database_sha
```

## Validation notes

Complete this section after testing the image:

- Application startup: pending
- Password reset email: pending
- Password reset and login: pending
- Integration/browser workflows: pending

EOF

echo
echo "Baseline written to: $output_file"
echo 'Review the file, add validation results, then commit it if appropriate.'
