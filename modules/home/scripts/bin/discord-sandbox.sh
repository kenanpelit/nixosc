#!/usr/bin/env bash
set -euo pipefail

if ! command -v discord >/dev/null 2>&1; then
  echo "discord-sandbox: 'discord' not found in PATH" >&2
  exit 127
fi

exec discord --no-sandbox --disable-gpu-sandbox "$@"
