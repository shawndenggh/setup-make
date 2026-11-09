#!/usr/bin/env bash
set -euo pipefail

if [[ "${RUNNER_OS:-$(uname -s)}" != "Linux" ]]; then
  echo "::error::setup-make supports Linux runners only."
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

"${elevate[@]}" apt-get update
"${elevate[@]}" env DEBIAN_FRONTEND=noninteractive   apt-get install -y --no-install-recommends make

# 包管理器成功不代表命令可用，最终校验实际执行结果。
make --version
