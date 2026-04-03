#!/usr/bin/env bash
# build-rv.sh
# Build a Docker image from an rv.lock file using Dockerfile.rv.
#
# Usage:
#   ./build-rv.sh --lock <path/to/rv.lock> --tag <registry/image:tag> [options]
#
# Options:
#   --lock        Path to rv.lock (required)
#   --tag         Image tag to build (required)
#   --rv-version  rv version to use, e.g. "v0.20.0" (default: version in Dockerfile)
#   --            Remaining args are forwarded to docker build

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile.rv"

# ── Args ───────────────────────────────────────────────────────────────────────
LOCK_FILE=""
IMAGE_TAG=""
RV_VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lock)       LOCK_FILE="$2";   shift 2 ;;
    --tag)        IMAGE_TAG="$2";   shift 2 ;;
    --rv-version) RV_VERSION="$2";  shift 2 ;;
    --)           shift; break ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LOCK_FILE" ]]  && { echo "Error: --lock is required" >&2; exit 1; }
[[ -z "$IMAGE_TAG" ]]  && { echo "Error: --tag is required" >&2; exit 1; }
[[ ! -f "$LOCK_FILE" ]] && { echo "Error: lock file not found: $LOCK_FILE" >&2; exit 1; }

# ── Parse R version from rv.lock ───────────────────────────────────────────────
R_VERSION="$(grep -m1 '^r_version' "$LOCK_FILE" | sed 's/r_version *= *"\(.*\)"/\1/')"
[[ -z "$R_VERSION" ]] && { echo "Error: could not parse r_version from $LOCK_FILE" >&2; exit 1; }

echo "R version:  ${R_VERSION}"
echo "Image tag:  ${IMAGE_TAG}"
[[ -n "$RV_VERSION" ]] && echo "rv version: ${RV_VERSION}"

# ── Build context ──────────────────────────────────────────────────────────────
BUILD_CTX="$(mktemp -d)"
trap 'rm -rf "$BUILD_CTX"' EXIT

cp "$LOCK_FILE" "${BUILD_CTX}/rv.lock"
cp "$DOCKERFILE" "${BUILD_CTX}/Dockerfile"

RPROJECT="$(dirname "$LOCK_FILE")/rproject.toml"
if [[ ! -f "$RPROJECT" ]]; then
  echo "Error: rproject.toml not found alongside rv.lock" >&2
  exit 1
fi
cp "$RPROJECT" "${BUILD_CTX}/rproject.toml"

# ── Docker build ───────────────────────────────────────────────────────────────
EXTRA_ARGS=()
[[ -n "$RV_VERSION" ]] && EXTRA_ARGS+=(--build-arg "RV_VERSION=${RV_VERSION}")

docker build \
  --build-arg R_VERSION="${R_VERSION}" \
  "${EXTRA_ARGS[@]}" \
  --tag "${IMAGE_TAG}" \
  "$@" \
  "${BUILD_CTX}"

echo ""
echo "Done. Image built: ${IMAGE_TAG}"
