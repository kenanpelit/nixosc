#!/usr/bin/env bash

#===============================================================================
#
#   Script: Brave Profile Startup Manager
#   Version: 2.0.0
#   Date: 2025-04-08
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Brave tarayıcı profillerini, web uygulamalarını ve terminal
#                oturumlarını semsumo ile başlatan otomatik başlatma scripti
#
#   Features:
#   - Semsumo entegrasyonu (yapılandırma semsumo config ile yönetilir)
#   - Terminal oturumları başlatma (kitty, wezterm, alacritty)
#   - Farklı Brave profillerini belirli workspace'lere yerleştirir
#   - Web uygulamalarını belirli profillerle açar (WhatsApp, YouTube, vb.)
#   - VPN kontrolü ve yönetimi (secure/bypass)
#   - Workspace yönetimi (Hyprland entegrasyonu)
#
#===============================================================================

# Yapılandırma Değişkenleri
readonly LOG_DIR="$HOME/.logs"
readonly LOG_FILE="$LOG_DIR/brave-startup.log"
readonly FINAL_WORKSPACE="2" # Son dönülecek workspace
readonly CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sem/config.json"
readonly SEMSUMO="semsumo"
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/system/scripts/start"

# Log dizinini oluştur
[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"

# Hata yakalama
set -euo pipefail
trap 'echo "Hata oluştu. Satır: $LINENO, Komut: $BASH_COMMAND"' ERR

# Loglama Fonksiyonu
log() {
	local app="$1"
	local message="$2"
	local notify="${3:-false}"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	echo "[$timestamp] [$app] $message" | tee -a "$LOG_FILE"

	if [[ "$notify" == "true" ]]; then
		notify-send -a "Uygulama Başlatıcı" "$app: $message"
	fi
}

# Geçerli workspace'i izle
current_workspace=""

# Workspace'e geçiş - ama sadece gerekliyse
switch_workspace() {
	local workspace="$1"

	# Aynı workspace'deyse geçiş yapma
	if [[ "$current_workspace" == "$workspace" ]]; then
		log "WORKSPACE" "Zaten $workspace numaralı workspace'deyiz, geçiş yapılmıyor" "false"
		return 0
	fi

	if command -v hyprctl >/dev/null; then
		log "WORKSPACE" "$workspace numaralı workspace'e geçiliyor" "false"
		hyprctl dispatch workspace "$workspace"
		current_workspace="$workspace"
		sleep 1 # İşlemin tamamlanması için kısa bekleme
	fi
}

# Profil başlatma - artık semsumo aracılığıyla
launch_profile() {
	local profile_name="$1"

	# Script dosyasını kontrol et
	local script_path="$SCRIPTS_DIR/start-${profile_name,,}.sh"

	if [[ ! -f "$script_path" ]]; then
		log "ERROR" "$profile_name için script bulunamadı: $script_path" "true"
		return 1
	fi

	log "LAUNCH" "$profile_name başlatılıyor (script: $script_path)" "true"

	# Script'i çalıştır
	bash "$script_path"

	log "DONE" "$profile_name başlatma işlemi tamamlandı" "false"
	return 0
}

# Profillerin workspace bilgisini config'den al
get_workspace() {
	local profile="$1"
	local workspace

	if [[ -f "$CONFIG_FILE" ]]; then
		workspace=$(jq -r ".sessions.\"$profile\".workspace // \"0\"" "$CONFIG_FILE")
		if [[ "$workspace" == "null" || "$workspace" == "0" ]]; then
			log "WARN" "$profile için workspace bilgisi bulunamadı" "false"
			echo "0"
		else
			echo "$workspace"
		fi
	else
		log "ERROR" "Config dosyası bulunamadı: $CONFIG_FILE" "false"
		echo "0"
	fi
}

# Profilin vpn modunu al
get_vpn_mode() {
	local profile="$1"
	local vpn_mode

	if [[ -f "$CONFIG_FILE" ]]; then
		vpn_mode=$(jq -r ".sessions.\"$profile\".vpn // \"secure\"" "$CONFIG_FILE")
		echo "$vpn_mode"
	else
		log "ERROR" "Config dosyası bulunamadı: $CONFIG_FILE" "false"
		echo "secure" # Varsayılan olarak secure döndür
	fi
}

# Terminal oturumlarını başlat
start_terminal_sessions() {
	log "TERMINAL" "Terminal oturumları başlatılıyor..." "true"

	# Terminal oturumlarını başlat
	log "TERMINAL" "kkenp oturumu başlatılıyor" "true"
	launch_profile "kkenp"

	#log "TERMINAL" "wkenp oturumu başlatılıyor" "true"
	#launch_profile "wkenp"

	#log "TERMINAL" "mkenp oturumu başlatılıyor" "true"
	#launch_profile "mkenp"

	log "TERMINAL" "Tüm terminal oturumları başlatıldı" "true"
}

# Brave profilleri ve uygulamalarını başlat
start_brave_profiles() {
	local profiles=(
		"Brave-Kenp"
		"Brave-Ai"
		"Brave-CompecTA"
	)

	for profile in "${profiles[@]}"; do
		launch_profile "$profile"
	done
}

# Brave web uygulamalarını başlat
start_brave_apps() {
	local apps=(
		"Brave-Whatsapp"
		"Brave-Spotify"
		"Brave-Yotube"
		#"Brave-Tiktok"  # İsteğe bağlı
		#"Brave-Discord" # İsteğe bağlı
	)

	for app in "${apps[@]}"; do
		launch_profile "$app"
	done
}

# Hyprland durumunu kontrol et
check_hyprland() {
	if ! command -v hyprctl >/dev/null; then
		log "WARN" "Hyprctl bulunamadı, pencere yönetimi işlevleri sınırlı olabilir" "true"
		return 1
	fi

	return 0
}

# Ana fonksiyon
main() {
	log "START" "Uygulama Başlatma Yöneticisi başlatılıyor" "true"

	# Hyprland kontrolü
	check_hyprland

	# Terminal oturumlarını başlat
	start_terminal_sessions

	# Profilleri başlat
	start_brave_profiles

	# Web uygulamalarını başlat
	start_brave_apps

	# İşlemler tamamlandıktan sonra workspace 2'ye dön
	log "WORKSPACE" "Tüm uygulamalar başlatıldı, $FINAL_WORKSPACE numaralı workspace'e dönülüyor" "true"
	switch_workspace "$FINAL_WORKSPACE"

	log "DONE" "Tüm uygulamalar başarıyla başlatıldı" "true"
}

# Çalıştır
main "$@"
