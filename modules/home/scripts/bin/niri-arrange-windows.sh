#!/usr/bin/env bash
# niri-arrange-windows.sh
# Moves running applications to their designated named workspaces in Niri.
# Useful for restoring window layout after a messy session or restart.

set -euo pipefail

usage() {
  cat <<'EOF'
Kullanım:
  niri-arrange-windows.sh [--dry-run] [--focus <window-id|workspace>]

Amaç:
  Niri'de açık pencereleri, semsumo (--daily) düzenindeki "ait oldukları"
  workspace'lere geri taşır.

Notlar:
  - Bu script Niri oturumu içinde çalıştırılmalı (NIRI_SOCKET gerekli).
  - Taşıma işlemi için Niri action'ları kullanılır:
      - focus-window <id>
      - move-window-to-workspace <workspace>
  - Varsayılan davranış: işlem bitince eski odaklanan pencereye geri döner.

Örnek:
  niri-arrange-windows.sh
  niri-arrange-windows.sh --dry-run
  niri-arrange-windows.sh --focus 2        # Window ID 2'ye geri odaklan
  niri-arrange-windows.sh --focus ws:2     # Workspace 2'ye geç
EOF
}

DRY_RUN=0
FOCUS_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --focus) FOCUS_OVERRIDE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Bilinmeyen arg: $1" >&2; usage; exit 2 ;;
  esac
done

if ! command -v niri >/dev/null 2>&1; then
  echo "niri bulunamadı (PATH)." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq bulunamadı (PATH)." >&2
  exit 1
fi

NIRI=(niri msg)

focused_id="$("${NIRI[@]}" -j focused-window 2>/dev/null | jq -r '.id // empty' || true)"

target_for_app_id() {
  local app_id="${1:-}"
  [[ -z "$app_id" ]] && return 1

  # Semsumo / daily layout mapping (App ID -> workspace)
  # (Bu listeyi `modules/home/niri/default.nix` içindeki semsumoWorkspaceRules ile uyumlu tut.)
  if [[ "$app_id" =~ ^(TmuxKenp|Tmux)$ ]]; then echo "2"; return 0; fi

  if [[ "$app_id" =~ ^Kenp$ ]]; then echo "1"; return 0; fi
  if [[ "$app_id" =~ ^Ai$ ]]; then echo "3"; return 0; fi
  if [[ "$app_id" =~ ^CompecTA$ ]]; then echo "4"; return 0; fi
  if [[ "$app_id" =~ ^brave-youtube\.com__-Default$ ]]; then echo "7"; return 0; fi

  if [[ "$app_id" =~ ^WebCord$ ]]; then echo "5"; return 0; fi
  if [[ "$app_id" =~ ^discord$ ]]; then echo "5"; return 0; fi

  if [[ "$app_id" =~ ^(spotify|Spotify|com\.spotify\.Client)$ ]]; then echo "8"; return 0; fi
  if [[ "$app_id" =~ ^ferdium$ ]]; then echo "9"; return 0; fi

  if [[ "$app_id" =~ ^org\.keepassxc\.KeePassXC$ ]]; then echo "7"; return 0; fi
  return 1
}

echo "Scanning windows..."
windows_json="$("${NIRI[@]}" -j windows)"

echo "$windows_json" | jq -c '.[]' | while read -r win; do
  id="$(jq -r '.id' <<<"$win")"
  app_id="$(jq -r '.app_id // ""' <<<"$win")"
  title="$(jq -r '.title // ""' <<<"$win")"
  current_ws="$(jq -r '.workspace_id // .workspace.id // empty' <<<"$win")"

  # Skip some noisy / transient surfaces.
  if [[ "$app_id" == "hyprland-share-picker" ]]; then
    continue
  fi
  if [[ -z "$app_id" && "$title" =~ ^[Pp]icture[[:space:]-]*in[[:space:]-]*[Pp]icture$ ]]; then
    continue
  fi

  target_ws=""
  if target_ws="$(target_for_app_id "$app_id" 2>/dev/null)"; then
    :
  else
    continue
  fi

  if [[ -n "$current_ws" && "$current_ws" == "$target_ws" ]]; then
    continue
  fi

  echo " -> $id: '$app_id' (ws:${current_ws:-?}) -> ws:$target_ws"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    continue
  fi

  # Actions operate on the focused window, so we focus by id first.
  "${NIRI[@]}" action focus-window "$id" >/dev/null 2>&1 || true
  "${NIRI[@]}" action move-window-to-workspace "$target_ws" >/dev/null 2>&1 || true
done

# Restore focus (best-effort)
if [[ -n "$FOCUS_OVERRIDE" ]]; then
  if [[ "$FOCUS_OVERRIDE" =~ ^ws:(.+)$ ]]; then
    "${NIRI[@]}" action focus-workspace "${BASH_REMATCH[1]}" >/dev/null 2>&1 || true
  else
    "${NIRI[@]}" action focus-window "$FOCUS_OVERRIDE" >/dev/null 2>&1 || true
  fi
elif [[ -n "$focused_id" ]]; then
  "${NIRI[@]}" action focus-window "$focused_id" >/dev/null 2>&1 || true
fi

echo "Done."
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Niri Arranger" "Pencereler workspace'lere taşındı"
fi
