#!/usr/bin/env bash
set -euo pipefail

# niri-lock: Lock via DMS but avoid duplicate lock spam.
#
# Niri loglarında görülen:
#   "refusing lock as already locked with an active client"
# çoğunlukla lock isteğinin (Alt+L + lid-close gibi) üst üste gelmesinden olur.
#
# Bu wrapper önce DMS üzerinden "zaten kilitli mi?" kontrol eder.
# (DMS kendi session-lock state'ini biliyor; bu LockedHint'ten daha güvenilir.)
#
# Modlar:
#   - (varsayılan) dms: dms kilit ekranı (içerideyken güzel UI)
#   - --logind: loginctl lock-session (lid-close gibi durumlarda daha güvenli)

is_dms_locked() {
  command -v dms >/dev/null 2>&1 || return 1
  # `dms ipc call lock isLocked` -> "true"/"false"
  local out
  out="$(dms ipc call lock isLocked 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
  [[ "$out" == "true" ]]
}

if is_dms_locked; then
  exit 0
fi

mode="dms"
if [[ "${1:-}" == "--logind" ]]; then
  mode="logind"
  shift || true
fi

case "$mode" in
logind)
  if command -v loginctl >/dev/null 2>&1; then
    exec loginctl lock-session
  fi
  # Fallback: DMS
  exec dms ipc call lock lock
  ;;
*)
  exec dms ipc call lock lock
  ;;
esac
