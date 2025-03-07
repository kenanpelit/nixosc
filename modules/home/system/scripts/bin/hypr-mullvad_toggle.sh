#!/usr/bin/env bash
#===============================================================================
#
#   Script Adı: mullvad-manager
#   Versiyon: 1.1.0
#   Tarih: 2025-03-07
#   Orijinal Yazar: Kenan Pelit
#   Repository: github.com/kenanpelit/dotfiles
#   Açıklama:
#
#   Bu script Mullvad VPN bağlantısını yönetmek için kullanılır.
#   Temel işlevleri:
#   - VPN bağlantısını açma/kapama
#   - Mevcut bağlantı durumunu kontrol etme
#   - Sistem bildirimlerini gösterme
#   - Bağlantı durumunu detaylı gösterme
#   - Bağlantı sırasında timeout kontrolü
#
#   Kullanım:
#   ./mullvad-manager [toggle|connect|disconnect|status|help]
#   Parametre verilmezse otomatik olarak toggle (aç/kapa) işlemi gerçekleştirilir
#
#   Not: Bu script çalışmak için Mullvad VPN'in sistemde kurulu olmasını gerektirir
#   ve notify-send komutunu kullanarak masaüstü bildirimleri gönderir.
#
#   Lisans: MIT
#
#===============================================================================

VERSION="1.1.0"
SCRIPT_NAME=$(basename "$0")
TIMEOUT=30 # Seconds to wait for connection before timeout

# Script sourcing kontrolü
[[ "${BASH_SOURCE[0]}" != "$0" ]] && echo "Script source edilemez!" && exit 1

# Gerekli komutların varlığını kontrol et
check_requirements() {
	command -v mullvad >/dev/null 2>&1 || {
		echo "Hata: Mullvad VPN kurulu değil!"
		exit 1
	}

	# notify-send optional olabilir
	if ! command -v notify-send >/dev/null 2>&1; then
		echo "Uyarı: notify-send bulunamadı, bildirimler devre dışı olacak."
		# Bildirim fonksiyonunu override et
		notify() { :; }
	fi
}

# Bildirim gönderme fonksiyonu (daha esnek)
notify() {
	local title="$1"
	local message="$2"
	local icon="$3"

	notify-send -t 5000 "$title" "$message" -i "$icon"
}

# Loglama fonksiyonu
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Mullvad VPN durumunu kontrol et
check_vpn_status() {
	local full_status
	full_status=$(mullvad status 2>/dev/null)

	if [[ $? -ne 0 ]]; then
		log "Hata: Mullvad VPN durum kontrolü başarısız oldu."
		return 2
	fi

	if echo "$full_status" | grep -q "Connected"; then
		# Bağlantı aktif
		return 0
	elif echo "$full_status" | grep -q "Connecting"; then
		# Bağlanıyor
		return 3
	elif echo "$full_status" | grep -q "Disconnecting"; then
		# Bağlantı kesiliyor
		return 4
	else
		# Bağlantı yok
		return 1
	fi
}

# Detaylı VPN durumunu göster
show_vpn_status() {
	local status_output
	status_output=$(mullvad status 2>/dev/null)

	if [[ $? -ne 0 ]]; then
		log "Hata: Mullvad VPN durum kontrolü başarısız oldu."
		notify "❌ MULLVAD VPN" "Status check failed" "security-low"
		return 1
	fi

	log "Mullvad VPN Durumu:"
	log "$status_output"

	if echo "$status_output" | grep -q "Connected"; then
		# Bağlantı konumunu çıkart
		local location
		location=$(echo "$status_output" | grep -o "in [^)]*" | sed 's/in //')
		notify "🔒 MULLVAD VPN" "Connected to $location" "security-high"
	else
		notify "🔓 MULLVAD VPN" "Disconnected" "security-medium"
	fi

	echo "$status_output"
}

# VPN'e bağlan (timeout'lu)
connect_vpn() {
	log "Mullvad VPN'e bağlanılıyor..."
	mullvad connect >/dev/null 2>&1 &
	local pid=$!
	disown

	# Bağlantı için timeout ile bekle
	local counter=0
	while ((counter < TIMEOUT)); do
		sleep 1
		((counter++))

		check_vpn_status
		local status=$?

		if [[ $status -eq 0 ]]; then
			log "VPN bağlantısı başarıyla kuruldu."
			local location
			location=$(mullvad status | grep -o "in [^)]*" | sed 's/in //' || echo "VPN")
			notify "🔒 MULLVAD VPN" "Connected to $location" "security-high"
			return 0
		elif [[ $status -eq 1 ]]; then
			# Hala bağlı değil, devam et
			continue
		elif [[ $status -eq 2 ]]; then
			log "Hata: VPN durum kontrolü başarısız oldu."
			notify "❌ MULLVAD VPN" "Connection failed" "security-low"
			return 1
		fi
	done

	log "Hata: VPN bağlantısı zaman aşımına uğradı."
	notify "❌ MULLVAD VPN" "Connection timeout" "security-low"
	return 1
}

# VPN bağlantısını kes
disconnect_vpn() {
	log "Mullvad VPN bağlantısı kesiliyor..."
	mullvad disconnect >/dev/null 2>&1 &
	local pid=$!
	disown

	# Bağlantı kesilmesi için kısa bir süre bekle
	sleep 2

	check_vpn_status
	if [[ $? -eq 1 ]]; then
		log "VPN bağlantısı başarıyla kesildi."
		notify "🔓 MULLVAD VPN" "Disconnected" "security-medium"
		return 0
	else
		log "Uyarı: VPN bağlantısı kesilirken bir sorun oluştu."
		notify "⚠️ MULLVAD VPN" "Disconnect issue" "security-low"
		return 1
	fi
}

# VPN bağlantısını aç/kapa
toggle_vpn() {
	check_vpn_status
	local status=$?

	if [[ $status -eq 0 ]]; then
		disconnect_vpn
	elif [[ $status -eq 1 ]]; then
		connect_vpn
	elif [[ $status -eq 3 ]]; then
		log "VPN şu anda bağlanıyor, lütfen bekleyin."
		notify "⏳ MULLVAD VPN" "Currently connecting..." "security-medium"
	elif [[ $status -eq 4 ]]; then
		log "VPN şu anda bağlantı kesiliyor, lütfen bekleyin."
		notify "⏳ MULLVAD VPN" "Currently disconnecting..." "security-medium"
	else
		log "Hata: VPN durumu belirlenemedi."
		notify "❌ MULLVAD VPN" "Status unknown" "security-low"
	fi
}

# Yardım mesajını göster
show_help() {
	echo "Mullvad VPN Yönetim Scripti v$VERSION"
	echo
	echo "Kullanım: $SCRIPT_NAME [KOMUT]"
	echo
	echo "Komutlar:"
	echo "  toggle      : VPN bağlantısını aç/kapa (varsayılan)"
	echo "  connect     : VPN'e bağlan"
	echo "  disconnect  : VPN bağlantısını kes"
	echo "  status      : Mevcut VPN durumunu göster"
	echo "  help        : Bu yardım mesajını göster"
	echo
	echo "Parametre verilmezse otomatik olarak toggle (aç/kapa) işlemi gerçekleştirilir."
}

# Ana işlem
main() {
	# Gereklilikleri kontrol et
	check_requirements

	# Parametre kontrolü ve işlem
	case "${1:-toggle}" in
	toggle)
		toggle_vpn
		;;
	connect)
		check_vpn_status
		if [[ $? -eq 0 ]]; then
			log "VPN zaten bağlı."
			notify "ℹ️ MULLVAD VPN" "Already connected" "security-high"
		else
			connect_vpn
		fi
		;;
	disconnect)
		check_vpn_status
		if [[ $? -eq 1 ]]; then
			log "VPN zaten bağlı değil."
			notify "ℹ️ MULLVAD VPN" "Already disconnected" "security-medium"
		else
			disconnect_vpn
		fi
		;;
	status)
		show_vpn_status
		;;
	help | --help | -h)
		show_help
		;;
	*)
		echo "Hata: Bilinmeyen komut '$1'"
		echo
		show_help
		exit 1
		;;
	esac
}

# Scripti çalıştır
main "$@"
