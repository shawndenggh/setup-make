# setup-make

A small GitHub Action that makes `make` available on Linux runners, including minimal Ubuntu/Debian containers used by Actions Runner Controller (ARC).

This is a community action, not an official GitHub `actions/*` action.

## Usage

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: shawndenggh/setup-make@v1
  - run: make build
```

Place the action before the first `make` command in **each job** that needs it. The action itself does not require checkout; your Makefile usually does.

## Behavior

- Reuses an existing `make` and verifies it with `make --version`.
- If missing, installs the distribution-provided `make` package using APT.
- Supports installation as root or with non-interactive, passwordless `sudo`.
- Fails immediately when installation or the final executable check fails.
- Runs in the job environment, so subsequent steps can use `make`.

No inputs, package cache, downloaded installer scripts, or runtime dependencies beyond Bash and standard system utilities. Installation requires access to the runner's configured APT repositories. New ephemeral runners install again unless Make is already in their image.

## Support

Installation is tested on Ubuntu 24.04 and Debian Bookworm, plus non-root Ubuntu with sudo. Other Linux distributions can reuse an existing Make, but automatic installation requires APT. macOS and Windows are not supported in v1. This action does not select a specific Make version or install compilers, Docker, Compose, or other tools referenced by your Makefile.

## ARC example

```yaml
jobs:
  build:
    runs-on:
      group: your-runner-group
      labels: your-runner-label
    steps:
      - uses: actions/checkout@v4
      - uses: shawndenggh/setup-make@v1
      - run: make build
```

## Development

`bash -n scripts/setup-make.sh` checks shell syntax. The Test workflow exercises the composite action, fresh installation in minimal containers, root and sudo installation, repeated execution, and a subsequent Makefile target.

## License

MIT. See [LICENSE](LICENSE).
