# containerize

A GitHub Action that builds reproducible R/Python Docker images from package lock files.
Supports [`rv`](https://a2-ai.github.io/rv-docs/) (`rv.lock`) and [`pixi`](https://pixi.sh) (`pixi.lock`) — the lock file type is detected automatically.

## Usage

```yaml
- uses: scrna-bench/containerize@main
  with:
    image-name: ghcr.io/scrna-bench/my-image
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
| `image` | Full image ref that was built, e.g. `ghcr.io/org/image:latest` |

### Example: build and push on lock file change

```yaml
on:
  push:
    branches: [main]
    paths:
      - rv.lock
      - rproject.toml

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
          image-name: ghcr.io/scrna-bench/pipelines-analysis
          image-tag: ${{ github.ref_name }}

      - run: docker push ${{ steps.build.outputs.image }}
```

---

## Backends

| | [`rv`](https://github.com/A2-ai/rv) | [`pixi`](https://pixi.sh) |
|---|---|---|
| Lock file | `rv.lock` | `pixi.lock` |
| Builder base | `rocker/r-ver` | `ghcr.io/prefix-dev/pixi` |
| Runtime base | `rocker/r-ver` | `debian:bookworm-slim` |

## Running locally

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

Use `--` to forward extra arguments to `docker build`, e.g. `-- --no-cache`.

## Testing

```sh
bash rv/tests/test-build.sh
bash pixi/tests/test-build.sh
```
