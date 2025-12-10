#!/usr/bin/env bash
# osc-proxy.sh - Sistem proxy anahtarlayıcı
# HTTP/HTTPS/SOCKS proxy ayarlarını aç/kapat, ortam değişkenlerini ve servisleri günceller.

# SSH SOCKS Proxy Yönetim Scripti
# Kullanım: ./ssh-proxy.sh [start|stop|restart|status] [hostname] [port]

SCRIPT_NAME="SSH SOCKS Proxy"
DEFAULT_PORT="4999"
PID_FILE="/tmp/ssh-proxy.pid"
LOG_FILE="/tmp/ssh-proxy.log"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Renk sıfırlama

# Yardım fonksiyonu
show_help() {
	echo -e "${BLUE}$SCRIPT_NAME Yönetim Scripti${NC}"
	echo ""
	echo "Kullanım:"
	echo "  $0 start <hostname> [port]     - Proxy'yi başlat"
	echo "  $0 stop                        - Proxy'yi durdur"
	echo "  $0 restart <hostname> [port]   - Proxy'yi yeniden başlat"
	echo "  $0 status                      - Proxy durumunu göster"
	echo ""
	echo "Örnekler:"
	echo "  $0 start tosun"
	echo "  $0 start tosun 5000"
	echo "  $0 stop"
	echo "  $0 status"
	echo ""
	echo "Varsayılan port: $DEFAULT_PORT"
}

# Proxy durumu kontrolü
check_status() {
	if [ -f "$PID_FILE" ]; then
		PID=$(cat "$PID_FILE")
		if ps -p "$PID" >/dev/null 2>&1; then
			return 0 # Çalışıyor
		else
			rm -f "$PID_FILE" # Eski PID dosyasını temizle
			return 1          # Çalışmıyor
		fi
	else
		return 1 # PID dosyası yok
	fi
}

# Proxy'yi başlat
start_proxy() {
	local hostname=$1
	local port=${2:-$DEFAULT_PORT}

	if [ -z "$hostname" ]; then
		echo -e "${RED}Hata: Hostname belirtilmedi${NC}"
		show_help
		exit 1
	fi

	if check_status; then
		echo -e "${YELLOW}Proxy zaten çalışıyor (PID: $(cat $PID_FILE))${NC}"
		return 1
	fi

	echo -e "${BLUE}SSH SOCKS Proxy başlatılıyor...${NC}"
	echo "Hostname: $hostname"
	echo "Port: $port"
	echo "Log: $LOG_FILE"

	# SSH bağlantısını başlat
	ssh -fND "$port" \
		-C \
		-o ServerAliveInterval=60 \
		-o ServerAliveCountMax=3 \
		-o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null \
		-o LogLevel=ERROR \
		"$hostname" >"$LOG_FILE" 2>&1

	# SSH process PID'ini bul ve kaydet
	sleep 2
	SSH_PID=$(ps aux | grep "ssh.*-fND.*$port.*$hostname" | grep -v grep | awk '{print $2}')

	if [ -n "$SSH_PID" ]; then
		echo "$SSH_PID" >"$PID_FILE"
		echo -e "${GREEN}✓ Proxy başarıyla başlatıldı (PID: $SSH_PID)${NC}"
		echo -e "${GREEN}✓ SOCKS5 proxy: localhost:$port${NC}"
		echo ""
		echo -e "${BLUE}Tarayıcı ayarları:${NC}"
		echo "  SOCKS5 Proxy: 127.0.0.1"
		echo "  Port: $port"
	else
		echo -e "${RED}✗ Proxy başlatılamadı${NC}"
		echo -e "${YELLOW}Log dosyasını kontrol edin: $LOG_FILE${NC}"
		exit 1
	fi
}

# Proxy'yi durdur
stop_proxy() {
	if check_status; then
		PID=$(cat "$PID_FILE")
		echo -e "${BLUE}Proxy durduruluyor (PID: $PID)...${NC}"

		kill "$PID" 2>/dev/null
		sleep 2

		if ps -p "$PID" >/dev/null 2>&1; then
			echo -e "${YELLOW}Normal kapatma başarısız, zorla kapatılıyor...${NC}"
			kill -9 "$PID" 2>/dev/null
		fi

		rm -f "$PID_FILE"
		echo -e "${GREEN}✓ Proxy durduruldu${NC}"
	else
		echo -e "${YELLOW}Proxy zaten çalışmıyor${NC}"
	fi
}

# Proxy durumunu göster
show_status() {
	if check_status; then
		PID=$(cat "$PID_FILE")
		PORT=$(ps -p "$PID" -o args= | grep -o '\-D [0-9]*' | awk '{print $2}')
		HOST=$(ps -p "$PID" -o args= | awk '{print $NF}')

		echo -e "${GREEN}✓ Proxy çalışıyor${NC}"
		echo "  PID: $PID"
		echo "  Host: $HOST"
		echo "  Port: $PORT"
		echo "  SOCKS5: localhost:$PORT"

		# Bağlantı testini öner
		echo ""
		echo -e "${BLUE}Bağlantı testi:${NC}"
		echo "  curl --socks5 localhost:$PORT https://ipinfo.io/ip"
	else
		echo -e "${RED}✗ Proxy çalışmıyor${NC}"
	fi
}

# Proxy'yi yeniden başlat
restart_proxy() {
	echo -e "${BLUE}Proxy yeniden başlatılıyor...${NC}"
	stop_proxy
	sleep 2
	start_proxy "$1" "$2"
}

# Ana program
case "$1" in
start)
	start_proxy "$2" "$3"
	;;
stop)
	stop_proxy
	;;
restart)
	restart_proxy "$2" "$3"
	;;
status)
	show_status
	;;
*)
	show_help
	exit 1
	;;
esac
