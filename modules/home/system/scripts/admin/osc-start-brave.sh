#!/usr/bin/env bash

#===============================================================================
#
#   Script: Brave Profile Startup Manager
#   Version: 2.0.0
#   Date: 2025-04-08
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Brave tarayıcı profillerini, web uygulamalarını ve terminal
#                oturumlarını başlatan otomatik başlatma scripti
#
#   Features:
#   - Terminal oturumları için semsumo entegrasyonu
#   - Brave profilleri için doğrudan profile_brave kullanımı
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
readonly PROFILE_BRAVE="profile_brave"

# Bekleme süreleri
readonly WAIT_TIME=3 # Uygulama açılması için bekleme süresi

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

# Tam ekran yapma fonksiyonu
make_fullscreen() {
	if command -v hyprctl &>/dev/null; then
		log "FULLSCREEN" "Aktif pencere tam ekran yapılıyor..." "false"
		sleep 1
		hyprctl dispatch fullscreen 1
		sleep 1
	fi
}

# Terminal profili başlatma - semsumo aracılığıyla
launch_terminal_profile() {
	local profile_name="$1"

	# Komutu çalıştır
	log "LAUNCH" "$profile_name başlatılıyor" "true"
	start-$profile_name

	log "DONE" "$profile_name başlatma işlemi tamamlandı" "false"
	return 0
}

# Semsumo uygulamasını başlatma
launch_semsumo_app() {
	local app_name="$1"

	log "LAUNCH" "$app_name uygulaması başlatılıyor" "true"

	# Komutu doğrudan çalıştır
	start-$app_name

	log "DONE" "$app_name başlatma işlemi tamamlandı" "false"
	return 0
}

# Brave profili başlatma
launch_brave_profile() {
	local profile="$1"
	local workspace="$2"
	local class="${3:-$profile}"
	local title="${4:-$profile}"
	local fullscreen="${5:-false}"

	# Workspace'e geç
	switch_workspace "$workspace"

	log "BRAVE" "$profile profili başlatılıyor (workspace: $workspace)" "true"

	# Brave profilini doğrudan başlat
	$PROFILE_BRAVE "$profile" --class="$class" --title="$title" --restore-last-session &

	# Uygulamanın yüklenmesi için bekle
	log "BRAVE" "$profile profili için açılması bekleniyor..." "false"
	sleep $WAIT_TIME

	# Tam ekran yapılacaksa
	if [[ "$fullscreen" == "true" ]]; then
		make_fullscreen
	fi

	log "BRAVE" "$profile profili başlatıldı" "false"
	return 0
}

# Brave web uygulaması başlatma
launch_brave_app() {
	local app="$1"
	local workspace="$2"
	local fullscreen="${3:-true}"

	# Workspace'e geç
	switch_workspace "$workspace"

	log "APP" "$app uygulaması başlatılıyor (workspace: $workspace)" "true"

	# Web uygulamasını doğrudan başlat
	$PROFILE_BRAVE "--$app" --class="$app" --title="$app" --restore-last-session &

	# Uygulamanın yüklenmesi için bekle
	log "APP" "$app uygulaması için açılması bekleniyor..." "false"
	sleep $WAIT_TIME

	# Tam ekran yapılacaksa
	if [[ "$fullscreen" == "true" ]]; then
		make_fullscreen
	fi

	log "APP" "$app uygulaması başlatıldı" "false"
	return 0
}

# Terminal oturumlarını başlat
start_terminal_sessions() {
	log "TERMINAL" "Terminal oturumları başlatılıyor..." "true"

	# Terminal oturumlarını başlat
	log "TERMINAL" "kkenp oturumu başlatılıyor" "true"
	launch_terminal_profile "kkenp"

	#log "TERMINAL" "wkenp oturumu başlatılıyor" "true"
	#launch_terminal_profile "wkenp"

	#log "TERMINAL" "mkenp oturumu başlatılıyor" "true"
	#launch_terminal_profile "mkenp"

	log "TERMINAL" "Tüm terminal oturumları başlatıldı" "true"
}

# Brave profilleri başlat
start_brave_profiles() {
	log "BRAVE" "Brave profilleri başlatılıyor..." "true"

	# Ana profiller (Profil ismi, Workspace, Class, Title, Fullscreen)
	launch_brave_profile "Kenp" "1" "Kenp" "Kenp" "false"
	launch_brave_profile "Ai" "3" "Ai" "Ai" "false"
	launch_brave_profile "CompecTA" "4" "CompecTA" "CompecTA" "false"

	log "BRAVE" "Tüm Brave profilleri başlatıldı" "true"
}

# Uygulamaları başlat (Semsumo ve Brave karışık)
start_applications() {
	log "APP" "Uygulamalar başlatılıyor..." "true"

	# WhatsApp
	launch_brave_app "whatsapp" "9" "true"

	# Spotify - Semsumo komutu ile başlat
	log "APP" "Spotify başlatılıyor..." "true"
	launch_semsumo_app "spotify"

	# YouTube - Brave ile başlat
	launch_brave_app "youtube" "7" "true"

	# Webcord - Semsumo komutu ile başlat
	log "APP" "Discord başlatılıyor..." "true"
	launch_semsumo_app "webcord"

	#launch_brave_app "tiktok" "7" "true"   # İsteğe bağlı
	#launch_brave_app "discord" "5" "true"  # İsteğe bağlı

	log "APP" "Tüm uygulamalar başlatıldı" "true"
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

	# Brave profilleri başlat
	start_brave_profiles

	# Uygulamaları başlat (Web ve Spotify)
	start_applications

	# İşlemler tamamlandıktan sonra workspace 2'ye dön
	log "WORKSPACE" "Tüm uygulamalar başlatıldı, $FINAL_WORKSPACE numaralı workspace'e dönülüyor" "true"
	switch_workspace "$FINAL_WORKSPACE"

	log "DONE" "Tüm uygulamalar başarıyla başlatıldı" "true"
}

# Çalıştır
main "$@"
