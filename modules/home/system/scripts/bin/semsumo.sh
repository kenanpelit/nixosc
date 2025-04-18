#!/usr/bin/env bash

#set -x

#######################################
#
# Version: 3.0.0
# Author: Kenan Pelit
# Description: Semsumo - Terminal ve Uygulama Oturumları Yöneticisi
#
# Özellikler:
# - VPN (Mullvad) entegrasyonu (secure/bypass)
# - Grup tabanlı oturum yönetimi
# - Oturum başlatma/durdurma/yeniden başlatma
# - Workspace entegrasyonu
# - Başlatma scripti oluşturucu
#
# Yapılandırma: Script içinde gömülü
# PID: /tmp/sem/
#
# Lisans: MIT
#
#######################################

set -euo pipefail
IFS=$'\n\t'

# Temel yapılandırma
readonly VERSION="3.0.0"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sem"
readonly CONFIG_FILE="$CONFIG_DIR/config.json"
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/system/scripts/start"
readonly PID_DIR="/tmp/sem"
readonly DEFAULT_WAIT_TIME=2

# Renk tanımları
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Global değişkenler
DEBUG=0
CREATE_MODE=0
CONFIG_OVERRIDE=""
OUTPUT_OVERRIDE=""
PARALLEL=0

# Gömülü grup tanımları - kolayca düzenlenebilir
declare -A APP_GROUPS
APP_GROUPS["browsers"]="Brave-Kenp Brave-CompecTA Brave-Ai Brave-Whats" # Ana tarayıcılar
#APP_GROUPS["terminals"]="kkenp mkenp wkenp"                             # Terminal oturumları
APP_GROUPS["terminals"]="kkenp" # Terminal oturumları
#APP_GROUPS["communications"]="discord webcord Brave-Whatsapp"           # İletişim uygulamaları
APP_GROUPS["communications"]="webcord"                      # İletişim uygulamaları
APP_GROUPS["media"]="spotify Brave-Spotify"                 # Medya uygulamaları
APP_GROUPS["all"]="browsers terminals communications media" # Tüm gruplar

# Gömülü oturum yapılandırması
EMBEDDED_CONFIG='{
  "sessions": {
    "kkenp": {
      "command": "kitty",
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tm"],
      "vpn": "bypass"
    },
    "mkenp": {
      "command": "kitty",
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tm"],
      "vpn": "secure"
    },
    "wkenp": {
      "command": "wezterm",
      "args": ["start", "--class", "TmuxKenp", "-e", "tm"],
      "vpn": "bypass"
    },
    "wezterm": {
      "command": "wezterm",
      "args": ["start", "--class", "wezterm"],
      "vpn": "secure",
      "workspace": "2"
    },
    "kitty-single": {
      "command": "kitty",
      "args": ["--class", "kitty", "-T", "kitty", "--single-instance"],
      "vpn": "secure",
      "workspace": "2"
    },
    "wezterm-rmpc": {
      "command": "wezterm",
      "args": ["start", "--class", "rmpc", "-e", "rmpc"],
      "vpn": "secure"
    },
    "discord": {
      "command": "discord",
      "args": ["-m", "--class=discord", "--title=discord"],
      "vpn": "bypass",
      "workspace": "5",
      "fullscreen": "true",
      "final_workspace": "2"
    },
    "webcord": {
      "command": "webcord",
      "args": ["-m", "--class=WebCord", "--title=Webcord"],
      "vpn": "bypass",
      "workspace": "5",
      "fullscreen": "true"
    },
    "Chrome-Kenp": {
      "command": "profile_chrome",
      "args": ["Kenp", "--class", "Kenp"],
      "vpn": "secure",
      "workspace": "1"
    },
    "Chrome-CompecTA": {
      "command": "profile_chrome",
      "args": ["CompecTA", "--class", "CompecTA"],
      "vpn": "secure",
      "workspace": "4"
    },
    "Chrome-AI": {
      "command": "profile_chrome",
      "args": ["AI", "--class", "AI"],
      "vpn": "secure",
      "workspace": "3"
    },
    "Chrome-Whats": {
      "command": "profile_chrome",
      "args": ["Whats", "--class", "Whats"],
      "vpn": "secure",
      "workspace": "9"
    },
    "Brave-Kenp": {
      "command": "profile_brave",
      "args": ["Kenp"],
      "vpn": "secure",
      "workspace": "1"
    },
    "Brave-CompecTA": {
      "command": "profile_brave",
      "args": ["CompecTA"],
      "vpn": "secure",
      "workspace": "4"
    },
    "Brave-Ai": {
      "command": "profile_brave",
      "args": ["Ai"],
      "vpn": "secure",
      "workspace": "3"
    },
    "Brave-Whats": {
      "command": "profile_brave",
      "args": ["Whats"],
      "vpn": "secure",
      "workspace": "9"
    },
    "Brave-Exclude": {
      "command": "profile_brave",
      "args": ["Exclude"],
      "vpn": "bypass",
      "workspace": "6"
    },
    "Brave-Yotube": {
      "command": "profile_brave",
      "args": ["--youtube"],
      "vpn": "secure",
      "workspace": "6",
      "fullscreen": "true"
    },
    "Brave-Tiktok": {
      "command": "profile_brave",
      "args": ["--tiktok"],
      "vpn": "secure",
      "workspace": "6",
      "fullscreen": "true"
    },
    "Brave-Spotify": {
      "command": "profile_brave",
      "args": ["--spotify"],
      "vpn": "secure",
      "workspace": "8",
      "fullscreen": "true"
    },
    "Brave-Discord": {
      "command": "profile_brave",
      "args": ["--discord"],
      "vpn": "secure",
      "workspace": "5",
      "final_workspace": "2",
      "wait_time": "2",
      "fullscreen": "true"
    },
    "Brave-Whatsapp": {
      "command": "profile_brave",
      "args": ["--whatsapp"],
      "vpn": "secure",
      "workspace": "9",
      "fullscreen": "true"
    },
    "Zen-Kenp": {
      "command": "zen",
      "args": ["-P", "Kenp", "--class", "Kenp", "--name", "Kenp", "--restore-session"],
      "vpn": "secure",
      "workspace": "1"
    },
    "Zen-CompecTA": {
      "command": "zen",
      "args": ["-P", "CompecTA", "--class", "CompecTA", "--name", "CompecTA", "--restore-session"],
      "vpn": "secure",
      "workspace": "4"
    },
    "Zen-Discord": {
      "command": "zen",
      "args": ["-P", "Discord", "--class", "Discord", "--name", "Discord", "--restore-session"],
      "vpn": "secure",
      "workspace": "5",
      "fullscreen": "true"
    },
    "Zen-NoVpn": {
      "command": "zen",
      "args": ["-P", "NoVpn", "--class", "AI", "--name", "AI", "--restore-session"],
      "vpn": "bypass",
      "workspace": "3"
    },
    "Zen-Proxy": {
      "command": "zen",
      "args": ["-P", "Proxy", "--class", "Proxy", "--name", "Proxy", "--restore-session"],
      "vpn": "bypass",
      "workspace": "7"
    },
    "Zen-Spotify": {
      "command": "zen",
      "args": ["-P", "Spotify", "--class", "Spotify", "--name", "Spotify", "--restore-session"],
      "vpn": "bypass",
      "workspace": "7",
      "fullscreen": "true"
    },
    "Zen-Whats": {
      "command": "zen",
      "args": ["-P", "Whats", "--class", "Whats", "--name", "Whats", "--restore-session"],
      "vpn": "secure",
      "workspace": "9",
      "fullscreen": "true"
    },
    "spotify": {
      "command": "spotify",
      "args": ["--class", "Spotify", "-T", "Spotify"],
      "vpn": "bypass",
      "workspace": "8",
      "fullscreen": "true"
    },
    "mpv": {
      "command": "mpv",
      "args": [],
      "vpn": "bypass",
      "workspace": "6",
      "fullscreen": "true"
    }
  }
}'

# Ortamı başlat
initialize() {
	# Gerekli dizinleri oluştur
	mkdir -p "$CONFIG_DIR" "$PID_DIR"

	# Yapılandırma dosyası mevcut değilse gömülü yapılandırmadan oluştur
	if [[ ! -f "$CONFIG_FILE" ]]; then
		echo "$EMBEDDED_CONFIG" >"$CONFIG_FILE"
		chmod 600 "$CONFIG_FILE"
		log_info "Varsayılan yapılandırma oluşturuldu: $CONFIG_FILE"
	fi
}

# Loglama fonksiyonları
log_info() {
	echo -e "${GREEN}[BİLGİ]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[UYARI]${NC} $1"
}

log_error() {
	echo -e "${RED}[HATA]${NC} $1"
}

log_success() {
	echo -e "${GREEN}✓${NC} $1"
}

log_debug() {
	if [[ $DEBUG -eq 1 ]]; then
		echo -e "${CYAN}[HATA AYIKLAMA]${NC} $1"
	fi
}

# VPN fonksiyonları
check_vpn() {
	if ! command -v mullvad &>/dev/null; then
		log_debug "Mullvad istemcisi bulunamadı, VPN bağlantısı olmadığı varsayılıyor"
		echo "false"
		return 0
	fi

	if mullvad status 2>/dev/null | grep -q "Connected"; then
		local vpn_details
		vpn_details=$(mullvad status | grep "Relay:" | awk -F': ' '{print $2}')
		log_debug "VPN aktif: $vpn_details"
		echo "true"
		return 0
	fi

	log_debug "VPN bağlantısı bulunamadı"
	echo "false"
	return 0
}

get_vpn_mode() {
	local session_name=$1
	local cli_mode=${2:-}

	case "$cli_mode" in
	bypass | secure)
		echo "$cli_mode"
		;;
	"")
		jq -r ".sessions.\"$session_name\".vpn // \"secure\"" "$CONFIG_FILE"
		;;
	*)
		log_error "Geçersiz VPN modu: $cli_mode. 'secure' veya 'bypass' kullanın"
		return 1
		;;
	esac
}

# Oturum yönetimi
execute_application() {
	local cmd=$1
	shift
	local -a args=("$@")

	log_debug "Çalıştırılıyor: $cmd ${args[*]}"
	nohup "$cmd" "${args[@]}" >/dev/null 2>&1 &
	echo $!
}

start_session() {
	local session_name=$1
	local vpn_param=${2:-}

	# Oturumun var olup olmadığını kontrol et
	local command
	command=$(jq -r ".sessions.\"${session_name}\".command" "$CONFIG_FILE")
	if [[ "$command" == "null" ]]; then
		log_error "Oturum bulunamadı: $session_name"
		return 1
	fi

	# Komut için argümanları al
	readarray -t args < <(jq -r ".sessions.\"${session_name}\".args[]" "$CONFIG_FILE" 2>/dev/null || echo "")

	# VPN modunu belirle
	local vpn_mode
	vpn_mode=$(get_vpn_mode "$session_name" "$vpn_param")
	local vpn_status
	vpn_status=$(check_vpn)
	local pid

	# VPN moduna göre başlat
	case "$vpn_mode" in
	secure)
		if [[ "$vpn_status" != "true" ]]; then
			log_warn "VPN bağlantısı bulunamadı. $session_name VPN koruması olmadan başlatılıyor."
			if command -v notify-send &>/dev/null; then
				notify-send "Oturum Yöneticisi" "VPN bağlantısı yok. $session_name VPN koruması olmadan başlatılıyor."
			fi
			pid=$(execute_application "$command" "${args[@]}")
		else
			log_info "$session_name VPN koruması ile başlatılıyor"
			pid=$(execute_application "$command" "${args[@]}")
		fi
		;;
	bypass)
		if [[ "$vpn_status" == "true" ]]; then
			if command -v mullvad-exclude &>/dev/null; then
				log_info "$session_name VPN tüneli dışında başlatılıyor"
				pid=$(mullvad-exclude "$command" "${args[@]}")
			else
				log_warn "mullvad-exclude bulunamadı - $session_name normal şekilde çalıştırılıyor"
				pid=$(execute_application "$command" "${args[@]}")
			fi
		else
			log_info "VPN aktif değil, $session_name normal şekilde başlatılıyor"
			pid=$(execute_application "$command" "${args[@]}")
		fi
		;;
	esac

	# PID'i kaydet
	local pid_file="$PID_DIR/${session_name}.pid"
	echo "$pid" >"$pid_file"
	log_success "Oturum başlatıldı: $session_name (PID: $pid)"

	# Workspace değiştirme işlemini yönet
	handle_workspace "$session_name" "$pid"

	return 0
}

handle_workspace() {
	local session_name=$1
	local pid=$2

	# Workspace belirtilip belirtilmediğini kontrol et
	local workspace
	workspace=$(jq -r ".sessions.\"${session_name}\".workspace // \"0\"" "$CONFIG_FILE")
	local fullscreen
	fullscreen=$(jq -r ".sessions.\"${session_name}\".fullscreen // \"false\"" "$CONFIG_FILE")
	local wait_time
	wait_time=$(jq -r ".sessions.\"${session_name}\".wait_time // \"$DEFAULT_WAIT_TIME\"" "$CONFIG_FILE")

	# Eğer workspace belirtilmişse ve hyprctl kullanılabilirse, geçiş yap
	if [[ "$workspace" != "0" && "$workspace" != "null" ]]; then
		if command -v hyprctl &>/dev/null; then
			log_info "$workspace workspace'ine geçiliyor"
			hyprctl dispatch workspace "$workspace"
			sleep 1

			# Tam ekran yapılacaksa
			if [[ "$fullscreen" == "true" ]]; then
				log_debug "$session_name tam ekran yapılmadan önce $wait_time saniye bekleniyor"
				sleep "$wait_time"
				hyprctl dispatch fullscreen 1
			fi

			# Son workspace'e geçiş yapılacaksa
			local final_workspace
			final_workspace=$(jq -r ".sessions.\"${session_name}\".final_workspace // \"\"" "$CONFIG_FILE")
			if [[ -n "$final_workspace" && "$final_workspace" != "null" && "$final_workspace" != "$workspace" ]]; then
				log_debug "$final_workspace workspace'ine geçmeden önce $wait_time saniye bekleniyor"
				sleep "$wait_time"
				hyprctl dispatch workspace "$final_workspace"
			fi
		else
			log_warn "hyprctl bulunamadı, workspace değiştirme devre dışı"
		fi
	fi
}

stop_session() {
	local session_name=$1
	local pid_file="$PID_DIR/${session_name}.pid"

	if [[ -f "$pid_file" ]]; then
		local pid
		pid=$(<"$pid_file")
		if kill "$pid" 2>/dev/null; then
			rm -f "$pid_file"
			log_success "Oturum durduruldu: $session_name"
			return 0
		fi
	fi
	log_error "Çalışan oturum bulunamadı: $session_name"
	return 1
}

restart_session() {
	local session_name=$1
	local vpn_param=${2:-}

	log_info "Oturum yeniden başlatılıyor: $session_name"
	if stop_session "$session_name"; then
		sleep 1
		start_session "$session_name" "$vpn_param"
		return $?
	else
		log_warn "Oturum $session_name çalışmıyordu, şimdi başlatılıyor"
		start_session "$session_name" "$vpn_param"
		return $?
	fi
}

# Utility functions
check_status() {
	local session_name=$1
	local pid_file="$PID_DIR/${session_name}.pid"

	if [[ -f "$pid_file" ]] && kill -0 "$(<"$pid_file")" 2>/dev/null; then
		echo "running"
	else
		echo "stopped"
	fi
}

show_version() {
	echo "semsumo sürüm $VERSION"
}

# Oturumları listele
list_sessions() {
	printf "${BLUE}%s${NC}\n" "Mevcut Oturumlar:"

	jq -r '.sessions | to_entries[] | {
        key: .key,
        command: .value.command,
        vpn: (.value.vpn // "secure"),
        workspace: (.value.workspace // "0"),
        args: (.value.args|join(" "))
    } | "\(.key):\n  Komut: \(.command)\n  VPN Modu: \(.vpn)\n  Workspace: \(.workspace)\n  Parametreler: \(.args)"' "$CONFIG_FILE" |
		while IFS= read -r line; do
			if [[ $line =~ :$ ]]; then
				session=${line%:}
				status=$(check_status "$session")
				if [[ "$status" == "running" ]]; then
					echo -e "${GREEN}${line} [ÇALIŞIYOR]${NC}"
				else
					echo -e "${GREEN}${line}${NC}"
				fi
			elif [[ $line =~ ^[[:space:]]*VPN[[:space:]]Modu:[[:space:]]*(.*) ]]; then
				mode=${BASH_REMATCH[1]}
				case "$mode" in
				secure) printf "  VPN Modu: ${RED}%s${NC}\n" "$mode" ;;
				bypass) printf "  VPN Modu: ${GREEN}%s${NC}\n" "$mode" ;;
				*) printf "  VPN Modu: ${YELLOW}%s${NC}\n" "$mode" ;;
				esac
			else
				echo "$line"
			fi
		done
}

# Grup işlemleri
list_groups() {
	printf "${BLUE}%s${NC}\n" "Tanımlı Gruplar:"

	for group in "${!APP_GROUPS[@]}"; do
		printf "${GREEN}%s${NC}: " "$group"
		# Grubun içeriğini göster
		local apps="${APP_GROUPS[$group]}"
		# Eğer grup adı "all" ise, bu bir meta grup - içindeki grup adlarını göster
		if [[ "$group" == "all" ]]; then
			printf "Meta-grup, içerik: ${YELLOW}%s${NC}\n" "$apps"
		else
			printf "${CYAN}%s${NC}\n" "$apps"
		fi
	done
}

# Bir grubu başlat
start_group() {
	local group_name=$1
	local parallel=${2:-false}

	if [[ ! -v APP_GROUPS["$group_name"] ]]; then
		log_error "Tanımlı grup bulunamadı: $group_name"
		return 1
	fi

	local group_content="${APP_GROUPS[$group_name]}"
	local start_time
	start_time=$(date +%s)

	# Eğer grup bir meta-grup ise (all gibi), alt grupları başlat
	if [[ "$group_name" == "all" || "$group_content" =~ browsers|terminals|communications|media ]]; then
		log_info "Meta-grup başlatılıyor: $group_name"
		for subgroup in $group_content; do
			if [[ -v APP_GROUPS["$subgroup"] ]]; then
				log_info "Alt grup başlatılıyor: $subgroup"
				start_group "$subgroup" "$parallel"
			else
				log_error "Alt grup bulunamadı: $subgroup"
			fi
		done
	else
		# Normal grup - oturumları başlat
		log_info "Grup başlatılıyor: $group_name ($group_content)"

		if [[ "$parallel" == "true" ]]; then
			log_debug "Paralel başlatma modu aktif"
			local pids=()
			for session in $group_content; do
				start_session "$session" &
				pids+=($!)
			done

			# Tüm paralel işlemlerin tamamlanmasını bekle
			for pid in "${pids[@]}"; do
				wait "$pid" || true # Hata olursa da devam et
			done
		else
			# Sıralı başlatma
			for session in $group_content; do
				start_session "$session"
			done
		fi
	fi

	local end_time
	end_time=$(date +%s)
	local duration=$((end_time - start_time))
	log_success "Grup başlatıldı: $group_name (Süre: ${duration}s)"

	# En son 2 numaralı workspace'e dön (varsayılan)
	if command -v hyprctl &>/dev/null; then
		log_info "Ana workspace'e dönülüyor (2)"
		hyprctl dispatch workspace 2
	fi
}

# Yardım göster
show_help() {
	cat <<EOF
Oturum Yöneticisi $VERSION - Terminal ve Uygulama Oturumları Yöneticisi

Kullanım: 
  semsumo <komut> [parametreler]

Komutlar:
  start   <oturum> [vpn_modu]  Oturum başlat
  stop    <oturum>             Oturum durdur
  restart <oturum> [vpn_modu]  Oturum yeniden başlat
  status  <oturum>             Oturum durumunu göster
  list                         Mevcut oturumları listele
  group   <grup>  [parallel]   Bir grup oturumu başlat (opsiyonel paralel)
  groups                       Tanımlı grupları listele
  version                      Versiyon bilgisi
  help                         Bu yardım mesajını göster
  --create [options]           Oturum yönetimi scriptleri oluştur
  
VPN Modları:
  bypass  : VPN dışında çalıştır (VPN'i bypass et)
  secure  : VPN üzerinden güvenli şekilde çalıştır

Yapılandırma Parametreleri:
  vpn             : "secure" veya "bypass" (VPN modu)
  workspace       : Uygulamanın çalışacağı Hyprland workspace numarası
  final_workspace : İşlem sonrası dönülecek workspace numarası
  wait_time       : Uygulama başlatıldıktan sonra beklenecek süre (saniye)
  fullscreen      : Uygulamayı tam ekran yapmak için "true" değeri ver

Grup Örnekleri:
  semsumo group browsers         # Tüm tarayıcıları başlat
  semsumo group terminals        # Tüm terminal oturumlarını başlat
  semsumo group communications -p # İletişim uygulamalarını paralel başlat
  semsumo group all              # Tüm grupları başlat

Örnek Kullanımlar:
  # Oturum başlatma örnekleri
  semsumo start secure-browser         # Yapılandırma VPN modunu kullan
  semsumo start local-browser bypass   # VPN dışında çalıştır
  semsumo restart discord secure       # VPN içinde yeniden başlat

  # Oturum yönetimi
  semsumo list                         # Tüm oturumları listele
  semsumo status spotify               # Oturum durumunu kontrol et
  semsumo stop discord                 # Oturumu durdur

  # Script oluşturma
  semsumo --create                     # Oturum scriptlerini oluştur
  semsumo --create --debug             # Detaylı bilgilerle oluştur

Yapılandırma dosyası: $CONFIG_FILE

Not: VPN modu yapılandırma dosyasında tanımlıysa ve komut satırında 
belirtilmemişse, yapılandırmadaki mod kullanılır. Hiçbiri belirtilmemişse 
"secure" mod varsayılan olarak kullanılır.
EOF
}

# Script oluşturma fonksiyonları
create_script() {
	local profile=$1
	local vpn_mode=$2
	local script_path="$SCRIPTS_DIR/start-${profile,,}.sh"

	if [[ ! -d "$SCRIPTS_DIR" ]]; then
		mkdir -p "$SCRIPTS_DIR"
	fi

	# Yapılandırmadan workspace ayarlarını al
	local workspace=$(jq -r ".sessions.\"$profile\".workspace // \"0\"" "$CONFIG_FILE")
	local final_workspace=$(jq -r ".sessions.\"$profile\".final_workspace // \"$workspace\"" "$CONFIG_FILE")
	local wait_time=$(jq -r ".sessions.\"$profile\".wait_time // \"$DEFAULT_WAIT_TIME\"" "$CONFIG_FILE")
	local fullscreen=$(jq -r ".sessions.\"$profile\".fullscreen // \"false\"" "$CONFIG_FILE")

	# Script içeriği oluştur
	cat >"$script_path" <<EOF
#!/usr/bin/env bash
#===============================================================================
# $profile için oluşturulan başlatma script'i
# VPN Modu: $vpn_mode
# Elle düzenlemeyin - semsumo tarafından otomatik oluşturulmuştur
#===============================================================================

# Hata yönetimi
set -euo pipefail

# Ortam ayarları
export TMPDIR="$PID_DIR"

# Sabitler
WORKSPACE=$workspace
FINAL_WORKSPACE=$final_workspace
WAIT_TIME=$wait_time

# Workspace'e geçiş fonksiyonu
switch_workspace() {
    local workspace="\$1"
    if command -v hyprctl &>/dev/null; then
        echo "Workspace \$workspace'e geçiliyor..."
        hyprctl dispatch workspace "\$workspace"
        sleep 1
    fi
}

# Tam ekran yapma fonksiyonu
make_fullscreen() {
    if command -v hyprctl &>/dev/null; then
        echo "Aktif pencere tam ekran yapılıyor..."
        sleep 1
        hyprctl dispatch fullscreen 1
        sleep 1
    fi
}

EOF

	# Workspace belirtilmişse geçiş ekle
	if [[ "$workspace" != "0" ]]; then
		cat >>"$script_path" <<EOF
# $profile workspace'ine geç
switch_workspace "\$WORKSPACE"

EOF
	fi

	# Oturum başlatma kodu
	cat >>"$script_path" <<EOF
# Semsumo ile oturumu başlat
echo "$profile başlatılıyor..."
semsumo start "$profile" "$vpn_mode" &

# Uygulamanın açılması için bekle
echo "Uygulama açılması için \$WAIT_TIME saniye bekleniyor..."
sleep \$WAIT_TIME

EOF

	# Fullscreen aktifse ekle
	if [[ "$fullscreen" == "true" ]]; then
		cat >>"$script_path" <<EOF
# Tam ekran yap
make_fullscreen

EOF
	fi

	# Son workspace farklıysa geçiş ekle
	if [[ "$final_workspace" != "0" && "$final_workspace" != "$workspace" ]]; then
		cat >>"$script_path" <<EOF
# Tamamlandığında ana workspace'e geri dön
echo "İşlem tamamlandı, workspace \$FINAL_WORKSPACE'e dönülüyor..."
switch_workspace "\$FINAL_WORKSPACE"

EOF
	fi

	# Script sonlandırma
	cat >>"$script_path" <<EOF
# Başarıyla çıkış yap
exit 0
EOF

	# Scripti çalıştırılabilir yap
	chmod 755 "$script_path"
	log_success "Oluşturuldu: start-${profile,,}.sh"
}

run_script_generator() {
	log_info "Script oluşturma başlatılıyor..."

	# jq kurulu mu kontrol et
	if ! command -v jq &>/dev/null; then
		log_error "Script oluşturma için jq gerekli"
		return 1
	fi

	# Script dizinini oluştur
	if [[ ! -d "$SCRIPTS_DIR" ]]; then
		mkdir -p "$SCRIPTS_DIR"
		log_info "Script dizini oluşturuldu: $SCRIPTS_DIR"
	fi

	# Tüm profilleri al
	local profiles
	profiles=$(jq -r '.sessions | keys[]' "$CONFIG_FILE")
	local total=$(echo "$profiles" | wc -l)

	log_info "$total profil için başlatma scriptleri oluşturuluyor..."

	# Her profil için işlem yap
	while IFS= read -r profile; do
		# Boş satırları atla
		if [[ -z "$profile" ]]; then
			continue
		fi

		# Yapılandırmadan VPN modunu al
		local vpn_mode
		vpn_mode=$(jq -r ".sessions.\"$profile\".vpn // \"secure\"" "$CONFIG_FILE")

		# Script oluştur
		create_script "$profile" "$vpn_mode"
	done <<<"$profiles"

	log_success "Script oluşturma tamamlandı! $total script oluşturuldu."

	# Kullanım örneği göster
	if [[ $total -gt 0 ]]; then
		local example
		example=$(jq -r '.sessions | keys[0]' "$CONFIG_FILE")
		echo ""
		log_info "Kullanım örneği: $SCRIPTS_DIR/start-${example,,}.sh"
	fi

	return 0
}

# Komut satırı parametreleri
parse_args() {
	# Script oluşturma modunu yönet
	if [[ "${1:-}" == "--create" ]]; then
		shift
		CREATE_MODE=1

		# Oluşturma için özel parametreleri ayrıştır
		while [[ $# -gt 0 ]]; do
			case $1 in
			--debug | -d)
				DEBUG=1
				shift
				;;
			--config | -c)
				CONFIG_OVERRIDE="$2"
				shift 2
				;;
			--output | -o)
				OUTPUT_OVERRIDE="$2"
				shift 2
				;;
			*)
				log_error "Bilinmeyen parametre: $1"
				show_help
				exit 1
				;;
			esac
		done

		# Alternatif yapılandırma belirtilmişse kullan
		if [[ -n "$CONFIG_OVERRIDE" ]]; then
			CONFIG_FILE="$CONFIG_OVERRIDE"
		fi

		# Alternatif çıkış dizini belirtilmişse kullan
		if [[ -n "$OUTPUT_OVERRIDE" ]]; then
			SCRIPTS_DIR="$OUTPUT_OVERRIDE"
		fi

		return 0
	fi

	# Hata ayıklama bayrağını yönet
	if [[ "${1:-}" == "--debug" || "${1:-}" == "-d" ]]; then
		DEBUG=1
		shift
	fi

	# Yapılandırma geçersiz kılmayı yönet
	if [[ "${1:-}" == "--config" || "${1:-}" == "-c" ]]; then
		if [[ -n "${2:-}" ]]; then
			CONFIG_FILE="$2"
			shift 2
		else
			log_error "--config parametresi için değer eksik"
			show_help
			exit 1
		fi
	fi

	# Paralel çalıştırma parametresi
	if [[ "${1:-}" == "--parallel" || "${1:-}" == "-p" ]]; then
		PARALLEL=1
		shift
	fi

	return 0
}

# Ana fonksiyon
main() {
	initialize
	parse_args "$@"

	# Script oluşturma modunu yönet
	if [[ $CREATE_MODE -eq 1 ]]; then
		run_script_generator
		exit $?
	fi

	# Normal komutları yönet
	case "${1:-}" in
	start)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		start_session "$2" "${3:-}"
		;;
	stop)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		stop_session "$2"
		;;
	restart)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		restart_session "$2" "${3:-}"
		;;
	status)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		check_status "$2"
		;;
	list)
		list_sessions
		;;
	group)
		if [[ -z "${2:-}" ]]; then
			list_groups
			exit 0
		fi
		if [[ $PARALLEL -eq 1 ]]; then
			start_group "$2" "true"
		else
			start_group "$2" "false"
		fi
		;;
	groups)
		list_groups
		;;
	version)
		show_version
		;;
	help | --help | -h)
		show_help
		;;
	*)
		show_help
		exit 1
		;;
	esac
}

# Scripti çalıştır
main "$@"
