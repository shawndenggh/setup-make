#!/usr/bin/env bash
set -euo pipefail

if [[ "${RUNNER_OS:-$(uname -s)}" != "Linux" ]]; then
  echo "::error::setup-make supports Linux runners only."
  exit 1
fi

mirror="${SETUP_MAKE_MIRROR:-}"
mirror="${mirror%/}"
if [[ -n "$mirror" && ! "$mirror" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/[a-zA-Z0-9._~/-]+)?$ ]]; then
  echo '::error::mirror must be an HTTP(S) archive URL without credentials, whitespace, query or fragment.'
  exit 1
fi

# 已有可用的 make 时复用，避免修改系统包或要求提权。
if command -v make >/dev/null 2>&1; then
  make --version
  exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "::error::Installing Make requires an Ubuntu or Debian runner with apt-get."
  exit 1
fi

# 安装必须能够非交互提权，避免自托管任务等待密码输入。
elevate=()
if [[ "$EUID" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1 || ! sudo -n true; then
    echo "::error::Installing Make requires root or passwordless sudo."
    exit 1
  fi
  elevate=(sudo -n)
fi

apt_options=(
  -o Acquire::Retries=2
  -o Acquire::http::Timeout=30
  -o Acquire::https::Timeout=30
  -o APT::Update::Error-Mode=any
  -o DPkg::Lock::Timeout=60
)
if [[ -n "$mirror" ]]; then
  # shellcheck source=/dev/null
  source /etc/os-release
  if [[ "$ID" != ubuntu || -z "${VERSION_CODENAME:-}" ]]; then
    echo '::error::The mirror input requires Ubuntu; use configured APT sources on Debian.'
    exit 1
  fi
  if [[ ! -r /usr/share/keyrings/ubuntu-archive-keyring.gpg ]]; then
    echo '::error::Ubuntu archive signing keyring is missing.'
    exit 1
  fi
  source_dir="$(mktemp -d)"
  trap 'rm -rf "$source_dir"' EXIT
  chmod 755 "$source_dir"
  cat > "$source_dir/ubuntu.sources" <<EOF
Types: deb
URIs: $mirror
Suites: $VERSION_CODENAME $VERSION_CODENAME-updates $VERSION_CODENAME-security
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
  chmod 644 "$source_dir/ubuntu.sources"
  apt_options+=(
    -o "Dir::Etc::sourcelist=$source_dir/ubuntu.sources"
    -o Dir::Etc::sourceparts=-
    -o APT::Get::List-Cleanup=0
  )
  echo "Installing make from $mirror ($VERSION_CODENAME)."
fi

"${elevate[@]}" apt-get "${apt_options[@]}" update
"${elevate[@]}" env DEBIAN_FRONTEND=noninteractive apt-get "${apt_options[@]}" install -y --no-install-recommends make

# 包管理器成功不代表命令可用，最终校验实际执行结果。
make --version
