#!/usr/bin/env bash
set -euo pipefail

# Wrapper kept for backwards compatibility.
exec gnome-set monitor-primary "$@"
