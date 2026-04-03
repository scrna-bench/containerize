# containerization

Tooling to build reproducible R/Python environments from package lock files into Docker images.

## Backends

| | [`rv`](https://github.com/A2-ai/rv) | [`pixi`](https://pixi.sh) |
|---|---|---|
| Lock file | `rv.lock` | `pixi.lock` |
| Builder base | `rocker/r-ver` | `ghcr.io/prefix-dev/pixi` |
| Runtime base | `rocker/r-ver` | `debian:bookworm-slim` |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- `rv` or `pixi` to manage lock files

## Usage

### rv

`rv.lock` and `rproject.toml` must be in the same directory.

```sh
./rv/build.sh --lock <path/to/rv.lock> --tag <registry/image:tag>
```

| Option | Required | Default |
|---|---|---|
| `--lock` | yes | |
| `--tag` | yes | |
| `--rv-version` | no | latest |

### pixi

`pixi.lock` and either `pixi.toml` or `pyproject.toml` must be in the same directory.

```sh
./pixi/build.sh --lock <path/to/pixi.lock> --tag <registry/image:tag>
```

| Option | Required | Default |
|---|---|---|
| `--lock` | yes | |
| `--tag` | yes | |
| `--pixi-version` | no | latest |

### Extra docker build flags

Use `--` to forward additional arguments to `docker build`:

```sh
./rv/build.sh --lock pipelines-analysis/rv.lock --tag scrna-bench/analysis:latest -- --no-cache
```

## GitHub Actions

This directory is a composite GitHub Action. Use it in any workflow to build a container image from a lock file. The action detects the lock file type automatically.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: scrna-bench/containerize@main
        with:
          image-name: ghcr.io/your-org/my-image
          image-tag: ${{ github.ref_name }}   # e.g. a git tag like v1.2.3

      - run: docker push ghcr.io/your-org/my-image:${{ github.ref_name }}
```

### Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `image-name` | yes | | Full image name, e.g. `ghcr.io/org/image` |
| `lock-file-dir` | no | `.` | Directory containing the lock file |
| `lock-type` | no | auto | `rv` or `pixi` — required only if both lock files exist |
| `image-tag` | no | `latest` | Image tag |
| `rv-version` | no | latest | Pin rv version, e.g. `0.20.0` |
| `pixi-version` | no | latest | Pin pixi version, e.g. `0.41.4` |

### Outputs

| Output | Description |
|---|---|
| `image` | Full image ref that was built, e.g. `ghcr.io/org/image:v1.2.3` |

### Example: build and push on git tag

```yaml
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      packages: write
    steps:
      - uses: actions/checkout@v6

      - uses: docker/login-action@v4
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: scrna-bench/containerize@main
        id: build
        with:
          lock-file-dir: pipelines-analysis
          image-name: ghcr.io/scrna-bench/pipelines-analysis
          image-tag: ${{ github.ref_name }}

      - run: docker push ${{ steps.build.outputs.image }}
```

## Testing

```sh
bash rv/tests/test-build.sh
bash pixi/tests/test-build.sh
```
