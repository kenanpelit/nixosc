#!/usr/bin/env bash

set -x

#===============================================================================
#
#   Script: Brave Profile Startup Manager
#   Version: 1.0.0
#   Date: 2025-04-08
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Brave tarayıcı profillerini ve web uygulamalarını kontrollü
#                şekilde başlatan otomatik başlatma scripti
#
#   Features:
#   - Farklı Brave profillerini belirli workspace'lere yerleştirir
#   - Çoklu başlatmaları önler (uygulama kontrolü)
#   - Web uygulamalarını belirli profillerle açar (WhatsApp, YouTube, vb.)
#   - VPN kontrolü ve yönetimi (secure/bypass)
#   - Workspace yönetimi (Hyprland entegrasyonu)
#
#===============================================================================

# Yapılandırma Değişkenleri
readonly BRAVE_CMD="profile_brave"
readonly LOG_DIR="$HOME/.logs"
readonly LOG_FILE="$LOG_DIR/brave-startup.log"
readonly FINAL_WORKSPACE="2" # Son dönülecek workspace

# Bekleme süreleri
readonly PROFILE_WAIT=4       # Profil başlatıldıktan sonraki bekleme süresi
readonly PROFILE_AFTER_WAIT=1 # İşlem tamamlandıktan sonraki bekleme süresi
readonly APP_WAIT=4           # Web uygulaması başlatıldıktan sonraki bekleme süresi
readonly FULLSCREEN_WAIT=1    # Tam ekran komutu sonrası bekleme
readonly APP_AFTER_WAIT=1     # İşlem tamamlandıktan sonraki bekleme süresi

# Log dizinini oluştur
[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"

# Hata yakalama
set -euo pipefail
trap 'echo "Hata oluştu. Satır: $LINENO, Komut: $BASH_COMMAND"' ERR

# Yapılandırma: ProfileID:Workspace:VPNMode:Title:Class
# Tam olarak profil başlatıcının bize gösterdiği profil isimlerini kullanıyoruz
declare -A BRAVE_PROFILES=(
	["Kenp"]="1:secure:Kenp:Kenp"
	["Ai"]="3:bypass:Ai:Ai"
	["CompecTA"]="4:secure:CompecTA:CompecTA"
	["Whats"]="9:secure:WhatsApp:Whats"
)

# Yapılandırma: App:Workspace:VPNMode:ProfileID:Fullscreen
declare -A BRAVE_APPS=(
	["whatsapp"]="9:secure:Whats:yes"
	["youtube"]="7:secure:Kenp:yes"
	["tiktok"]="7:secure:Kenp:yes"
	["spotify"]="8:bypass:Kenp:yes"
	["discord"]="5:secure:Kenp:yes"
)

# Geçerli workspace'i izle
current_workspace=""

# Loglama Fonksiyonu
log() {
	local app="$1"
	local message="$2"
	local notify="${3:-false}"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	echo "[$timestamp] [$app] $message" | tee -a "$LOG_FILE"

	if [[ "$notify" == "true" ]]; then
		notify-send -a "Brave Startup" "$app: $message"
	fi
}

# VPN Durum Kontrolü
check_vpn() {
	local mode="$1"

	if [[ "$mode" == "secure" ]]; then
		# VPN bağlantısı var mı kontrol et
		if pgrep -x "openvpn" >/dev/null || ip link show tun0 >/dev/null 2>&1 || ip link show wg0-mullvad >/dev/null 2>&1; then
			return 0
		else
			log "VPN" "VPN bağlantısı gerekli ama aktif değil" "true"
			return 1
		fi
	fi

	return 0
}

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

# Pencereyi tam ekran yap - daha basit yaklaşım
make_fullscreen() {
	local workspace="$1"

	log "FULLSCREEN" "Workspace $workspace'deki aktif pencere tam ekran yapılıyor" "false"

	if command -v hyprctl >/dev/null; then
		# Workspace'de olduğumuzdan emin ol
		switch_workspace "$workspace"

		# Biraz bekle, pencere düzgün yüklensin
		sleep 1

		# Aktif pencereyi tam ekran yap - basit yaklaşım
		hyprctl dispatch fullscreen 1

		log "FULLSCREEN" "Tam ekran komutu gönderildi (workspace: $workspace)" "false"

		# Tam ekran komutunun uygulanması için bekle
		sleep $FULLSCREEN_WAIT
	fi
}

# Brave profilini başlat
launch_brave_profile() {
	local profile="$1"
	local config="${BRAVE_PROFILES[$profile]}"

	local workspace=$(echo "$config" | cut -d: -f1)
	local vpn_mode=$(echo "$config" | cut -d: -f2)
	local title=$(echo "$config" | cut -d: -f3)
	local class=$(echo "$config" | cut -d: -f4)

	# VPN kontrolü
	if ! check_vpn "$vpn_mode"; then
		log "BRAVE" "VPN gerekliyken bağlantı yok - $profile profili başlatılmıyor" "true"
		return 1
	fi

	# Önce workspace'e geç ve orada kal
	switch_workspace "$workspace"

	log "BRAVE" "$profile profili başlatılıyor (VPN: $vpn_mode, workspace: $workspace)" "true"

	# Brave profilini başlat
	$BRAVE_CMD "$profile" "--class=$class" "--title=$title" &

	# Uygulama açılması için bekle
	log "BRAVE" "$profile profili için açılması bekleniyor..." "false"
	sleep $PROFILE_WAIT

	# Workspace'de kalındığından emin ol
	switch_workspace "$workspace"

	log "BRAVE" "$profile profili işlemi tamamlandı" "false"

	# İşlem tamamlandı, biraz daha bekleyip diğerine geç
	sleep $PROFILE_AFTER_WAIT
	return 0
}

# Brave web uygulamasını başlat
launch_brave_app() {
	local app="$1"
	local config="${BRAVE_APPS[$app]}"

	local workspace=$(echo "$config" | cut -d: -f1)
	local vpn_mode=$(echo "$config" | cut -d: -f2)
	local profile=$(echo "$config" | cut -d: -f3)
	local fullscreen=$(echo "$config" | cut -d: -f4)

	# VPN kontrolü
	if ! check_vpn "$vpn_mode"; then
		log "APP" "VPN gerekliyken bağlantı yok - $app uygulaması başlatılmıyor" "true"
		return 1
	fi

	# Önce workspace'e geç ve orada kal
	switch_workspace "$workspace"

	log "APP" "$app uygulaması başlatılıyor (VPN: $vpn_mode, workspace: $workspace)" "true"

	# Web uygulamasını başlat
	$BRAVE_CMD "--$app" "--class=$app" "--title=$app" &

	# Uygulama açılması için bekle
	log "APP" "$app uygulaması için açılması bekleniyor..." "false"
	sleep $APP_WAIT

	# Workspace'de kalındığından emin ol
	switch_workspace "$workspace"

	# Tam ekrana geç
	if [[ "$fullscreen" == "yes" ]]; then
		make_fullscreen "$workspace"
	fi

	log "APP" "$app uygulaması işlemi tamamlandı" "false"

	# İşlem tamamlandı, biraz daha bekleyip diğerine geç
	sleep $APP_AFTER_WAIT
	return 0
}

# Hyprland durumunu kontrol et
check_hyprland() {
	if ! command -v hyprctl >/dev/null; then
		log "WARN" "Hyprctl bulunamadı, pencere yönetimi işlevleri devre dışı" "true"
		return 0
	fi

	return 0
}

# Ana fonksiyon
main() {
	log "START" "Brave Profile Startup başlatılıyor" "true"

	# Hyprland kontrolü
	check_hyprland

	# Her profili ve uygulamayı kendi workspace'inde tamamen işle

	# Ana profilleri başlat
	launch_brave_profile "Kenp"     # Workspace 1
	launch_brave_profile "Ai"       # Workspace 3
	launch_brave_profile "CompecTA" # Workspace 4

	# Web uygulamalarını başlat
	launch_brave_app "whatsapp" # Workspace 9
	launch_brave_app "spotify"  # Workspace 8
	launch_brave_app "youtube"  # Workspace 7
	launch_brave_app "tiktok"   # Workspace 7 (isteğe bağlı)
	launch_brave_app "discord"  # Workspace 5 (isteğe bağlı)

	# İşlemler tamamlandıktan sonra workspace 2'ye dön
	log "WORKSPACE" "Tüm uygulamalar başlatıldı, $FINAL_WORKSPACE numaralı workspace'e dönülüyor" "true"
	switch_workspace "$FINAL_WORKSPACE"

	log "DONE" "Tüm Brave profilleri ve uygulamaları başlatıldı" "true"
}

# Çalıştır
main "$@"
