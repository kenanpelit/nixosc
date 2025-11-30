#!/usr/bin/env bash
# ===========================================================================
# anotes.sh - Anote.sh için geliştirilmiş başlatıcı
# ===========================================================================
#
# Bu betik, anote.sh terminal not yönetim sistemini çeşitli terminal emülatörlerinde
# çalıştırmak için bir başlatıcı görevi görür, kullanıcıya daha iyi bir deneyim sunar.
#
# Geliştiren: Kenan Pelit
# Repository: github.com/kenanpelit
# Versiyon: 1.3 (Optimized)
# Lisans: GPLv3

set -euo pipefail

# =================================================================
# KONFİGÜRASYON
# =================================================================

readonly ANOTE_CMD="${ANOTE_CMD:-anote}"
readonly ANOTE_WINDOW_TITLE="${ANOTE_WINDOW_TITLE:-Anote}"
readonly ANOTE_WINDOW_CLASS="${ANOTE_WINDOW_CLASS:-anote}"
readonly ANOTE_DIR="${ANOTE_DIR:-$HOME/.anote}"
readonly CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/anotes/config"

export ANOTE_DIR

# EDITOR değişkeni yoksa nvim'i varsayılan yap
: "${EDITOR:=nvim}"
export EDITOR

# Konfigürasyon dosyası varsa yükle
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# Tercih edilmemişse terminal seçim modunu otomatik yap
: "${PREFERRED_TERMINAL:=auto}"

# =================================================================
# FONKSİYONLAR
# =================================================================

show_help() {
  cat <<'EOF'
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                          ANOTES - Anote Başlatıcı                            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

KULLANIM: anotes [SEÇENEK]

AÇIKLAMA:
    anote.sh terminal not yönetim sistemi için geliştirilmiş başlatıcı.

SEÇENEKLER:
    -t, --single       Tek satır snippet modunu başlat
    -M, --multi        Çok satırlı snippet modunu başlat
    -s, --search       Arama modunu başlat
    -A, --audit        Denetim modunu başlat (karalama defteri)
    -c, --create       Dosya oluşturma modunu başlat
    -C, --config       Anotes yapılandırma dosyasını aç
    -r, --restart      Varsa mevcut anote penceresini yeniden başlat
    -d, --daemon       Arka planda çalıştır
    -a, --auto METİN   Hızlı not ekle ve çık
    -S, --scratch      Doğrudan karalama defterini aç
    -k, --kill         Çalışan tüm anote örneklerini sonlandır
    -h, --help         Bu yardım mesajını göster

ÖRNEKLER:
    anotes                           # Anote'u varsayılan ayarlarla çalıştır
    anotes -a "Yapılacak: John'u ara" # Hızlı not ekle ve çık
    anotes -r                        # Mevcut pencereyi yeniden başlat
    anotes -d -t                     # Arka planda tek satır modu

YAPILANDIRMA DOSYASI: ~/.config/anotes/config
EOF
}

detect_terminal() {
  local terminals=(
    "kitty:kitty --class $ANOTE_WINDOW_CLASS -T $ANOTE_WINDOW_TITLE --single-instance"
    "wezterm:wezterm start --class $ANOTE_WINDOW_CLASS"
    "alacritty:alacritty --class $ANOTE_WINDOW_CLASS -t $ANOTE_WINDOW_TITLE"
    "foot:foot --app-id=$ANOTE_WINDOW_CLASS --title=$ANOTE_WINDOW_TITLE"
  )

  local entry term cmd

  # Önce yapılandırmada belirtilen terminali dene
  if [[ "${PREFERRED_TERMINAL}" != "auto" ]]; then
    for entry in "${terminals[@]}"; do
      term="${entry%%:*}"
      cmd="${entry#*:}"
      if [[ "$term" == "$PREFERRED_TERMINAL" ]] && command -v "$term" &>/dev/null; then
        TERMINAL_CMD="$cmd"
        return 0
      fi
    done
  fi

  for entry in "${terminals[@]}"; do
    term="${entry%%:*}"
    cmd="${entry#*:}"
    if command -v "$term" &>/dev/null; then
      TERMINAL_CMD="$cmd"
      return 0
    fi
  done

  echo "⚠ Desteklenen GUI terminal bulunamadı (kitty, wezterm, alacritty, foot)" >&2
  return 1
}

check_anote() {
  command -v "$ANOTE_CMD" &>/dev/null || {
    echo "Hata: $ANOTE_CMD PATH üzerinde bulunamadı" >&2
    exit 1
  }
}

kill_anote() {
  if pkill -f "$ANOTE_WINDOW_CLASS" 2>/dev/null; then
    echo "✓ Anote örnekleri sonlandırıldı"
  else
    echo "⚠ Çalışan anote örneği bulunamadı"
  fi
}

ensure_config() {
  [[ -f "$CONFIG_FILE" ]] && return 0

  mkdir -p "$(dirname "$CONFIG_FILE")"
  cat >"$CONFIG_FILE" <<EOF
# anotes.sh yapılandırma dosyası

# Temel ayarlar
ANOTE_CMD="$ANOTE_CMD"
ANOTE_WINDOW_TITLE="$ANOTE_WINDOW_TITLE"
ANOTE_WINDOW_CLASS="$ANOTE_WINDOW_CLASS"

# Terminal seçimi (auto, kitty, wezterm, alacritty, foot)
PREFERRED_TERMINAL="auto"

# Ek özellikler
ANOTE_USE_TMUX=false
ANOTE_AUTOSTART=false
EOF
  echo "✓ Varsayılan yapılandırma oluşturuldu: $CONFIG_FILE"
}

run_daemon() {
  nohup "$@" >/dev/null 2>&1 &
  disown
  echo "✓ Anote arka planda başlatıldı (PID: $!)"
}

# =================================================================
# ANA PROGRAM
# =================================================================

main() {
  mkdir -p "$ANOTE_DIR" 2>/dev/null

  local anote_args=()
  local daemon=false
  local restart=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -t | --single)
      anote_args+=("-S")
      shift
      ;;
    -M | --multi)
      anote_args+=("-M")
      shift
      ;;
    -s | --search)
      anote_args+=("-s")
      shift
      ;;
    -A | --audit)
      anote_args+=("-A")
      shift
      ;;
    -S | --scratch)
      anote_args+=("--scratch")
      shift
      ;;
    -c | --create)
      anote_args+=("-e")
      shift
      ;;
    -C | --config)
      ensure_config
      "$EDITOR" "$CONFIG_FILE"
      exit 0
      ;;
    -r | --restart)
      restart=true
      shift
      ;;
    -d | --daemon)
      daemon=true
      shift
      ;;
    -a | --auto)
      shift
      [[ $# -eq 0 ]] && {
        echo "Hata: -a/--auto metin argümanı gerektirir" >&2
        exit 1
      }
      "$ANOTE_CMD" -a "$*"
      exit 0
      ;;
    -k | --kill)
      kill_anote
      exit 0
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      anote_args+=("$1")
      shift
      ;;
    esac
  done

  check_anote
  [[ "$restart" == true ]] && kill_anote

  # TMUX içindeysek ve ANOTE_USE_TMUX true ise
  if [[ "${ANOTE_USE_TMUX:-false}" == true ]] &&
    [[ "$TERM_PROGRAM" == "tmux" || -n "${TMUX:-}" ]]; then
    local tmux_cmd="$ANOTE_CMD"
    [[ ${#anote_args[@]} -gt 0 ]] && tmux_cmd+=" ${anote_args[*]}"

    if [[ "$daemon" == true ]]; then
      tmux new-window -d -n "$ANOTE_WINDOW_TITLE" "$tmux_cmd"
      echo "✓ Anote tmux penceresinde başlatıldı"
    else
      tmux new-window -n "$ANOTE_WINDOW_TITLE" "$tmux_cmd"
    fi
    exit 0
  fi

  if detect_terminal; then
    local cmd="$TERMINAL_CMD -e $ANOTE_CMD"
    [[ ${#anote_args[@]} -gt 0 ]] && cmd+=" ${anote_args[*]}"

    if [[ "$daemon" == true ]]; then
      run_daemon bash -c "$cmd"
    else
      eval "$cmd"
    fi
  else
    # GUI terminal bulunamadı; mevcut terminalde çalıştır
    if [[ "$daemon" == true ]]; then
      run_daemon "$ANOTE_CMD" "${anote_args[@]}"
    else
      "$ANOTE_CMD" "${anote_args[@]}"
    fi
  fi
}

main "$@"
