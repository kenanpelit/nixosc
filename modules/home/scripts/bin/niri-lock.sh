#!/usr/bin/env bash
set -euo pipefail

# niri-lock: Lock via DMS but avoid duplicate lock spam.
#
# Niri loglarında görülen:
#   "refusing lock as already locked with an active client"
# çoğunlukla lock isteğinin (Alt+L + lid-close gibi) üst üste gelmesinden olur.
#
# Bu wrapper önce logind LockedHint ile "zaten kilitli mi?" kontrol eder,
# kilitliyse sessizce çıkar.
#
# Modlar:
#   - (varsayılan) dms: dms kilit ekranı (içerideyken güzel UI)
#   - --logind: loginctl lock-session (lid-close gibi durumlarda daha güvenli)

is_locked() {
  [[ -n "${XDG_SESSION_ID:-}" ]] || return 1
  command -v loginctl >/dev/null 2>&1 || return 1

  local hint
  hint="$(loginctl show-session "${XDG_SESSION_ID}" -p LockedHint --value 2>/dev/null || true)"
  [[ "$hint" == "yes" ]]
}

if is_locked; then
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
