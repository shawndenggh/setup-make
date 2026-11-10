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

No package cache, downloaded installer scripts, or runtime dependencies beyond Bash and standard system utilities. New ephemeral runners install again unless Make is already in their image.

## Mirror configuration

| Input | Default | Description |
| --- | --- | --- |
| `mirror` | empty | Full Ubuntu APT archive URL. Empty uses the runner's configured repositories, including on Debian. |

For Ubuntu ARC runners in mainland China:

```yaml
- uses: shawndenggh/setup-make@v1
  timeout-minutes: 5
  with:
    mirror: https://mirrors.aliyun.com/ubuntu
```

Use `https://mirrors.aliyun.com/ubuntu-ports` on ARM64, or provide an internal Ubuntu mirror. The archive must contain the runner's codename, updates and security suites. HTTPS requires CA certificates in the runner image. Non-ECS hosts should use the public Aliyun domain shown above.

When installing with `mirror`, the action uses a temporary Deb822 source file, excludes other repositories/PPAs, and retains Ubuntu archive signature verification. It does not rewrite `/etc/apt`. Custom mirror installation is Ubuntu-only; Debian continues to use its configured sources. APT has 30-second network timeouts, two retries, and fails on index download errors. Set the step's `timeout-minutes` to bound total installation time. Mirror speed depends on the runner's network.

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
        timeout-minutes: 5
        with:
          mirror: https://mirrors.aliyun.com/ubuntu
      - run: make build
```

## Development

`bash -n scripts/setup-make.sh` checks shell syntax. The Test workflow exercises the composite action, fresh installation in minimal containers, root and sudo installation, Aliyun mirrors, invalid/unreachable mirrors, source-file preservation, repeated execution, compiler absence, and a subsequent Makefile target.

## License

MIT. See [LICENSE](LICENSE).
