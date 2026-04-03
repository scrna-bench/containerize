#!/usr/bin/env bash
# test-build.sh
# Builds a test image from the local rv.lock and verifies all locked packages load.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="scrna-bench/rv-test:latest"

# Build
"${SCRIPT_DIR}/../build.sh" --lock "${SCRIPT_DIR}/rv.lock" --tag "$IMAGE"

# Extract package names from the lock file and try to load each one in R
PACKAGES="$(grep '^name = ' "${SCRIPT_DIR}/rv.lock" | sed 's/name = "\(.*\)"/\1/')"

echo ""
echo "Verifying packages load in container..."
docker run --rm "$IMAGE" Rscript -e "
  pkgs <- strsplit('$(echo "$PACKAGES" | tr '\n' ' ')', ' ')[[1]]
  for (p in pkgs) { library(p, character.only = TRUE); cat('OK:', p, '\n') }
"

echo ""
echo "All packages loaded successfully."
