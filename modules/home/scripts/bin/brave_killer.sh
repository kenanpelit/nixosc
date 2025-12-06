#!/usr/bin/env bash
#===============================================================================
#
#   Script: Brave Process Killer
#   Version: 2.0.0
#   Description: Basit ve etkili Brave process kapatma aracı
#
#===============================================================================

set -euo pipefail

# Renk tanımlamaları
readonly GREEN="\033[32m"
readonly YELLOW="\033[33m"
readonly RED="\033[31m"
readonly BLUE="\033[34m"
readonly RESET="\033[0m"

# Semboller
readonly SUCCESS="✓"
readonly ERROR="✗"
readonly WARNING="⚠"
readonly INFO="ℹ"

# Zaman aşımı ayarları
GRACEFUL_TIMEOUT=5
FORCE_TIMEOUT=2

# Kullanım bilgisi
usage() {
	echo "Brave Process Killer v2.0.0"
	echo
	echo "Kullanım: $0 [seçenekler]"
	echo
	echo "Seçenekler:"
	echo "  --profile=PROFIL    Sadece belirtilen profili kapat"
	echo "  --force             Hemen zorla kapat (SIGKILL)"
	echo "  --timeout=SANIYE    Graceful shutdown timeout (varsayılan: 5)"
	echo "  --dry-run           Sadece göster, kapatma"
	echo "  --help, -h          Bu yardımı göster"
	echo
	echo "Örnekler:"
	echo "  $0                     # Tüm Brave process'lerini kapat"
	echo "  $0 --profile=Work      # Sadece Work profilini kapat"
	echo "  $0 --force             # Hemen zorla kapat"
	echo "  $0 --dry-run           # Sadece analiz et"
	echo
	exit "${1:-0}"
}

# Loglama
log() {
	local level="$1"
	shift
	local message="$*"

	case "$level" in
	"ERROR")
		echo -e "${RED}${ERROR} $message${RESET}" >&2
		;;
	"WARN")
		echo -e "${YELLOW}${WARNING} $message${RESET}"
		;;
	"INFO")
		echo -e "${BLUE}${INFO} $message${RESET}"
		;;
	"SUCCESS")
		echo -e "${GREEN}${SUCCESS} $message${RESET}"
		;;
	*)
		echo "$message"
		;;
	esac
}

# Brave process'lerini bul
find_brave_processes() {
	local profile_filter="${1:-}"

	if [[ -n "$profile_filter" ]]; then
		pgrep -f "brave.*profile-directory.*$profile_filter" || true
	else
		pgrep -f "brave" || true
	fi
}

# Process'leri kapat
kill_brave() {
	local profile_filter="${1:-}"
	local force_kill="${2:-false}"
	local timeout="${3:-$GRACEFUL_TIMEOUT}"

	# Process'leri bul
	local pids
	pids=$(find_brave_processes "$profile_filter")

	if [[ -z "$pids" ]]; then
		log "INFO" "Çalışan Brave process'i bulunamadı"
		return 0
	fi

	local count
	count=$(echo "$pids" | wc -l)

	if [[ -n "$profile_filter" ]]; then
		log "INFO" "Profil '$profile_filter' için $count adet Brave process'i bulundu"
	else
		log "INFO" "$count adet Brave process'i bulundu"
	fi

	if [[ "${DRY_RUN:-false}" == "true" ]]; then
		log "INFO" "DRY RUN - Kapatılacak PID'ler: $(echo $pids | tr '\n' ' ')"
		return 0
	fi

	# Zorla kapatma
	if [[ "$force_kill" == "true" ]]; then
		log "WARN" "Process'ler zorla kapatılıyor..."
		echo "$pids" | xargs kill -9 2>/dev/null || true
		sleep "$FORCE_TIMEOUT"
	else
		# Önce nazikçe kapat (SIGTERM)
		log "INFO" "Brave'e düzgün kapanma sinyali gönderiliyor..."
		echo "$pids" | xargs kill -15 2>/dev/null || true

		# Timeout süresince bekle
		log "INFO" "Kapanma için $timeout saniye bekleniyor..."
		sleep "$timeout"

		# Hala çalışan var mı kontrol et
		local remaining
		remaining=$(find_brave_processes "$profile_filter")

		if [[ -n "$remaining" ]]; then
			local remaining_count
			remaining_count=$(echo "$remaining" | wc -l)
			log "WARN" "$remaining_count process hala çalışıyor. Zorla kapatılıyor..."
			echo "$remaining" | xargs kill -9 2>/dev/null || true
			sleep "$FORCE_TIMEOUT"
		fi
	fi

	# Final kontrol
	local final_check
	final_check=$(find_brave_processes "$profile_filter")

	if [[ -z "$final_check" ]]; then
		if [[ -n "$profile_filter" ]]; then
			log "SUCCESS" "Profil '$profile_filter' için tüm Brave process'leri kapatıldı"
		else
			log "SUCCESS" "Tüm Brave process'leri kapatıldı"
		fi
	else
		log "ERROR" "Bazı process'ler kapatılamadı"
		return 1
	fi
}

# Ana fonksiyon
main() {
	local profile_filter=""
	local force_kill=false
	local timeout="$GRACEFUL_TIMEOUT"

	# Parametreleri işle
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--profile=*)
			profile_filter="${1#*=}"
			;;
		--force)
			force_kill=true
			;;
		--timeout=*)
			timeout="${1#*=}"
			if ! [[ "$timeout" =~ ^[0-9]+$ ]]; then
				log "ERROR" "Geçersiz timeout değeri: $timeout"
				exit 1
			fi
			;;
		--dry-run)
			DRY_RUN=true
			;;
		--help | -h)
			usage 0
			;;
		*)
			log "ERROR" "Bilinmeyen parametre: $1"
			usage 1
			;;
		esac
		shift
	done

	# Ana işlem
	kill_brave "$profile_filter" "$force_kill" "$timeout"
}

# Scripti çalıştır
main "$@"
