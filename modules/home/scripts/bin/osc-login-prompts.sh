#!/usr/bin/env bash
set -euo pipefail

# Trigger keyring/GPG prompts so user can unlock once at login.

delay="${NIRI_BOOT_PROMPT_DELAY:-6}"

sleep "$delay"

if command -v gpg >/dev/null 2>&1; then
  printf "niri-boot\n" | gpg --clearsign --output /tmp/.niri-gpg-test.asc >/dev/null 2>&1 || true
  rm -f /tmp/.niri-gpg-test.asc 2>/dev/null || true
fi

if command -v secret-tool >/dev/null 2>&1; then
  secret-tool lookup niri boot >/dev/null 2>&1 || true
fi
