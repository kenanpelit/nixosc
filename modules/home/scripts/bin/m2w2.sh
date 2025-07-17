#!/usr/bin/env bash

# Hyprland Otomatik Monitor ve Workspace Yöneticisi
# Kullanım: ./script.sh [workspace] [--options]
# Örnek: ./script.sh 2

set -euo pipefail # Hata durumunda çık, tanımsız değişkenleri yakalama

# Varsayılan değerler
DEFAULT_WORKSPACE="2"
SLEEP_DURATION="0.2"
PRIMARY_MONITOR="eDP-1" # Laptop ekranı
NOTIFY_ENABLED=true
NOTIFY_TIMEOUT=3000 # milisaniye

# Yardım fonksiyonu
show_help() {
	cat <<EOF
Hyprland Otomatik Monitor ve Workspace Yöneticisi

Kullanım: $0 [SEÇENEKLER] [WORKSPACE]

SEÇENEKLER:
    -h, --help          Bu yardım mesajını göster
    -l, --list          Mevcut monitörleri ve workspace'leri listele
    -t, --timeout NUM   Monitör geçiş bekleme süresi (varsayılan: $SLEEP_DURATION)
    -m, --monitor NAME  Manuel olarak monitör seç (otomatik algılama yerine)
    -n, --no-notify     Bildirimleri devre dışı bırak
    -p, --primary       Sadece birincil monitöre geç

ÖRNEKLER:
    $0                  # Harici monitör bul ve varsayılan workspace'e ($DEFAULT_WORKSPACE) geç
    $0 5               # Harici monitör bul ve workspace 5'e geç
    $0 -m DP-2 3       # Manuel olarak DP-2'ye geçip workspace 3'e git
    $0 -p              # Laptop ekranına dön
    $0 --list          # Mevcut monitörleri listele

EOF
}

# Bildirim gönder
send_notification() {
	if [ "$NOTIFY_ENABLED" = false ]; then
		return
	fi

	local title=$1
	local message=$2
	local urgency=${3:-normal}
	local icon=${4:-video-display}

	# notify-send varsa kullan
	if command -v notify-send &>/dev/null; then
		notify-send -t "$NOTIFY_TIMEOUT" -u "$urgency" -i "$icon" "$title" "$message"
	# dunstify varsa kullan (daha gelişmiş)
	elif command -v dunstify &>/dev/null; then
		dunstify -t "$NOTIFY_TIMEOUT" -u "$urgency" -i "$icon" "$title" "$message"
	# hyprctl notify kullan (Hyprland dahili)
	else
		local color="rgb(61afef)"                          # Mavi
		[ "$urgency" = "critical" ] && color="rgb(e06c75)" # Kırmızı
		hyprctl notify -1 "$NOTIFY_TIMEOUT" "$color" "$title: $message"
	fi
}

# Hyprctl'nin çalışır durumda olup olmadığını kontrol et
check_hyprland() {
	if ! command -v hyprctl &>/dev/null; then
		echo "Hata: hyprctl bulunamadı. Hyprland çalışıyor mu?" >&2
		exit 1
	fi

	if ! hyprctl version &>/dev/null; then
		echo "Hata: Hyprland'a bağlanılamadı. Hyprland çalışıyor mu?" >&2
		exit 1
	fi
}

# Mevcut monitörleri listele
list_monitors() {
	echo "Mevcut monitörler:"
	hyprctl monitors -j 2>/dev/null | jq -r '.[] | "  \(.name) - \(.width)x\(.height) @ \(.refreshRate)Hz (\(if .focused then "AKTIF" else "pasif" end))"' ||
		hyprctl monitors | grep -E "^Monitor" | sed 's/^/  /'
}

# Mevcut workspace'leri listele
list_workspaces() {
	echo "Mevcut workspace'ler:"
	hyprctl workspaces -j 2>/dev/null | jq -r '.[] | "  Workspace \(.id): \(.windows) pencere"' ||
		hyprctl workspaces | grep -E "^workspace" | sed 's/^/  /'
}

# Harici monitör bul
find_external_monitor() {
	local monitors
	if command -v jq &>/dev/null; then
		# jq varsa JSON parsing kullan
		monitors=$(hyprctl monitors -j | jq -r '.[] | select(.name != "'"$PRIMARY_MONITOR"'") | .name' 2>/dev/null | head -1)
	else
		# jq yoksa grep/awk kullan
		monitors=$(hyprctl monitors | grep "^Monitor" | grep -v "$PRIMARY_MONITOR" | awk '{print $2}' | head -1)
	fi

	echo "$monitors"
}

# Aktif monitörü bul
get_active_monitor() {
	if command -v jq &>/dev/null; then
		hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null
	else
		hyprctl monitors | grep -B5 "focused: yes" | grep "^Monitor" | awk '{print $2}'
	fi
}

# Monitor detaylarını al
get_monitor_info() {
	local monitor=$1
	if command -v jq &>/dev/null; then
		hyprctl monitors -j | jq -r ".[] | select(.name == \"$monitor\") | \"\\(.width)x\\(.height)@\\(.refreshRate)Hz\""
	else
		hyprctl monitors | grep -A20 "^Monitor $monitor" | grep -E "(^[[:space:]]*[0-9]+x[0-9]+)" | head -1 | awk '{print $1}'
	fi
}

# Monitörün var olup olmadığını kontrol et
validate_monitor() {
	local monitor=$1
	if command -v jq &>/dev/null; then
		if ! hyprctl monitors -j | jq -e ".[] | select(.name == \"$monitor\")" &>/dev/null; then
			return 1
		fi
	else
		if ! hyprctl monitors | grep -q "^Monitor $monitor"; then
			return 1
		fi
	fi
	return 0
}

# Workspace'in geçerli olup olmadığını kontrol et
validate_workspace() {
	local workspace=$1
	if ! [[ "$workspace" =~ ^[0-9]+$ ]] || [ "$workspace" -lt 1 ] || [ "$workspace" -gt 10 ]; then
		echo "Hata: Workspace '$workspace' geçerli değil. 1-10 arası bir sayı olmalı." >&2
		exit 1
	fi
}

# Komut çalıştır ve hata kontrolü yap
run_hyprctl() {
	local cmd=$1
	local desc=$2

	echo "→ $desc"
	if ! hyprctl dispatch "$cmd" &>/dev/null; then
		echo "Hata: $desc başarısız oldu" >&2
		send_notification "Hyprland Hata" "$desc başarısız oldu" "critical" "dialog-error"
		exit 1
	fi
}

# Ana işlem
main() {
	local monitor=""
	local workspace=$DEFAULT_WORKSPACE
	local manual_monitor=false
	local primary_only=false

	# Argüman işleme
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			show_help
			exit 0
			;;
		-l | --list)
			list_monitors
			echo
			list_workspaces
			exit 0
			;;
		-t | --timeout)
			if [[ -n ${2:-} ]] && [[ $2 =~ ^[0-9]+\.?[0-9]*$ ]]; then
				SLEEP_DURATION=$2
				shift 2
			else
				echo "Hata: --timeout için geçerli bir sayı gerekli" >&2
				exit 1
			fi
			;;
		-m | --monitor)
			if [[ -n ${2:-} ]]; then
				monitor=$2
				manual_monitor=true
				shift 2
			else
				echo "Hata: --monitor için monitör adı gerekli" >&2
				exit 1
			fi
			;;
		-n | --no-notify)
			NOTIFY_ENABLED=false
			shift
			;;
		-p | --primary)
			primary_only=true
			shift
			;;
		-*)
			echo "Hata: Bilinmeyen seçenek: $1" >&2
			show_help >&2
			exit 1
			;;
		*)
			# Pozisyonel argüman olarak workspace
			workspace=$1
			shift
			;;
		esac
	done

	# Hyprland kontrolü
	check_hyprland

	# Workspace doğrulama
	validate_workspace "$workspace"

	# Monitör seçimi
	if [ "$primary_only" = true ]; then
		monitor=$PRIMARY_MONITOR
		send_notification "Monitor Değiştiriliyor" "Birincil monitöre dönülüyor: $monitor" "normal"
	elif [ "$manual_monitor" = false ]; then
		# Otomatik harici monitör algılama
		echo "Harici monitör aranıyor..."
		monitor=$(find_external_monitor)

		if [ -z "$monitor" ]; then
			echo "Harici monitör bulunamadı, birincil monitör kullanılıyor: $PRIMARY_MONITOR"
			monitor=$PRIMARY_MONITOR
			send_notification "Harici Monitor Yok" "Harici monitör bulunamadı, laptop ekranı kullanılıyor" "normal" "video-display"
		else
			echo "Harici monitör bulundu: $monitor"
			local monitor_info=$(get_monitor_info "$monitor")
			send_notification "Harici Monitor Algılandı" "$monitor ($monitor_info) kullanılıyor" "normal" "video-display"
		fi
	fi

	# Monitor doğrulama
	if ! validate_monitor "$monitor"; then
		echo "Hata: '$monitor' monitörü bulunamadı." >&2
		send_notification "Monitor Hatası" "'$monitor' monitörü bulunamadı" "critical" "dialog-error"
		echo "Mevcut monitörler:" >&2
		list_monitors >&2
		exit 1
	fi

	# Mevcut monitörü kontrol et
	local current_monitor=$(get_active_monitor)

	echo "Hyprland Workspace Yöneticisi"
	echo "Mevcut monitor: $current_monitor"
	echo "Hedef monitor: $monitor"
	echo "Workspace: $workspace"
	echo "Bekleme süresi: ${SLEEP_DURATION}s"
	echo

	# Eğer zaten hedef monitördeyse sadece workspace değiştir
	if [ "$current_monitor" = "$monitor" ]; then
		echo "Zaten $monitor monitöründe, sadece workspace değiştiriliyor"
		run_hyprctl "workspace $workspace" "Workspace $workspace'e geçiliyor"
	else
		# Komutları çalıştır
		run_hyprctl "focusmonitor $monitor" "Monitör $monitor'a odaklanılıyor"

		# Monitör geçişinin tamamlanması için bekle
		sleep "$SLEEP_DURATION"

		run_hyprctl "workspace $workspace" "Workspace $workspace'e geçiliyor"
	fi

	echo "✓ İşlem tamamlandı!"

	# Başarı bildirimi
	local monitor_info=$(get_monitor_info "$monitor")
	send_notification "İşlem Tamamlandı" "$monitor ($monitor_info) - Workspace $workspace" "normal" "emblem-success"
}

# Script'i çalıştır
main "$@"
