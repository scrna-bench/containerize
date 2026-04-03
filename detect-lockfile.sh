#!/usr/bin/env bash
# detect-lockfile.sh
# Detect the lock file type in a given directory and output LOCK_TYPE and LOCK_FILE.
# Writes to GITHUB_OUTPUT if running in a GitHub Actions environment, otherwise prints.
#
# Usage:
#   bash detect-lockfile.sh <directory> [lock-type]
#
#   lock-type: "rv" or "pixi" — required if both lock files are present

set -euo pipefail

DIR="${1:?Usage: detect-lockfile.sh <directory> [lock-type]}"
EXPLICIT_TYPE="${2:-}"

HAS_RV=false
HAS_PIXI=false

if [[ -f "${DIR}/rv.lock" ]]; then
  if [[ ! -f "${DIR}/rproject.toml" ]]; then
    echo "Error: rv.lock found in ${DIR} but rproject.toml is missing" >&2
    exit 1
  fi
  HAS_RV=true
fi

if [[ -f "${DIR}/pixi.lock" ]]; then
  if [[ ! -f "${DIR}/pixi.toml" && ! -f "${DIR}/pyproject.toml" ]]; then
    echo "Error: pixi.lock found in ${DIR} but neither pixi.toml nor pyproject.toml is present" >&2
    exit 1
  fi
  HAS_PIXI=true
fi

if [[ "$HAS_RV" == false && "$HAS_PIXI" == false ]]; then
  echo "Error: no rv.lock or pixi.lock found in ${DIR}" >&2
  exit 1
fi

if [[ "$HAS_RV" == true && "$HAS_PIXI" == true ]]; then
  if [[ -z "$EXPLICIT_TYPE" ]]; then
    echo "Error: both rv.lock and pixi.lock found in ${DIR} — set lock-type to 'rv' or 'pixi'" >&2
    exit 1
  fi
  LOCK_TYPE="$EXPLICIT_TYPE"
elif [[ "$HAS_RV" == true ]]; then
  LOCK_TYPE="rv"
else
  LOCK_TYPE="pixi"
fi

case "$LOCK_TYPE" in
  rv)   LOCK_FILE="${DIR}/rv.lock" ;;
  pixi) LOCK_FILE="${DIR}/pixi.lock" ;;
  *)    echo "Error: unknown lock-type '${LOCK_TYPE}' — must be 'rv' or 'pixi'" >&2; exit 1 ;;
esac

echo "Detected lock type: ${LOCK_TYPE}"
echo "Lock file:          ${LOCK_FILE}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "lock-type=${LOCK_TYPE}" >> "$GITHUB_OUTPUT"
  echo "lock-file=${LOCK_FILE}" >> "$GITHUB_OUTPUT"
fi
