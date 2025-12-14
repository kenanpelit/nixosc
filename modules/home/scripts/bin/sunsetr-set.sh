#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/sunsetr"

IST_LAT="41.0082"
IST_LON="28.9784"

usage() {
  cat <<'EOF'
Kullanım:
  sunsetr-set <preset> [profile]

Örnekler:
  sunsetr-set night
  sunsetr-set night night
  sunsetr-set focus work

Notlar:
  - profile verilmezse "default" kullanılır.
  - profile != default ise config: ~/.config/sunsetr/profiles/<profile>/sunsetr.toml
EOF
}

die() {
  echo "sunsetr-set: $*" >&2
  exit 1
}

ensure_config_dir() {
  local cfg_dir="$1"
  mkdir -p "$cfg_dir"

  # İlk kez profile oluşturuluyorsa default config'ten kopyala.
  if [[ ! -f "$cfg_dir/sunsetr.toml" && -f "$CONFIG_ROOT/sunsetr.toml" ]]; then
    cp -f "$CONFIG_ROOT/sunsetr.toml" "$cfg_dir/sunsetr.toml" 2>/dev/null || true
  fi
}

apply_preset() {
  local preset="$1"
  local cfg_dir="$2"

  case "$preset" in
    day)
      sunsetr --config "$cfg_dir" set \
        day_temp=4500 night_temp=4000 day_gamma=100 night_gamma=95 \
        latitude="$IST_LAT" longitude="$IST_LON"
      ;;
    night)
      sunsetr --config "$cfg_dir" set \
        day_temp=3500 night_temp=3300 day_gamma=90 night_gamma=85 \
        latitude="$IST_LAT" longitude="$IST_LON"
      ;;
    warm)
      sunsetr --config "$cfg_dir" set \
        day_temp=4000 night_temp=3000 day_gamma=100 night_gamma=90 \
        latitude="$IST_LAT" longitude="$IST_LON"
      ;;
    dim)
      sunsetr --config "$cfg_dir" set \
        day_temp=3500 night_temp=3000 day_gamma=85 night_gamma=75 \
        latitude="$IST_LAT" longitude="$IST_LON"
      ;;
    focus)
      sunsetr --config "$cfg_dir" set \
        day_temp=5200 night_temp=4800 day_gamma=110 night_gamma=100 \
        latitude="$IST_LAT" longitude="$IST_LON"
      ;;
    cinema)
      sunsetr --config "$cfg_dir" set \
        day_temp=4000 night_temp=2800 day_gamma=90 night_gamma=80 \
        latitude="$IST_LAT" longitude="$IST_LON"
      ;;
    list|-l|--list)
      cat <<'EOF'
Presetler:
  day     (4500/4000K, 100/95)
  night   (3500/3300K, 90/85)
  warm    (4000/3000K, 100/90)
  dim     (3500/3000K, 85/75)
  focus   (5200/4800K, 110/100)
  cinema  (4000/2800K, 90/80)
EOF
      ;;
    *)
      die "Bilinmeyen preset: $preset (list için: sunsetr-set list)"
      ;;
  esac
}

main() {
  [[ $# -ge 1 ]] || { usage; exit 2; }
  local preset="$1"
  local profile="${2:-default}"

  local cfg_dir="$CONFIG_ROOT"
  if [[ "$profile" != "default" ]]; then
    cfg_dir="$CONFIG_ROOT/profiles/$profile"
  fi

  ensure_config_dir "$cfg_dir"
  apply_preset "$preset" "$cfg_dir"
}

main "$@"

