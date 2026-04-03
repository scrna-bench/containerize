# Dockerfile.pixi
# Two-stage build:
#   builder  - ghcr.io/prefix-dev/pixi base, install environment via pixi install --locked
#   runtime  - minimal base + self-contained conda env; no pixi, no build tools
#
# Build args:
#   PIXI_VERSION - pixi image tag, e.g. "0.41.4"

ARG PIXI_VERSION=0.41.4

# ── Stage 1: builder ───────────────────────────────────────────────────────────
FROM ghcr.io/prefix-dev/pixi:${PIXI_VERSION} AS builder

WORKDIR /project

# Build context contains pixi.lock and whichever config is present
# (pixi.toml, pyproject.toml, or both)
COPY . .

RUN pixi install --locked
RUN mv .pixi/envs/default /pixi-env

# ── Stage 2: runtime ───────────────────────────────────────────────────────────
FROM debian:bookworm-slim

COPY --from=builder /pixi-env /pixi-env
ENV PATH="/pixi-env/bin:$PATH"

CMD ["/bin/bash"]
