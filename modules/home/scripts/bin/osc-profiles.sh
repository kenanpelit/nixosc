#!/usr/bin/env bash
# osc-profiles.sh - NixOS system profile manager
# /nix/var/nix/profiles/system-profiles altındaki profilleri listeler/karşılaştırır/siler ve yedekler.

# ==============================================================================
# osc-profiles - NixOS System Profile Manager
# Author: Kenan Pelit
# Version: 1.3.0
# Description:
#   Lightweight, robust manager for NixOS system profiles:
#   - list, inspect and compare profiles
#   - delete old generations safely
#   - create and rotate compressed backups
#   - simple interactive TUI or one-shot CLI
# ==============================================================================

set -o pipefail

# Script metadata
VERSION="1.3.0"

# Core paths
SYSTEM_PROFILES="/nix/var/nix/profiles/system-profiles"
SYSTEM_PROFILE="/nix/var/nix/profiles/system"

BACKUP_DIR="${HOME}/.nix-profile-backups"
CONFIG_DIR="${HOME}/.config/nixos-profiles"
CONFIG_FILE="${CONFIG_DIR}/settings.conf"
LOG_FILE="${CONFIG_DIR}/profile-manager.log"

# Defaults (can be overridden by config / CLI)
SORT_BY="date"      # one of: date, size, name
SHOW_DETAILS=true   # show extra nix-store details
AUTO_BACKUP=false   # automatically backup on delete/bulk delete
CONFIRM_DELETE=true # ask before destructive actions
MAX_BACKUPS=10      # maximum number of backup archives to keep

# UI flags
NO_CLEAR=false

# Styling (colors + symbols)
ui::apply_style() {
  local use_color=true
  if [[ ! -t 1 ]] || [[ -n "${NO_COLOR:-}" ]]; then
    use_color=false
  fi

  if [[ "${use_color}" == true ]]; then
    CYAN="\033[0;36m"
    ORANGE="\033[0;33m"
    BLUE="\033[0;34m"
    GREEN="\033[0;32m"
    RED="\033[0;31m"
    GRAY="\033[0;90m"
    YELLOW="\033[0;33m"
    PURPLE="\033[0;35m"
    NC="\033[0m"
    BOLD="\033[1m"

    S_SUCCESS="✓"
    S_ERROR="✗"
    S_WARN="⚠"
    S_INFO="ℹ"

    HR_CHAR="─"
  else
    CYAN="" ORANGE="" BLUE="" GREEN="" RED="" GRAY="" YELLOW="" PURPLE="" NC="" BOLD=""

    S_SUCCESS="[OK]"
    S_ERROR="[ERR]"
    S_WARN="[WARN]"
    S_INFO="[INFO]"

    HR_CHAR="-"
  fi
}

ui::apply_style

# Box drawing
TOP_CORNER="╭"
VERTICAL="│"
TEE="├"
LAST_TEE="└"
HORIZONTAL="─"
BAR="═"

# ------------------------------------------------------------------------------
# Helpers: logging, config, formatting
# ------------------------------------------------------------------------------

log::init() {
  mkdir -p "${CONFIG_DIR}" 2>/dev/null || true

  # Open a logfile if possible; otherwise keep going without file logging.
  if ! : 2>/dev/null >>"${LOG_FILE}"; then
    local fallback_dir="${HOME}/.cache/osc-profiles"
    local fallback_file="${fallback_dir}/profile-manager.log"
    mkdir -p "${fallback_dir}" 2>/dev/null || true
    if : 2>/dev/null >>"${fallback_file}"; then
      LOG_FILE="${fallback_file}"
    else
      return 0
    fi
  fi

  exec 3>>"${LOG_FILE}" 2>/dev/null || true
}

strip_ansi() {
  sed 's/\x1b\[[0-9;]*m//g'
}

term::cols() {
  local cols="${COLUMNS:-}"
  if [[ -z "${cols}" ]] && command -v tput >/dev/null 2>&1; then
    cols="$(tput cols 2>/dev/null || true)"
  fi
  if [[ -z "${cols}" ]] || ! [[ "${cols}" =~ ^[0-9]+$ ]]; then
    cols="80"
  fi
  printf '%s\n' "${cols}"
}

hr() {
  local cols line
  cols="$(term::cols)"
  printf -v line '%*s' "${cols}" ''
  line="${line// /${HR_CHAR:-'-'}}"
  printf '%b%s%b\n' "${GRAY}" "${line}" "${NC}"
}

ui::clear() {
  [[ "${NO_CLEAR}" == true ]] && return 0
  [[ -t 1 ]] || return 0
  command -v clear >/dev/null 2>&1 && clear || true
}

bool::parse() {
  case "${1,,}" in
    1|true|yes|y|on) printf 'true\n' ;;
    0|false|no|n|off) printf 'false\n' ;;
    *) return 1 ;;
  esac
}

sort::validate() {
  case "${1:-}" in
    date|size|name) return 0 ;;
    *) return 1 ;;
  esac
}

log_message() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  local icon="${S_INFO}"
  local color="${BLUE}"

  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  case "${level}" in
    ERROR) icon="${S_ERROR}"; color="${RED}" ;;
    WARNING) icon="${S_WARN}"; color="${YELLOW}" ;;
    SUCCESS) icon="${S_SUCCESS}"; color="${GREEN}" ;;
    INFO|*) icon="${S_INFO}"; color="${BLUE}" ;;
  esac

  if [[ -e /proc/self/fd/3 ]]; then
    printf '[%s] [%s] %s\n' "${timestamp}" "${level}" "$(printf '%b' "${message}" | strip_ansi)" >&3
  fi

  if [[ "${level}" == "ERROR" ]]; then
    printf '  %b  %b\n' "${color}${BOLD}${icon}${NC}" "${message}" >&2 || true
    return 0
  fi

  # Avoid noisy "Broken pipe" messages when output is piped (e.g. to head).
  printf '  %b  %b\n' "${color}${BOLD}${icon}${NC}" "${message}" 2>/dev/null || true
}

SUDO_BIN=""

resolve_sudo() {
  # NixOS: `sudo` in /nix/store is not setuid; the working wrapper is /run/wrappers/bin/sudo.
  if [[ -x /run/wrappers/bin/sudo ]]; then
    printf '%s\n' "/run/wrappers/bin/sudo"
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    command -v sudo
    return 0
  fi

  return 1
}

ensure_sudo() {
  if [[ -z "${SUDO_BIN}" ]]; then
    SUDO_BIN="$(resolve_sudo 2>/dev/null || true)"
  fi

  if [[ -z "${SUDO_BIN}" ]]; then
    log_message "ERROR" "sudo bulunamadı (root yetkisi gerekli)."
    return 1
  fi

  if [[ ! -u "${SUDO_BIN}" ]]; then
    log_message "ERROR" "sudo setuid değil: ${SUDO_BIN} (NixOS'ta genelde /run/wrappers/bin/sudo kullanılmalı)"
    return 1
  fi

  # If we already have a cached credential, don't prompt.
  if "${SUDO_BIN}" -n true >/dev/null 2>&1; then
    return 0
  fi

  log_message "INFO" "Root yetkisi gerekiyor; sudo parolanı gir."
  "${SUDO_BIN}" -v || {
    log_message "ERROR" "sudo doğrulaması başarısız oldu."
    return 1
  }
}

sudo_run() {
  ensure_sudo || return 1
  "${SUDO_BIN}" -n "$@"
}

load_config() {
  mkdir -p "${CONFIG_DIR}"
  if [[ -f "${CONFIG_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${CONFIG_FILE}" || log_message "WARNING" "Config could not be sourced, using defaults."
  else
    save_config
  fi
}

save_config() {
  mkdir -p "${CONFIG_DIR}"
  cat >"${CONFIG_FILE}" <<EOF
# osc-profiles configuration
SORT_BY="${SORT_BY}"
SHOW_DETAILS=${SHOW_DETAILS}
AUTO_BACKUP=${AUTO_BACKUP}
CONFIRM_DELETE=${CONFIRM_DELETE}
MAX_BACKUPS=${MAX_BACKUPS}
EOF
  log_message "INFO" "Ayarlar kaydedildi: ${CONFIG_FILE}"
}

format_date() {
  # Accepts either an epoch value or a file path
  local input="$1"
  local epoch=""

  if [[ "${input}" =~ ^[0-9]+$ ]]; then
    epoch="${input}"
  elif [[ -e "${input}" ]]; then
    epoch="$(stat -Lc %Y "${input}" 2>/dev/null || printf '')"
  fi

  if [[ -n "${epoch}" ]]; then
    date -d "@${epoch}" "+%Y-%m-%d %H:%M" 2>/dev/null || printf 'unknown'
  else
    printf 'unknown'
  fi
}

human_size() {
  local bytes="$1"
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec-i --suffix=B "${bytes}" 2>/dev/null || printf "%sB" "${bytes}"
  else
    printf "%sB" "${bytes}"
  fi
}

profile_target() {
  local link="$1"
  readlink -f "${link}" 2>/dev/null || printf ''
}

active_profile_name() {
  local active_target
  active_target="$(profile_target "${SYSTEM_PROFILE}")"
  [[ -n "${active_target}" ]] || return 0
  [[ -d "${SYSTEM_PROFILES}" ]] || return 0

  local p t
  while IFS= read -r p; do
    t="$(profile_target "${p}")"
    [[ -n "${t}" ]] || continue
    if [[ "${t}" == "${active_target}" ]]; then
      basename "${p}"
      return 0
    fi
  done < <(find "${SYSTEM_PROFILES}" -maxdepth 1 -type l -print 2>/dev/null | sort)
}

sorted_profile_paths_by_date() {
  [[ -d "${SYSTEM_PROFILES}" ]] || return 0
  find "${SYSTEM_PROFILES}" -maxdepth 1 -type l -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | awk '{ $1=""; sub(/^ /,""); print }'
}

sorted_profile_paths() {
  # Prints one profile symlink path per line sorted by current SORT_BY
  [[ -d "${SYSTEM_PROFILES}" ]] || return 0

  case "${SORT_BY}" in
    date)
      find "${SYSTEM_PROFILES}" -maxdepth 1 -type l -printf '%T@ %p\n' 2>/dev/null \
        | sort -nr \
        | awk '{ $1=""; sub(/^ /,""); print }'
      ;;
    size)
      # sort by target store path size (descending)
      while IFS= read -r link; do
        local target size
        target="$(profile_target "${link}")"
        [[ -n "${target}" ]] || continue
        size="$(du -sb "${target}" 2>/dev/null | awk '{print $1}')"
        printf '%015d %s\n' "${size:-0}" "${link}"
      done < <(find "${SYSTEM_PROFILES}" -maxdepth 1 -type l -print 2>/dev/null) \
        | sort -nr \
        | awk '{ $1=""; sub(/^ /,""); print }'
      ;;
    name|*)
      find "${SYSTEM_PROFILES}" -maxdepth 1 -type l -printf '%f %p\n' 2>/dev/null \
        | sort -k1,1 \
        | awk '{ $1=""; sub(/^ /,""); print }'
      ;;
  esac
}

# ------------------------------------------------------------------------------
# Profile inspection
# ------------------------------------------------------------------------------

get_profile_details() {
  local target="$1"
  [[ -n "${target}" ]] || return 0

  local result=""

  # Package count
  if command -v nix-store >/dev/null 2>&1; then
    local pkg_count
    pkg_count="$(nix-store -q --references "${target}" 2>/dev/null | wc -l | tr -d ' ')"
    result+="Paket sayısı: ${BLUE}${pkg_count}${NC}\n"
  fi

  # Dependency count
  if command -v nix-store >/dev/null 2>&1; then
    local dep_count
    dep_count="$(nix-store -q --requisites "${target}" 2>/dev/null | wc -l | tr -d ' ')"
    result+="Bağımlılık: ${BLUE}${dep_count}${NC}\n"
  fi

  # Compressed size via nix path-info -S
  if command -v nix >/dev/null 2>&1; then
    local comp
    comp="$(nix path-info -S "${target}" 2>/dev/null | awk 'NR==1{print $2}')"
    if [[ -n "${comp}" ]]; then
      result+="Sıkıştırılmış: ${BLUE}$(human_size "${comp}")${NC}\n"
    fi
  fi

  # Build / registration time (optional jq)
  if command -v nix >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    local json build_time
    json="$(nix path-info --json "${target}" 2>/dev/null || printf '')"
    if [[ -n "${json}" ]]; then
      build_time="$(printf '%s\n' "${json}" | jq -er '.[0].registrationTime // empty' 2>/dev/null || printf '')"
      if [[ -n "${build_time}" ]]; then
        result+="Derleme: ${BLUE}$(format_date "${build_time}")${NC}\n"
      fi
    fi
  fi

  [[ -n "${result}" ]] && printf '%b' "${result}"
}

print_header() {
  printf '\n'
  hr
  printf '%b\n' "${CYAN}${BOLD}osc-profiles${NC} ${GRAY}v${VERSION}${NC}"
  printf '%b\n' "${GRAY}${SYSTEM_PROFILES}${NC}"
  printf '%b\n' "  Sıralama: ${ORANGE}${SORT_BY}${NC} | Detay: ${ORANGE}$([[ "${SHOW_DETAILS}" == true ]] && echo 'açık' || echo 'kapalı')${NC} | Otomatik yedek: ${ORANGE}$([[ "${AUTO_BACKUP}" == true ]] && echo 'açık' || echo 'kapalı')${NC} | Silme onayı: ${ORANGE}$([[ "${CONFIRM_DELETE}" == true ]] && echo 'açık' || echo 'kapalı')${NC}"
  hr
  printf '\n'
}

print_active_system() {
  local target size store name uptime kernel

  target="$(profile_target "${SYSTEM_PROFILE}")"
  if [[ -z "${target}" ]]; then
    printf '%b\n\n' "${RED}${BOLD}Aktif sistem profili bulunamadı.${NC}"
    return
  fi

  size="$(du -sh "${target}" 2>/dev/null | awk '{print $1}')"
  store="$(basename "${target}")"
  name="$(active_profile_name)"
  uptime="$(uptime | sed 's/.*up \([^,]*\),.*/\1/' 2>/dev/null || echo 'bilinmiyor')"
  kernel="$(uname -r)"

  printf '%b\n' "${GREEN}${BOLD}${S_INFO} Aktif Sistem Profili${NC}"
  [[ -n "${name}" ]] && printf '%b\n' "${TEE}${HORIZONTAL} Profil  ${ORANGE}${name}${NC}"
  printf '%b\n' "${TEE}${HORIZONTAL} Store   ${ORANGE}${store}${NC}"
  printf '%b\n' "${TEE}${HORIZONTAL} Yol     ${ORANGE}${target}${NC}"
  printf '%b\n' "${TEE}${HORIZONTAL} Boyut   ${BLUE}${size}${NC}"
  printf '%b\n' "${TEE}${HORIZONTAL} Çalışma ${PURPLE}${uptime}${NC}"
  printf '%b\n' "${LAST_TEE}${HORIZONTAL} Çekirdek ${PURPLE}${kernel}${NC}"

  if [[ "${SHOW_DETAILS}" == true ]]; then
    local details
    details="$(get_profile_details "${target}")"
    [[ -n "${details}" ]] && printf '%b\n' "${VERTICAL}  ${GRAY}${details}${NC}"
  fi

  printf '\n'
}

list_profiles() {
  # $1 = true/false -> show numeric index
  local show_numbers="$1"

  mapfile -t _profiles < <(sorted_profile_paths)
  local total="${#_profiles[@]}"

  local active_target
  active_target="$(profile_target "${SYSTEM_PROFILE}")"

  printf '%b\n' "${GREEN}${BOLD}Mevcut profiller (${total})${NC}"

  if (( total == 0 )); then
    printf '%b\n\n' "   ${GRAY}Profil bulunamadı${NC}"
    return 0
  fi

  local idx=1
  for profile in "${_profiles[@]}"; do
    local name target store size mtime label active_mark
    name="$(basename "${profile}")"
    target="$(profile_target "${profile}")"
    store="$(basename "${target}")"
    size="$(du -sh "${target}" 2>/dev/null | awk '{print $1}')"
    mtime="$(stat -Lc %Y "${profile}" 2>/dev/null || printf '0')"

    active_mark=""
    if [[ -n "${active_target}" && "${target}" == "${active_target}" ]]; then
      active_mark=" ${GREEN}${BOLD}(aktif)${NC}"
    fi

    if [[ "${show_numbers}" == true ]]; then
      label="${ORANGE}[${idx}]${NC} ${CYAN}${BOLD}${name}${NC}${active_mark}"
    else
      label="${CYAN}${BOLD}${name}${NC}${active_mark}"
    fi

    printf '%b\n' "${TEE}${HORIZONTAL} ${label}"
    printf '%b\n' "${VERTICAL}  ${HORIZONTAL} Store  ${ORANGE}${store}${NC}"
    printf '%b\n' "${VERTICAL}  ${HORIZONTAL} Boyut  ${BLUE}${size}${NC}"
    printf '%b\n' "${LAST_TEE}${HORIZONTAL} Tarih  ${GRAY}$(format_date "${mtime}")${NC}"

    if [[ "${SHOW_DETAILS}" == true ]]; then
      local details
      details="$(get_profile_details "${target}")"
      [[ -n "${details}" ]] && printf '%b\n' "   ${GRAY}${details}${NC}"
    fi

    ((idx++))
  done

  printf '\n'
  return 0
}

# ------------------------------------------------------------------------------
# Mutating operations: backup, delete, bulk delete, compare
# ------------------------------------------------------------------------------

clean_old_backups() {
  [[ -d "${BACKUP_DIR}" ]] || return 0
  mapfile -t backups < <(find "${BACKUP_DIR}" -maxdepth 1 -type f -name '*.tar.gz' -printf '%T@ %p\n' 2>/dev/null | sort -n | awk '{ $1=""; sub(/^ /,""); print }')
  local count="${#backups[@]}"
  (( count <= MAX_BACKUPS )) && return 0

  local remove=$((count - MAX_BACKUPS))
  for ((i=0; i<remove; i++)); do
    rm -f -- "${backups[$i]}" 2>/dev/null || true
  done
}

backup_profile() {
  local profile_link="$1"
  local target name ts archive

  target="$(profile_target "${profile_link}")"
  if [[ -z "${target}" ]]; then
    log_message "ERROR" "Yedeklenecek profil çözümlenemedi: ${profile_link}"
    return 1
  fi

  ensure_sudo || return 1

  name="$(basename "${profile_link}")"
  ts="$(date '+%Y%m%d-%H%M%S')"
  mkdir -p "${BACKUP_DIR}"
  archive="${BACKUP_DIR}/${name}-${ts}.tar.gz"

  log_message "INFO" "Profil yedekleniyor: ${name} -> ${archive}"
  if sudo_run tar -C "${target}" -czf "${archive}" .; then
    log_message "SUCCESS" "Yedek oluşturuldu: ${archive}"
    clean_old_backups
    return 0
  else
    log_message "ERROR" "Yedek oluşturulamadı: ${archive}"
    rm -f -- "${archive}" 2>/dev/null || true
    return 1
  fi
}

delete_profile_by_index() {
  local index="$1"
  mapfile -t _profiles < <(sorted_profile_paths)
  local total="${#_profiles[@]}"

  if ! [[ "${index}" =~ ^[0-9]+$ ]] || (( index < 1 || index > total )); then
    log_message "ERROR" "Geçersiz profil numarası: ${index}"
    return 1
  fi

  local selected="${_profiles[$((index-1))]}"
  local name
  name="$(basename "${selected}")"

  local active_target selected_target
  active_target="$(profile_target "${SYSTEM_PROFILE}")"
  selected_target="$(profile_target "${selected}")"

  if [[ -n "${active_target}" && "${active_target}" == "${selected_target}" ]]; then
    log_message "ERROR" "Aktif profil silinemez: ${name}"
    return 1
  fi

  if [[ "${CONFIRM_DELETE}" == true ]]; then
    printf '%b' "${YELLOW}${BOLD}${S_WARN} '${name}' profili silinecek. Emin misiniz? (e/H) ${NC}"
    read -r reply
    [[ "${reply}" =~ ^[Ee]$ ]] || { log_message "INFO" "Silme iptal edildi."; return 0; }
  fi

  [[ "${AUTO_BACKUP}" == true ]] && backup_profile "${selected}" || true

  local err=""
  ensure_sudo || return 1
  if err="$("${SUDO_BIN}" -n rm -f -- "${selected}" 2>&1)"; then
    log_message "SUCCESS" "Profil silindi: ${name}"
    return 0
  else
    log_message "ERROR" "Profil silinemedi: ${name}${err:+ ($err)}"
    return 1
  fi
}

bulk_delete_old_profiles() {
  mapfile -t _profiles < <(sorted_profile_paths)
  local total="${#_profiles[@]}"
  (( total > 1 )) || { log_message "INFO" "Silinecek eski profil yok."; return 0; }

  local active_target
  active_target="$(profile_target "${SYSTEM_PROFILE}")"

  printf '%b' "${YELLOW}${BOLD}${S_WARN} Aktif profil dışındaki TÜM profiller silinecek. Emin misiniz? (e/H) ${NC}"
  read -r reply
  [[ "${reply}" =~ ^[Ee]$ ]] || { log_message "INFO" "Toplu silme iptal edildi."; return 0; }

  ensure_sudo || return 1

  local p
  for p in "${_profiles[@]}"; do
    local t
    t="$(profile_target "${p}")"
    if [[ -n "${active_target}" && "${t}" == "${active_target}" ]]; then
      continue
    fi
    [[ "${AUTO_BACKUP}" == true ]] && backup_profile "${p}" || true
    local err=""
    if err="$("${SUDO_BIN}" -n rm -f -- "${p}" 2>&1)"; then
      log_message "SUCCESS" "Profil silindi: $(basename "${p}")"
    else
      log_message "ERROR" "Profil silinemedi: $(basename "${p}")${err:+ ($err)}"
      return 1
    fi
  done
}

prune_old_profiles() {
  # Keep N newest *non-active* profiles (active is always kept).
  local keep="${1:-5}"

  if ! [[ "${keep}" =~ ^[0-9]+$ ]]; then
    log_message "ERROR" "Geçersiz değer: --prune ${keep} (sayı olmalı)"
    return 1
  fi

  mapfile -t _profiles < <(sorted_profile_paths_by_date)
  local total="${#_profiles[@]}"
  (( total > 1 )) || { log_message "INFO" "Prune edilecek eski profil yok."; return 0; }

  local active_target
  active_target="$(profile_target "${SYSTEM_PROFILE}")"

  local kept=0
  local to_delete=()

  local p t
  for p in "${_profiles[@]}"; do
    t="$(profile_target "${p}")"
    [[ -n "${t}" ]] || continue
    if [[ -n "${active_target}" && "${t}" == "${active_target}" ]]; then
      continue
    fi
    if (( kept < keep )); then
      kept=$((kept + 1))
      continue
    fi
    to_delete+=("${p}")
  done

  local del_count="${#to_delete[@]}"
  (( del_count > 0 )) || { log_message "INFO" "Prune edilecek eski profil yok."; return 0; }

  if [[ "${CONFIRM_DELETE}" == true ]]; then
    printf '%b\n' "${YELLOW}${BOLD}${S_WARN} ${del_count} profil silinecek (aktif profil korunur).${NC}"
    printf '%b' "${YELLOW}${BOLD}Devam edilsin mi? (e/H) ${NC}"
    read -r reply
    [[ "${reply}" =~ ^[Ee]$ ]] || { log_message "INFO" "Prune iptal edildi."; return 0; }
  fi

  ensure_sudo || return 1

  for p in "${to_delete[@]}"; do
    [[ "${AUTO_BACKUP}" == true ]] && backup_profile "${p}" || true
    local err=""
    if err="$("${SUDO_BIN}" -n rm -f -- "${p}" 2>&1)"; then
      log_message "SUCCESS" "Profil silindi: $(basename "${p}")"
    else
      log_message "ERROR" "Profil silinemedi: $(basename "${p}")${err:+ ($err)}"
      return 1
    fi
  done

  log_message "SUCCESS" "Prune tamamlandı."
}

compare_profiles() {
  local idx1="$1"
  local idx2="$2"

  mapfile -t _profiles < <(sorted_profile_paths)
  local total="${#_profiles[@]}"

  if ! [[ "${idx1}" =~ ^[0-9]+$ && "${idx2}" =~ ^[0-9]+$ ]] \
     || (( idx1 < 1 || idx1 > total || idx2 < 1 || idx2 > total )); then
    log_message "ERROR" "Geçersiz profil numarası."
    return 1
  fi

  local p1="${_profiles[$((idx1-1))]}"
  local p2="${_profiles[$((idx2-1))]}"
  local t1 t2 n1 n2

  t1="$(profile_target "${p1}")"
  t2="$(profile_target "${p2}")"
  n1="$(basename "${p1}")"
  n2="$(basename "${p2}")"

  if [[ -z "${t1}" || -z "${t2}" ]]; then
    log_message "ERROR" "Profil çözümlenemedi."
    return 1
  fi

  printf '%b\n' "${CYAN}${BOLD}Profil Karşılaştırması${NC}"
  printf '%b\n' "${TEE}${HORIZONTAL} Profil 1: ${CYAN}${n1}${NC}"
  printf '%b\n' "${LAST_TEE}${HORIZONTAL} Profil 2: ${CYAN}${n2}${NC}"
  printf '\n'

  if ! command -v nix-store >/dev/null 2>&1; then
    log_message "ERROR" "nix-store bulunamadı; paket karşılaştırılamıyor."
    return 1
  fi

  local pkgs1 pkgs2 only1 only2 count1 count2
  pkgs1="$(nix-store -q --references "${t1}" 2>/dev/null | sort)"
  pkgs2="$(nix-store -q --references "${t2}" 2>/dev/null | sort)"

  only1="$(comm -23 <(printf '%s\n' "${pkgs1}") <(printf '%s\n' "${pkgs2}"))"
  only2="$(comm -13 <(printf '%s\n' "${pkgs1}") <(printf '%s\n' "${pkgs2}"))"

  count1="$(printf '%s\n' "${only1}" | sed '/^$/d' | wc -l | tr -d ' ')"
  count2="$(printf '%s\n' "${only2}" | sed '/^$/d' | wc -l | tr -d ' ')"

  printf '%b\n' "${ORANGE}${BOLD}Paket Farklılıkları:${NC}"

  printf '%b\n' "${GREEN}Yalnızca '${n1}' profilinde olan paketler (${count1}):${NC}"
  if (( count1 == 0 )); then
    printf '%b\n' "   ${GRAY}Farklı paket yok${NC}"
  else
    printf '%s\n' "${only1}" | sed '/^$/d' | while read -r pkg; do
      local pkgname
      pkgname="$(basename "${pkg}" | cut -d'-' -f2-)"
      printf '%b\n' " + ${BLUE}${pkgname}${NC} (${GRAY}${pkg}${NC})"
    done
  fi

  printf '\n'
  printf '%b\n' "${RED}Yalnızca '${n2}' profilinde olan paketler (${count2}):${NC}"
  if (( count2 == 0 )); then
    printf '%b\n' "   ${GRAY}Farklı paket yok${NC}"
  else
    printf '%s\n' "${only2}" | sed '/^$/d' | while read -r pkg; do
      local pkgname
      pkgname="$(basename "${pkg}" | cut -d'-' -f2-)"
      printf '%b\n' " - ${BLUE}${pkgname}${NC} (${GRAY}${pkg}${NC})"
    done
  fi

  printf '\n'
  printf '%b\n' "${ORANGE}${BOLD}Özet:${NC}"
  printf '%b\n' "${TEE}${HORIZONTAL} '${n1}' özgü paket sayısı: ${GREEN}${count1}${NC}"
  printf '%b\n' "${TEE}${HORIZONTAL} '${n2}' özgü paket sayısı: ${RED}${count2}${NC}"
  printf '%b\n' "${LAST_TEE}${HORIZONTAL} Toplam farklılık: ${PURPLE}$((count1 + count2))${NC}"
}

# ------------------------------------------------------------------------------
# Stats & settings
# ------------------------------------------------------------------------------

print_stats() {
  mapfile -t _profiles < <(sorted_profile_paths)
  local total="${#_profiles[@]}"

  printf '\n'
  printf '%b\n' "${CYAN}${BOLD}${TOP_CORNER}${BAR} Profil İstatistikleri ${BAR}${NC}"
  printf '%b\n' "${TEE}${HORIZONTAL} Toplam profil: ${BLUE}${total}${NC}"

  if (( total == 0 )); then
    printf '%b\n' "${LAST_TEE}${HORIZONTAL} ${GRAY}Profil bulunamadı${NC}"
    printf '\n'
    return 0
  fi

  local total_size=0 largest_size=0 smallest_size=999999999999
  local largest_name="" smallest_name=""

  local p
  for p in "${_profiles[@]}"; do
    local target size
    target="$(profile_target "${p}")"
    [[ -n "${target}" ]] || continue
    size="$(du -sb "${target}" 2>/dev/null | awk '{print $1}')"
    [[ -n "${size}" ]] || continue

    total_size=$((total_size + size))
    if (( size > largest_size )); then
      largest_size="${size}"
      largest_name="$(basename "${p}")"
    fi
    if (( size < smallest_size )); then
      smallest_size="${size}"
      smallest_name="$(basename "${p}")"
    fi
  done

  if (( total_size > 0 )); then
    local avg_size=$((total_size / total))
    printf '%b\n' "${TEE}${HORIZONTAL} Ortalama boyut: ${BLUE}$(human_size "${avg_size}")${NC}"
    printf '%b\n' "${TEE}${HORIZONTAL} Toplam boyut:   ${BLUE}$(human_size "${total_size}")${NC}"
    [[ -n "${largest_name}" ]] && printf '%b\n' "${TEE}${HORIZONTAL} En büyük:       ${PURPLE}${largest_name}${NC} (${BLUE}$(human_size "${largest_size}")${NC})"
    [[ -n "${smallest_name}" ]] && printf '%b\n' "${LAST_TEE}${HORIZONTAL} En küçük:       ${PURPLE}${smallest_name}${NC} (${BLUE}$(human_size "${smallest_size}")${NC})"
  else
    printf '%b\n' "${LAST_TEE}${HORIZONTAL} ${GRAY}Boyut bilgisi alınamadı${NC}"
  fi

  printf '\n'

  # Backup stats
  printf '%b\n' "${YELLOW}${BOLD}Yedek Bilgileri:${NC}"
  if [[ -d "${BACKUP_DIR}" ]]; then
    mapfile -t backups < <(find "${BACKUP_DIR}" -maxdepth 1 -type f -name '*.tar.gz' 2>/dev/null)
    local count="${#backups[@]}"
    if (( count == 0 )); then
      printf '%b\n' "${LAST_TEE}${HORIZONTAL} ${GRAY}Yedek bulunamadı${NC}"
    else
      local total_b=0
      local oldest_name="" newest_name=""
      local oldest_t=9999999999 newest_t=0
      local b
      for b in "${backups[@]}"; do
        local sz tm
        sz="$(du -sb "${b}" 2>/dev/null | awk '{print $1}')"
        tm="$(stat -Lc %Y "${b}" 2>/dev/null || printf '0')"
        total_b=$((total_b + sz))
        if (( tm < oldest_t )); then
          oldest_t="${tm}"
          oldest_name="$(basename "${b}")"
        fi
        if (( tm > newest_t )); then
          newest_t="${tm}"
          newest_name="$(basename "${b}")"
        fi
      done
      printf '%b\n' "${TEE}${HORIZONTAL} Yedek sayısı:   ${BLUE}${count}${NC}"
      printf '%b\n' "${TEE}${HORIZONTAL} Toplam boyut:   ${BLUE}$(human_size "${total_b}")${NC}"
      printf '%b\n' "${TEE}${HORIZONTAL} En eski:        ${GRAY}${oldest_name}${NC}"
      printf '%b\n' "${LAST_TEE}${HORIZONTAL} En yeni:        ${GRAY}${newest_name}${NC}"
    fi
  else
    printf '%b\n' "${LAST_TEE}${HORIZONTAL} ${GRAY}Yedek dizini yok${NC}"
  fi

  printf '\n'
}

doctor() {
  ui::clear
  print_header

  log_message "INFO" "Sürüm: ${VERSION}"

  if [[ -d "${SYSTEM_PROFILES}" ]]; then
    log_message "SUCCESS" "system-profiles dizini: ${SYSTEM_PROFILES}"
  else
    log_message "ERROR" "system-profiles dizini yok: ${SYSTEM_PROFILES}"
  fi

  local active_target active_name
  active_target="$(profile_target "${SYSTEM_PROFILE}")"
  active_name="$(active_profile_name)"

  if [[ -n "${active_target}" ]]; then
    log_message "INFO" "Aktif profil: ${active_name:-<profile-name yok>} -> ${active_target}"
  else
    log_message "WARNING" "Aktif sistem profili çözümlenemedi: ${SYSTEM_PROFILE}"
  fi

  mapfile -t _profiles < <(sorted_profile_paths_by_date)
  log_message "INFO" "Bulunan profil sayısı: ${#_profiles[@]}"

  log_message "INFO" "Yedek dizini: ${BACKUP_DIR}"
  log_message "INFO" "Config: ${CONFIG_FILE}"
  log_message "INFO" "Log: ${LOG_FILE}"

  local sudo_path
  sudo_path="$(resolve_sudo 2>/dev/null || true)"
  if [[ -n "${sudo_path}" ]]; then
    if [[ -u "${sudo_path}" ]]; then
      log_message "SUCCESS" "sudo: ${sudo_path} (setuid)"
    else
      log_message "WARNING" "sudo: ${sudo_path} (setuid değil; NixOS'ta /run/wrappers/bin/sudo beklenir)"
    fi
  else
    log_message "WARNING" "sudo bulunamadı"
  fi

  local cmd
  for cmd in nix nix-store jq numfmt tar du stat readlink; do
    if command -v "${cmd}" >/dev/null 2>&1; then
      log_message "SUCCESS" "bin:${cmd} -> $(command -v "${cmd}")"
    else
      log_message "WARNING" "bin:${cmd} (missing)"
    fi
  done
}

show_settings_menu() {
  while true; do
    ui::clear
    printf '%b\n' "${CYAN}${BOLD}${TOP_CORNER}${BAR} Ayarlar Menüsü ${BAR}${NC}"
    printf '\n'
    printf '%b\n' "${TEE}${HORIZONTAL} 1 - Sıralama: ${ORANGE}${SORT_BY}${NC}"
    printf '%b\n' "${TEE}${HORIZONTAL} 2 - Detaylar: ${ORANGE}$([[ "${SHOW_DETAILS}" == true ]] && echo 'Açık' || echo 'Kapalı')${NC}"
    printf '%b\n' "${TEE}${HORIZONTAL} 3 - Otomatik yedek: ${ORANGE}$([[ "${AUTO_BACKUP}" == true ]] && echo 'Açık' || echo 'Kapalı')${NC}"
    printf '%b\n' "${TEE}${HORIZONTAL} 4 - Silme onayı: ${ORANGE}$([[ "${CONFIRM_DELETE}" == true ]] && echo 'Açık' || echo 'Kapalı')${NC}"
    printf '%b\n' "${TEE}${HORIZONTAL} 5 - Maksimum yedek: ${ORANGE}${MAX_BACKUPS}${NC}"
    printf '%b\n' "${TEE}${HORIZONTAL} s - Kaydet ve çık"
    printf '%b\n' "${LAST_TEE}${HORIZONTAL} q - Kaydetmeden çık"
    printf '\n'
    printf '%b' "${BOLD}Komut: ${NC}"
    read -r cmd

    case "${cmd}" in
      1)
        printf '\n%b\n' "${CYAN}${BOLD}Sıralama Seçenekleri:${NC}"
        printf '%b\n' "1) ${ORANGE}date${NC} - tarihe göre (yeni -> eski)"
        printf '%b\n' "2) ${ORANGE}size${NC} - boyuta göre (büyük -> küçük)"
        printf '%b\n' "3) ${ORANGE}name${NC} - isme göre (a -> z)"
        printf '%b'  "Seçiminiz: "
        read -r s
        case "${s}" in
          1) SORT_BY="date" ;;
          2) SORT_BY="size" ;;
          3) SORT_BY="name" ;;
          *) log_message "ERROR" "Geçersiz sıralama seçimi: ${s}" ;;
        esac
        ;;
      2) SHOW_DETAILS=$([[ "${SHOW_DETAILS}" == true ]] && echo false || echo true) ;;
      3) AUTO_BACKUP=$([[ "${AUTO_BACKUP}" == true ]] && echo false || echo true) ;;
      4) CONFIRM_DELETE=$([[ "${CONFIRM_DELETE}" == true ]] && echo false || echo true) ;;
      5)
        printf '\n%b' "${BOLD}Maksimum yedek sayısı (1-50): ${NC}"
        read -r m
        if [[ "${m}" =~ ^[0-9]+$ ]] && (( m >= 1 && m <= 50 )); then
          MAX_BACKUPS="${m}"
        else
          log_message "ERROR" "Geçersiz değer: ${m}"
        fi
        ;;
      s|S)
        save_config
        break
        ;;
      q|Q)
        log_message "INFO" "Ayarlar kaydedilmedi."
        break
        ;;
      *)
        log_message "ERROR" "Geçersiz komut: ${cmd}"
        ;;
    esac

    printf '\n%b' "${GRAY}Devam etmek için Enter'a basın...${NC}"
    read -r _
  done
}

# ------------------------------------------------------------------------------
# UI: help & main menu
# ------------------------------------------------------------------------------

show_help() {
  cat <<EOF
osc-profiles - NixOS system profile manager

Usage:
  osc-profiles            # interactive menu
  osc-profiles -m|--menu  # interactive menu
  osc-profiles -l|--list  # list profiles (non-interactive)
  osc-profiles -s|--stats # show statistics
  osc-profiles -b|--backup # backup active system profile
  osc-profiles --doctor   # environment/self-check
  osc-profiles --prune N  # keep N newest non-active profiles
  osc-profiles -h|--help  # show this help

Options (apply to most commands):
  --no-color              Disable ANSI colors
  --no-clear              Do not clear the screen
  --sort date|size|name   Override sort order
  --details on|off        Toggle extra nix-store/nix details
  -y, --yes               Skip delete confirmations

Inside interactive menu:
  d  - delete profile by index
  c  - compare two profiles
  b  - backup active profile
  s  - change sort order
  t  - toggle details
  a  - delete all non-active profiles
  p  - prune old profiles (keep N)
  g  - show log tail
  o  - settings menu
  q  - quit
EOF
}

show_main_menu() {
  while true; do
    ui::clear
    print_header
    print_active_system
    list_profiles true

    printf '%b\n' "${BOLD}Ana Menü:${NC}"
    printf '%b\n' "${TEE}${HORIZONTAL} d - Profil sil"
    printf '%b\n' "${TEE}${HORIZONTAL} c - Profilleri karşılaştır"
    printf '%b\n' "${TEE}${HORIZONTAL} b - Aktif profili yedekle"
    printf '%b\n' "${TEE}${HORIZONTAL} g - Günlüğü görüntüle"
    printf '%b\n' "${TEE}${HORIZONTAL} s - Sıralama değiştir"
    printf '%b\n' "${TEE}${HORIZONTAL} t - Detayları aç/kapat"
    printf '%b\n' "${TEE}${HORIZONTAL} a - Tüm eski profilleri sil"
    printf '%b\n' "${TEE}${HORIZONTAL} p - Eski profilleri prune et (keep N)"
    printf '%b\n' "${TEE}${HORIZONTAL} o - Ayarlar"
    printf '%b\n' "${LAST_TEE}${HORIZONTAL} q - Çıkış"
    printf '\n%b' "${BOLD}Komut: ${NC}"
    read -r cmd

    case "${cmd}" in
      d|D)
        while true; do
          printf '\n%b' "${BOLD}Silinecek profil numarası (çıkmak için q): ${NC}"
          read -r num
          [[ "${num}" == "q" ]] && break
          delete_profile_by_index "${num}" && break
        done
        ;;
      c|C)
        printf '%b' "1. profil numarası: "
        read -r n1
        printf '%b' "2. profil numarası: "
        read -r n2
        compare_profiles "${n1}" "${n2}"
        ;;
      b|B)
        backup_profile "${SYSTEM_PROFILE}"
        ;;
      g|G)
        ui::clear
        printf '%b\n' "${CYAN}${BOLD}${TOP_CORNER}${BAR} Sistem Günlüğü ${BAR}${NC}"
        printf '\n'
        if [[ -f "${LOG_FILE}" ]]; then
          tail -n 20 "${LOG_FILE}"
        else
          printf '%b\n' "${GRAY}Günlük dosyası bulunamadı.${NC}"
        fi
        printf '\n%b' "${GRAY}Devam etmek için Enter'a basın...${NC}"
        read -r _
        ;;
      s|S)
        printf '\n%b\n' "${CYAN}${BOLD}Sıralama Seçenekleri:${NC}"
        printf '%b\n' "1) ${ORANGE}date${NC}"
        printf '%b\n' "2) ${ORANGE}size${NC}"
        printf '%b\n' "3) ${ORANGE}name${NC}"
        printf '%b'  "Seçiminiz: "
        read -r s
        case "${s}" in
          1) SORT_BY="date" ;;
          2) SORT_BY="size" ;;
          3) SORT_BY="name" ;;
          *) log_message "ERROR" "Geçersiz seçim: ${s}" ;;
        esac
        ;;
      t|T)
        SHOW_DETAILS=$([[ "${SHOW_DETAILS}" == true ]] && echo false || echo true)
        ;;
      a|A)
        bulk_delete_old_profiles
        ;;
      p|P)
        printf '\n%b' "${BOLD}Kaç adet (aktif dışı) profil kalsın? [varsayılan: 5] ${NC}"
        read -r keep
        keep="${keep:-5}"
        prune_old_profiles "${keep}"
        ;;
      o|O)
        show_settings_menu
        ;;
      q|Q)
        break
        ;;
      *)
        log_message "ERROR" "Geçersiz komut: ${cmd}"
        ;;
    esac

    printf '\n'
  done
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

ACTION="menu"
PRUNE_KEEP=""

pre_parse_ui_flags() {
  local arg
  for arg in "$@"; do
    case "${arg}" in
      --no-color) NO_COLOR=1 ;;
      --no-clear) NO_CLEAR=true ;;
    esac
  done
  ui::apply_style
}

parse_args() {
  ACTION="menu"
  PRUNE_KEEP=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help|help)
        ACTION="help"
        ;;
      -m|--menu|menu)
        ACTION="menu"
        ;;
      -l|--list|list)
        ACTION="list"
        ;;
      -s|--stats|stats)
        ACTION="stats"
        ;;
      -b|--backup|backup)
        ACTION="backup"
        ;;
      --doctor|doctor)
        ACTION="doctor"
        ;;
      --prune|prune)
        ACTION="prune"
        if [[ -n "${2:-}" ]] && [[ ! "${2}" =~ ^- ]]; then
          PRUNE_KEEP="${2}"
          shift
        fi
        ;;
      --sort)
        if [[ -z "${2:-}" ]]; then
          log_message "ERROR" "--sort bir değer ister (date|size|name)"
          return 1
        fi
        SORT_BY="${2}"
        shift
        ;;
      --details)
        if [[ -z "${2:-}" ]]; then
          log_message "ERROR" "--details bir değer ister (on|off)"
          return 1
        fi
        if ! SHOW_DETAILS="$(bool::parse "${2}")"; then
          log_message "ERROR" "Geçersiz --details değeri: ${2} (on|off)"
          return 1
        fi
        shift
        ;;
      --auto-backup)
        if [[ -z "${2:-}" ]]; then
          log_message "ERROR" "--auto-backup bir değer ister (on|off)"
          return 1
        fi
        if ! AUTO_BACKUP="$(bool::parse "${2}")"; then
          log_message "ERROR" "Geçersiz --auto-backup değeri: ${2} (on|off)"
          return 1
        fi
        shift
        ;;
      --confirm-delete)
        if [[ -z "${2:-}" ]]; then
          log_message "ERROR" "--confirm-delete bir değer ister (on|off)"
          return 1
        fi
        if ! CONFIRM_DELETE="$(bool::parse "${2}")"; then
          log_message "ERROR" "Geçersiz --confirm-delete değeri: ${2} (on|off)"
          return 1
        fi
        shift
        ;;
      --max-backups)
        if [[ -z "${2:-}" ]]; then
          log_message "ERROR" "--max-backups bir değer ister (1-50)"
          return 1
        fi
        MAX_BACKUPS="${2}"
        shift
        ;;
      --no-color)
        NO_COLOR=1
        ;;
      --no-clear)
        NO_CLEAR=true
        ;;
      -y|--yes)
        CONFIRM_DELETE=false
        ;;
      *)
        log_message "ERROR" "Geçersiz parametre: $1"
        return 1
        ;;
    esac
    shift
  done

  if ! sort::validate "${SORT_BY}"; then
    log_message "ERROR" "Geçersiz SORT_BY: ${SORT_BY} (date|size|name)"
    return 1
  fi

  if ! [[ "${MAX_BACKUPS}" =~ ^[0-9]+$ ]] || (( MAX_BACKUPS < 1 || MAX_BACKUPS > 50 )); then
    log_message "WARNING" "MAX_BACKUPS geçersiz: ${MAX_BACKUPS}; varsayılan 10 uygulanacak."
    MAX_BACKUPS=10
  fi

  if [[ "${ACTION}" == "prune" ]]; then
    PRUNE_KEEP="${PRUNE_KEEP:-5}"
  fi

  ui::apply_style
  return 0
}

main() {
  pre_parse_ui_flags "$@"
  log::init
  load_config
  parse_args "$@" || { show_help; exit 1; }

  case "${ACTION}" in
    help)
      show_help
      ;;
    menu)
      show_main_menu
      ;;
    list)
      ui::clear
      print_header
      print_active_system
      list_profiles false
      ;;
    stats)
      ui::clear
      print_header
      print_stats
      ;;
    backup)
      backup_profile "${SYSTEM_PROFILE}"
      ;;
    doctor)
      doctor
      ;;
    prune)
      prune_old_profiles "${PRUNE_KEEP}"
      ;;
    *)
      log_message "ERROR" "Bilinmeyen action: ${ACTION}"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
