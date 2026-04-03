#!/usr/bin/env bash
# build.sh
# Build a Docker image from a pixi.lock file.
#
# Usage:
#   ./build.sh --lock <path/to/pixi.lock> --tag <registry/image:tag> [options]
#
# Options:
#   --lock          Path to pixi.lock (required)
#   --tag           Image tag to build (required)
#   --pixi-version  pixi version to use, e.g. "0.41.4" (default: latest)
#   --              Remaining args are forwarded to docker build

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"

# ── Args ───────────────────────────────────────────────────────────────────────
LOCK_FILE=""
IMAGE_TAG=""
PIXI_VERSION="latest"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lock)          LOCK_FILE="$2";    shift 2 ;;
    --tag)           IMAGE_TAG="$2";    shift 2 ;;
    --pixi-version)  PIXI_VERSION="$2"; shift 2 ;;
    --)              shift; break ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LOCK_FILE" ]]  && { echo "Error: --lock is required" >&2; exit 1; }
[[ -z "$IMAGE_TAG" ]]  && { echo "Error: --tag is required" >&2; exit 1; }
[[ ! -f "$LOCK_FILE" ]] && { echo "Error: lock file not found: $LOCK_FILE" >&2; exit 1; }

# ── Find project config ────────────────────────────────────────────────────────
LOCK_DIR="$(dirname "$(realpath "$LOCK_FILE")")"
PIXI_TOML="${LOCK_DIR}/pixi.toml"
PYPROJECT="${LOCK_DIR}/pyproject.toml"

if [[ ! -f "$PIXI_TOML" && ! -f "$PYPROJECT" ]]; then
  echo "Error: neither pixi.toml nor pyproject.toml found alongside pixi.lock" >&2
  exit 1
fi

echo "Image tag:    ${IMAGE_TAG}"
echo "pixi version: ${PIXI_VERSION}"

# ── Build context ──────────────────────────────────────────────────────────────
BUILD_CTX="$(mktemp -d)"
trap 'rm -rf "$BUILD_CTX"' EXIT

cp "$LOCK_FILE" "${BUILD_CTX}/pixi.lock"
cp "$DOCKERFILE" "${BUILD_CTX}/Dockerfile"
[[ -f "$PIXI_TOML" ]] && cp "$PIXI_TOML" "${BUILD_CTX}/pixi.toml"
[[ -f "$PYPROJECT" ]] && cp "$PYPROJECT" "${BUILD_CTX}/pyproject.toml"

# ── Docker build ───────────────────────────────────────────────────────────────
docker build \
  --build-arg PIXI_VERSION="${PIXI_VERSION}" \
  --tag "${IMAGE_TAG}" \
  "$@" \
  "${BUILD_CTX}"

echo ""
echo "Done. Image built: ${IMAGE_TAG}"
