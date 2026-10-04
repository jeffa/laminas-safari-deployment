#!/usr/bin/env bash
set -Eeuo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
platforms="${PLATFORMS:-linux/amd64,linux/arm64}"
repository="${IMAGE_REPOSITORY:-laminas-safari/local}"
commit="${GIT_COMMIT:-}"
if [[ -z "$commit" ]]; then
    commit="$(git -C "$project_dir" rev-parse HEAD 2>/dev/null || true)"
fi
if [[ -z "$commit" ]]; then
    echo 'No Git commit is available. Set GIT_COMMIT or IMAGE_TAG for a remote source-only checkout.' >&2
    exit 1
fi
tag="${IMAGE_TAG:-$commit}"
builder="${BUILDX_BUILDER:-laminas-safari-builder}"
push="${PUSH:-0}"

command -v docker >/dev/null 2>&1 || { echo 'Docker is required.' >&2; exit 1; }
[[ -f "$project_dir/app/composer.json" ]] || {
    echo "Application source is missing from $project_dir/app; run bin/extract-source.sh first." >&2
    exit 1
}

if ! docker buildx inspect "$builder" >/dev/null 2>&1; then
    if ! builder="$(docker buildx create --name "$builder" --driver docker-container --use 2>/dev/null)"; then
        echo 'Named Buildx builders are unsupported; creating a compatibility builder.' >&2
        builder="$(docker buildx create --driver docker-container --use)"
    fi
else
    docker buildx use "$builder"
fi
docker buildx inspect --bootstrap "$builder" >/dev/null

build_args=(
    --builder "$builder"
    --file "$project_dir/Dockerfile"
    --platform "$platforms"
    --tag "$repository:$tag"
    --label "org.opencontainers.image.revision=$commit"
    --label "org.opencontainers.image.source=laminas-safari-deployment"
    --provenance=true
    --sbom=true
    --progress plain
)

if [[ "$push" == 1 ]]; then
    build_args+=(--push)
else
    if [[ -n "${BUILD_OUTPUT:-}" ]]; then
        build_args+=(--output "type=oci,dest=$BUILD_OUTPUT")
    else
        build_args+=(--output type=cacheonly)
    fi
fi

docker buildx build "${build_args[@]}" "$project_dir"

if [[ "$push" == 1 ]]; then
    echo "Published $repository:$tag for $platforms"
else
    echo "Built $repository:$tag for $platforms"
    if [[ -n "${BUILD_OUTPUT:-}" ]]; then
        echo "OCI output: $BUILD_OUTPUT"
    else
        echo 'Build output retained in the BuildKit cache.'
    fi
fi
