#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Remote Tunnel Manager
#   Version: 1.2.0
#   Date: 2024-04-29
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Remote SSH tunnel manager with search capabilities for
#                filtering tunnel connections and status
#
#   Features:
#   - SSH connection with color preservation
#   - Quick tunnel status search
#   - Configurable connection parameters
#   - Direct tunnel command execution
#   - Pattern-based filtering
#   - Connection status check before attempting to connect
#   - Automatic byobu session management
#
#   License: MIT
#
#===============================================================================

# Terminal renkleri
COLOR_HEADER='\033[1;95m'
COLOR_GREY='\033[1;30m'
COLOR_LGREY='\033[0;30m'
COLOR_WHITE='\033[0;37m'
COLOR_BOLD='\033[1;37m'
COLOR_BLUE='\033[1;94m'
COLOR_LBLUE='\033[0;94m'
COLOR_HBLUE='\033[1;44m'
COLOR_GREEN='\033[1;92m'
COLOR_HGREEN='\033[1;42m'
COLOR_WARNING='\033[1;93m'
COLOR_HWARNING='\033[1;43m'
COLOR_RED='\033[1;91m'
COLOR_HRED='\033[1;41m'
COLOR_CYAN='\033[1;96m'
COLOR_HCYAN='\033[1;46m'
COLOR_MAGENTA='\033[1;95m'
COLOR_LMAGENTA='\033[0;95m'
COLOR_HMAGENTA='\033[1;45m'
COLOR_END='\033[1;0m'

# SSH bağlantı parametreleri
REMOTE_USER="$(pass terminal-user)"
REMOTE_HOST="$(pass terminal-host)"
REMOTE_PORT="$(pass terminal-port)"
TUNNEL_DB="$(pass terminal-db)"

# Function to get tunnel database via SSH and format using pure bash
fetch_tunnel_list() {
	local search_pattern="$1"
	local user="$2"
	local online_only="$3"

	# Doğrudan sunucuda cat, grep ve awk kullanarak çıktıyı biçimlendir
	local cmd="cat ${TUNNEL_DB}"

	# Çıktıyı doğrudan uzak sunucuda biçimlendir
	cmd+=' | awk -F"|" '\''
    BEGIN {
        # Online kontrolünü daha güvenilir yapmak için baştan kontrol et
        if ("'$online_only'" == "true") {
            online_only = 1;
        } else {
            online_only = 0;
        }
    }
    {
        port=$1;
        name=$2;
        hostname=$3;
        description=$4;
        date=$5;
        
        # Arama desenine göre filtrele
        if ("'$search_pattern'" != "" && 
            tolower(name) !~ tolower("'$search_pattern'") && 
            tolower(hostname) !~ tolower("'$search_pattern'") && 
            tolower(description) !~ tolower("'$search_pattern'")) {
            next;
        }
        
        # Bağlantı durumunu kontrol et
        cmd = "nc -z -w1 127.0.0.1 " port " 2>/dev/null";
        if (system(cmd) == 0) {
            conn_status = "\033[48;5;108m\033[38;5;232m CONNECTED \033[0m";
            connected = 1;
        } else {
            conn_status = "\033[48;5;174m\033[38;5;232m NOTCONNEC \033[0m";
            connected = 0;
        }
        
        # Online filtresi varsa ve bağlı değilse bu satırı atla
        if (online_only == 1 && connected == 0) {
            next;
        }
        
        # Çıktı renklerini ve formatını ayarla
        printf("\033[48;5;175m\033[38;5;232m TUNNEL \033[0m \033[48;5;116m\033[38;5;232m %-15s \033[0m %s", name, conn_status);
        
        # SSH komutunu göster
        printf(" ssh -p %s '$user'@localhost", port);
        
        # Tarih bilgisi
        if (date != "") {
            printf(" \033[38;5;240mDate: %s\033[0m", date);
        }
        
        # Açıklama ve hostname
        printf(" \033[38;5;139m%s - hostname: %s\033[0m\n", description, hostname);
    }'\'''

	# Uzak sunucuda komutu çalıştır
	ssh -p "${REMOTE_PORT}" -t "${REMOTE_USER}@${REMOTE_HOST}" "$cmd"
}

# Bir port'un açık olup olmadığını kontrol et (tünelin bağlı olup olmadığı)
is_connected() {
	local port=$1

	# Doğrudan uzak sunucuda port kontrolü yap
	local cmd="nc -z -w1 127.0.0.1 $port 2>/dev/null && echo 'CONNECTED' || echo 'NOTCONNECTED'"
	local status=$(ssh -p "${REMOTE_PORT}" "${REMOTE_USER}@${REMOTE_HOST}" "$cmd")

	if [ "$status" = "CONNECTED" ]; then
		return 0 # Bağlı
	else
		return 1 # Bağlı değil
	fi
}

# Belirli bir tünele bağlan
connect_to_tunnel() {
	local tunnel_name="$1"
	local user="$2"

	echo -e "\033[38;5;110mBağlanıyor: $tunnel_name\033[0m"

	# Tünel bilgisini al
	local tunnel_info=$(ssh -p "${REMOTE_PORT}" "${REMOTE_USER}@${REMOTE_HOST}" "cat ${TUNNEL_DB} | grep -E '^[^|]*\\|${tunnel_name}\\|'")

	if [ -z "$tunnel_info" ]; then
		echo -e "\033[38;5;174mHata: $tunnel_name adlı tünel bulunamadı!\033[0m"
		exit 1
	fi

	# Debug: tünel bilgisini göster
	echo -e "\033[38;5;110mBulunan tünel: \033[38;5;145m$tunnel_info\033[0m"

	# Port bilgisini ayıkla (ilk "|" işaretinden önceki kısım)
	local port=$(echo "$tunnel_info" | cut -d'|' -f1)
	local hostname=$(echo "$tunnel_info" | cut -d'|' -f3)
	local description=$(echo "$tunnel_info" | cut -d'|' -f4)
	local date=$(echo "$tunnel_info" | cut -d'|' -f5)

	# Tünelin bağlı olup olmadığını kontrol et
	# Doğrudan terminal sunucusunda port kontrolü yap
	local connection_check="nc -z -w1 127.0.0.1 $port 2>/dev/null"
	local is_tunnel_open=$(ssh -p "${REMOTE_PORT}" "${REMOTE_USER}@${REMOTE_HOST}" "$connection_check; echo \$?")

	if [ "$is_tunnel_open" != "0" ]; then
		echo -e "\033[48;5;174m\033[38;5;232m BAĞLANTI YOK \033[0m \033[38;5;174mHata: $tunnel_name tüneli aktif değil! Bağlantı kurulamaz.\033[0m"
		exit 1
	fi

	# Byobu komutu - oturum ismi "kenan" olarak sabit
	local BYOBU_CMD="byobu has -t kenan || byobu new-session -d -s kenan && byobu a -t kenan"

	echo -e "\033[48;5;108m\033[38;5;232m Çalıştırılıyor \033[0m \033[38;5;114mssh -t -J terminal -p $port $user@localhost \"$BYOBU_CMD\"\033[0m"
	echo -e "\033[48;5;108m\033[38;5;232m Byobu oturumu başlatılıyor \033[0m"

	# Görsel ayrıştırıcı
	echo -e " "

	# SSH komutu çalıştır - her zaman byobu ile
	ssh -t -J terminal -p $port $user@localhost "$BYOBU_CMD"

	# Bağlantı sonlandığında görsel bildirim
	echo -e "\033[48;5;108m\033[38;5;232m                Bağlantı sonlandırıldı                \033[0m"
}

# Yardım bilgisini göster
show_help() {
	cat <<EOF
Kullanım: $(basename $0) [SEÇENEKLER] [ARAMA_DESENİ]

Seçenekler:
  -c, --connect ISIM     ISIM adlı tünele bağlan (otomatik byobu oturumu)
  -u, --user KULLANICI   Uzak makineye bağlanırken kullanılacak kullanıcı (varsayılan: root)
  -o, --online           Sadece bağlı olan tünelleri listele
  -h, --help             Bu yardım mesajını göster ve çık

Örnekler:
  $(basename $0)                     # Tüm tünelleri listele
  $(basename $0) production          # "production" içeren tünelleri listele
  $(basename $0) -c myserver         # "myserver" adlı tünele bağlan (byobu oturumu otomatik)
  $(basename $0) -o                  # Sadece bağlı tünelleri listele

Not: Tüm bağlantılar otomatik olarak byobu oturumu ('kenan' isimli) başlatır.

CompecTA HPC Solutions (c) 2024
EOF
}

# Ana fonksiyon
main() {
	local tunnel_name=""
	local user="root"
	local online_only="false"
	local search_pattern=""

	# Eğer özel parametreler varsa işle
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-c | --connect)
			if [[ -z "$2" || "$2" == -* ]]; then
				echo "Hata: --connect parametresi için tünel ismi gerekli"
				show_help
				exit 1
			fi
			tunnel_name="$2"
			shift 2
			;;
		-u | --user)
			if [[ -z "$2" || "$2" == -* ]]; then
				echo "Hata: --user parametresi için kullanıcı adı gerekli"
				show_help
				exit 1
			fi
			user="$2"
			shift 2
			;;
		-o | --online)
			online_only="true"
			shift
			;;
		-h | --help)
			show_help
			exit 0
			;;
		*)
			# İlk pozisyonel argüman arama deseni olarak kullanılır
			if [[ -z "$search_pattern" && "$1" != -* ]]; then
				search_pattern="$1"
				shift
			else
				echo "Bilinmeyen parametre: $1"
				show_help
				exit 1
			fi
			;;
		esac
	done

	# Eğer tünel bağlantısı istendiyse
	if [[ -n "$tunnel_name" ]]; then
		connect_to_tunnel "$tunnel_name" "$user"
	else
		# Aksi halde tünelleri listele (arama deseni veya online flagi ile)
		fetch_tunnel_list "$search_pattern" "$user" "$online_only"
	fi
}

# Programı çalıştır
main "$@"
