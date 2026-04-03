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
./build-rv.sh --lock <path/to/rv.lock> --tag <registry/image:tag>
```

| Option | Required | Default |
|---|---|---|
| `--lock` | yes | |
| `--tag` | yes | |
| `--rv-version` | no | latest |

### pixi

`pixi.lock` and either `pixi.toml` or `pyproject.toml` must be in the same directory.

```sh
./build-pixi.sh --lock <path/to/pixi.lock> --tag <registry/image:tag>
```

| Option | Required | Default |
|---|---|---|
| `--lock` | yes | |
| `--tag` | yes | |
| `--pixi-version` | no | latest |

### Extra docker build flags

Use `--` to forward additional arguments to `docker build`:

```sh
./build-rv.sh --lock pipelines-analysis/rv.lock --tag scrna-bench/analysis:latest -- --no-cache
```

## Testing

```sh
bash tests/test-rv/test-build.sh
bash tests/test-pixi/test-build.sh
```
