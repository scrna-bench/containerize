#!/usr/bin/env bash
# test-build.sh
# Builds a test image from the local pixi.lock and verifies all packages import.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="scrna-bench/pixi-test:latest"

# Build
"${SCRIPT_DIR}/../build.sh" --lock "${SCRIPT_DIR}/pixi.lock" --tag "$IMAGE"

echo ""
echo "Verifying packages import in container..."
docker run --rm "$IMAGE" python -c "
import requests
print('OK: requests', requests.__version__)
"

echo ""
echo "All packages imported successfully."
