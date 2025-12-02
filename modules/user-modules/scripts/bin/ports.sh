#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Port Scanner
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Network discovery and port scanning utility with advanced
#                vendor detection and comprehensive protocol support
#
#   Features:
#   - Network device discovery with vendor identification
#   - TCP/UDP port scanning capabilities
#   - Flexible port range and list scanning
#   - Host reachability verification
#   - Multi-distribution package management
#   - MAC vendor database integration
#   - Comprehensive error handling
#
#   License: MIT
#
#===============================================================================

# Renk tanımlamaları
GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

# Hata yakalama
trap 'echo -e "\n${RED}Script sonlandırıldı!${NC}"; exit 1' SIGINT SIGTERM

# Gerekli programların kontrolü
check_requirements() {
	local missing_pkgs=()

	# Gerekli programları kontrol et
	! command -v nmap >/dev/null && missing_pkgs+=("nmap")
	! command -v arp >/dev/null && missing_pkgs+=("net-tools")
	! command -v nc >/dev/null && missing_pkgs+=("gnu-netcat/netcat")
	! command -v ip >/dev/null && missing_pkgs+=("iproute2")
	! command -v ping >/dev/null && missing_pkgs+=("iputils")

	if [ ${#missing_pkgs[@]} -ne 0 ]; then
		echo -e "${RED}Eksik paketler: ${missing_pkgs[*]}${NC}"
		echo -e "${YELLOW}Kurulum komutları:${NC}"
		echo "Arch Linux: sudo pacman -S nmap net-tools gnu-netcat iproute2 iputils"
		echo "Ubuntu/Debian: sudo apt install nmap net-tools netcat iproute2 iputils-ping"
		echo "RHEL/CentOS: sudo yum install nmap net-tools nc iproute iputils"
		exit 1
	fi
}

# Yardım fonksiyonu
show_help() {
	echo -e "${YELLOW}Gelişmiş Ağ ve Port Tarama Scripti${NC}"
	echo -e "\n${YELLOW}KULLANIM:${NC}"
	echo "  $0 [seçenek]"
	echo -e "\n${YELLOW}Seçenekler:${NC}"
	echo "  discover              Ağdaki cihazları tara"
	echo "  scan <host> [port/port_aralığı/port_listesi] [tcp/udp]"
	echo -e "\n${YELLOW}Port Tarama Parametreleri:${NC}"
	echo "  host                    Hedef IP adresi veya hostname"
	echo "  port                    Port belirtimi:"
	echo "                          - Tek port: 80"
	echo "                          - Port aralığı: 80-100"
	echo "                          - Port listesi: 80,443,8080"
	echo "  tcp/udp                 Protokol seçimi (varsayılan: tcp)"
	echo -e "\n${YELLOW}Örnekler:${NC}"
	echo "  $0 discover             # Ağdaki cihazları bul"
	echo "  $0 scan 192.168.1.1 80  # Tek TCP port tarama"
	exit 1
}

# MAC adresi üretici bilgisi sorgulama
get_vendor_info() {
	local mac=$1
	local vendor="Bilinmiyor"

	# MAC adresinin ilk 6 karakterini al (OUI)
	local oui=$(echo "$mac" | tr -d ':' | tr -d '-' | cut -c1-6 | tr '[:lower:]' '[:upper:]')

	# Çevrimdışı OUI veritabanı varsa kullan
	if [ -f "/usr/share/nmap/nmap-mac-prefixes" ]; then
		vendor=$(grep -i "^$oui" "/usr/share/nmap/nmap-mac-prefixes" | cut -d' ' -f2- || echo "Bilinmiyor")
	elif [ -f "/var/lib/ieee-data/oui.txt" ]; then
		vendor=$(grep -i "^$oui" "/var/lib/ieee-data/oui.txt" | cut -d$'\t' -f3 || echo "Bilinmiyor")
	fi

	echo "$vendor"
}

# Ağ keşif fonksiyonu
discover_network() {
	local subnet

	# Yerel ağ bilgisini al
	if command -v ip &>/dev/null; then
		subnet=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -n1)
	else
		subnet=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*/[0-9]*' | head -n1 | grep -Eo '([0-9]*\.){3}[0-9]*/[0-9]*')
	fi

	if [ -z "$subnet" ]; then
		echo -e "${RED}Ağ bilgisi alınamadı!${NC}"
		return 1
	fi

	echo -e "${YELLOW}Ağ taraması başlatılıyor: $subnet${NC}\n"

	# ARP tablosunu temizle
	arp -d &>/dev/null

	# Hızlı ping taraması
	if command -v nmap &>/dev/null; then
		echo -e "${YELLOW}Nmap ile ağ taraması yapılıyor...${NC}"
		nmap -sn "$subnet" | grep "Nmap scan report"
	else
		echo -e "${YELLOW}Ping taraması yapılıyor...${NC}"
		prefix=$(echo "$subnet" | cut -d'/' -f1 | rev | cut -d'.' -f2- | rev)
		for i in {1..254}; do
			(ping -c 1 -W 1 "$prefix.$i" >/dev/null && echo -e "${GREEN}Aktif host: $prefix.$i${NC}") &
		done
		wait
	fi

	echo -e "\n${YELLOW}ARP tablosu ve Cihaz Bilgileri:${NC}"
	echo -e "\n${GREEN}IP Adresi\t\tMAC Adresi\t\tÜretici${NC}"
	echo "=================================================================="

	# ARP tablosunu işle ve üretici bilgilerini ekle
	while read -r line; do
		if [[ $line =~ \((.*)\).*at[[:space:]]([0-9a-fA-F:]+)[[:space:]] ]]; then
			ip="${BASH_REMATCH[1]}"
			mac="${BASH_REMATCH[2]}"
			vendor=$(get_vendor_info "$mac")
			printf "%-20s\t%s\t%s\n" "$ip" "$mac" "$vendor"
		fi
	done < <(arp -a | grep -v "incomplete")
}

# IP adresi kontrolü
validate_ip() {
	local ip=$1
	if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		return 1
	fi
	return 0
}

# Host erişilebilirlik kontrolü
check_host() {
	local host=$1
	echo -e "${YELLOW}Host kontrol ediliyor: $host${NC}"
	if ping -c 1 -W 1 "$host" >/dev/null 2>&1; then
		echo -e "${GREEN}Host aktif!${NC}"
		return 0
	else
		echo -e "${RED}Host yanıt vermiyor!${NC}"
		return 1
	fi
}

# Port tarama fonksiyonu
check_port() {
	local host=$1
	local port=$2
	local protocol=${3:-tcp}
	local timeout=1

	if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
		echo -e "${RED}Geçersiz port numarası: $port${NC}"
		return 1
	fi

	if [ "$protocol" = "tcp" ]; then
		nc_opts="-z -w $timeout"
	else
		nc_opts="-zu -w $timeout"
	fi

	if nc $nc_opts "$host" "$port" 2>/dev/null; then
		echo -e "${GREEN}$port/$protocol açık${NC}"
		return 0
	else
		echo -e "${RED}$port/$protocol kapalı${NC}"
		return 1
	fi
}

# Ana program başlangıcı
if [ $# -lt 1 ]; then
	show_help
fi

# Gerekli programları kontrol et
check_requirements

case "$1" in
discover)
	discover_network
	;;
scan)
	if [ $# -lt 3 ]; then
		show_help
	fi
	host=$2
	port_spec=$3
	protocol=${4:-tcp}

	# Protocol kontrolü
	if [ "$protocol" != "tcp" ] && [ "$protocol" != "udp" ]; then
		echo -e "${RED}Geçersiz protokol. 'tcp' veya 'udp' kullanın.${NC}"
		exit 1
	fi

	# Host kontrolü
	if ! validate_ip "$host" && ! host "$host" >/dev/null 2>&1; then
		echo -e "${RED}Geçersiz host adresi: $host${NC}"
		exit 1
	fi

	# Host erişilebilirlik kontrolü
	if ! check_host "$host"; then
		echo -e "${RED}Host erişilemez durumda. Tarama sonlandırılıyor.${NC}"
		exit 1
	fi

	START=$(date +%s)

	# Port tarama işlemi
	if [[ "$port_spec" == *-* ]]; then
		# Port aralığı tarama
		IFS=- read -r start_port end_port <<<"$port_spec"
		if ! [[ "$start_port" =~ ^[0-9]+$ ]] || ! [[ "$end_port" =~ ^[0-9]+$ ]]; then
			echo -e "${RED}Geçersiz port aralığı${NC}"
			exit 1
		fi
		echo -e "${YELLOW}Port aralığı taranıyor ($protocol): $start_port - $end_port${NC}"
		for ((port = start_port; port <= end_port; port++)); do
			check_port "$host" "$port" "$protocol"
		done
	elif [[ "$port_spec" == *,* ]]; then
		# Port listesi tarama
		IFS=',' read -ra PORTS <<<"$port_spec"
		echo -e "${YELLOW}Port listesi taranıyor ($protocol)${NC}"
		for port in "${PORTS[@]}"; do
			check_port "$host" "$port" "$protocol"
		done
	else
		# Tek port tarama
		check_port "$host" "$port_spec" "$protocol"
	fi

	END=$(date +%s)
	DIFF=$((END - START))
	echo -e "\n${GREEN}Tarama tamamlandı!${NC}"
	echo -e "${YELLOW}Toplam süre: $DIFF saniye${NC}"
	;;
*)
	show_help
	;;
esac

exit 0
