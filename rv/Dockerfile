# Dockerfile.rv
# Two-stage build:
#   builder  - fetch rv, install system deps via rv sysdeps, populate R library via rv sync
#   runtime  - r-ver + runtime shared libs + R library only; no rv, no build tools
#
# Build args:
#   R_VERSION  - R version string, e.g. "4.5"  (parsed from rv.lock by build-rv.sh)
#   RV_VERSION - rv release tag, e.g. "v0.20.0" (omit for latest)

ARG R_VERSION=4.5
ARG RV_VERSION=""

# ── Stage 1: builder ───────────────────────────────────────────────────────────
FROM rocker/r-ver:${R_VERSION} AS builder

ARG RV_VERSION
RUN set -eux; \
  apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*; \
  if [ -z "$RV_VERSION" ]; then \
  curl -sSL https://raw.githubusercontent.com/A2-ai/rv/refs/heads/main/scripts/install.sh | bash; \
  mv ~/.local/bin/rv /usr/local/bin/rv; \
  else \
  ARCH="$(dpkg --print-architecture)"; \
  case "$ARCH" in \
  amd64) RV_ARCH="x86_64" ;; \
  arm64) RV_ARCH="aarch64" ;; \
  *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
  esac; \
  curl -fsSL "https://github.com/A2-ai/rv/releases/download/${RV_VERSION}/rv-${RV_VERSION}-${RV_ARCH}-unknown-linux-musl.tar.gz" \
  | tar -xz -C /usr/local/bin rv; \
  fi

WORKDIR /project
COPY rproject.toml ./rproject.toml
COPY rv.lock ./rv.lock

# Resolve system deps, install them, sync the R library, then move it to a fixed
# path so the runtime stage can COPY it without knowing the R version or arch.
RUN set -eux; \
  SYSDEPS="$(rv sysdeps)"; \
  if [ -n "$SYSDEPS" ]; then \
  apt-get update && echo "$SYSDEPS" | xargs apt-get install -y --no-install-recommends; \
  rm -rf /var/lib/apt/lists/*; \
  fi; \
  echo "$SYSDEPS" > /runtime-deps.txt; \
  rv sync; \
  mv "$(rv library)" /rvlib

# ── Stage 3: runtime ───────────────────────────────────────────────────────────
FROM rocker/r-ver:${R_VERSION}

# Install runtime shared libs only (no -dev headers, no rv, no compiler)
COPY --from=builder /runtime-deps.txt /tmp/runtime-deps.txt
RUN set -eux; \
  PKGS="$(cat /tmp/runtime-deps.txt | tr '\n' ' ')"; \
  if [ -n "$PKGS" ]; then \
  apt-get update; \
  echo "$PKGS" | xargs apt-get install -y --no-install-recommends; \
  rm -rf /var/lib/apt/lists/*; \
  fi; \
  rm /tmp/runtime-deps.txt

# R_LIBS_USER is the standard env var R checks for the user library path.
COPY --from=builder /rvlib /rvlib
ENV R_LIBS=/rvlib

CMD ["/bin/bash"]
