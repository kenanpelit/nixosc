#!/usr/bin/env bash

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

help() {
  echo -e "${BLUE}Network Ayarları Sıfırlama Scripti${NC}"
  echo -e "${YELLOW}Kullanım: sudo $0 [SEÇENEK]${NC}\n"
  echo "Bu script aşağıdaki işlemleri gerçekleştirir:"
  echo "  - Mevcut ağ ayarlarını yedekler"
  echo "  - VPN bağlantılarını (Mullvad dahil) temizler"
  echo "  - DNS ayarlarını varsayılan sunucularla yapılandırır"
  echo "  - Route tablosunu sıfırlar ve yeniden yapılandırır"
  echo "  - Incus/LXD bridge ayarlarını kontrol eder"
  echo "  - Network servislerini yeniden başlatır"
  echo -e "\nSeçenekler:"
  echo "  -h, --help     Bu yardım mesajını gösterir"
  echo "  -y, --yes      Onay istemeden çalışır"
  echo -e "\nÖrnek kullanım:"
  echo "  sudo $0        Normal çalıştırma (onay isteyerek)"
  echo "  sudo $0 -y     Onay istemeden çalıştır"
  echo -e "\nNot: Bu script root yetkisi gerektirir."
  exit 0
}

# Komut satırı parametrelerini işle
SKIP_CONFIRM=false
for arg in "$@"; do
  case $arg in
  -h | --help)
    help
    ;;
  -y | --yes)
    SKIP_CONFIRM=true
    ;;
  *)
    echo -e "${RED}Geçersiz parametre: $arg${NC}"
    help
    ;;
  esac
done

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Bu script root yetkisi gerektirir.${NC}"
  echo "Lütfen 'sudo' ile çalıştırın."
  exit 1
fi

# DNS sunucuları
declare -a DNS_SERVERS=(
  "1.1.1.1#cloudflare-dns.com"
  "9.9.9.9#dns.quad9.net"
  "8.8.8.8#dns.google"
  "8.8.4.4#dns.google"
  "2606:4700:4700::1111#cloudflare-dns.com"
  "2620:fe::9#dns.quad9.net"
  "2001:4860:4860::8888#dns.google"
)

# Fonksiyonlar
get_network_info() {
  # Kablolu ve kablosuz interface'leri bul
  WIRED_INTERFACE=$(ip -br link show up |
    awk '{print $1}' |
    grep -E '^(en|eth)' |
    grep -v -E '^(tun|docker|br-|lxdbr|lo|veth|mullvad)' |
    head -n 1)

  WIRELESS_INTERFACE=$(ip -br link show up |
    awk '{print $1}' |
    grep -E '^(wl)' |
    grep -v -E '^(tun|docker|br-|lxdbr|lo|veth|mullvad)' |
    head -n 1)

  # Aktif interface'i belirle (önce wireless'ı kontrol et)
  if [ -n "$WIRELESS_INTERFACE" ] && ip addr show "$WIRELESS_INTERFACE" | grep -q "inet "; then
    MAIN_INTERFACE="$WIRELESS_INTERFACE"
    MAIN_IP=$(ip -br addr show "$WIRELESS_INTERFACE" | awk '{print $3}' | cut -d'/' -f1)
  elif [ -n "$WIRED_INTERFACE" ] && ip addr show "$WIRED_INTERFACE" | grep -q "inet "; then
    MAIN_INTERFACE="$WIRED_INTERFACE"
    MAIN_IP=$(ip -br addr show "$WIRED_INTERFACE" | awk '{print $3}' | cut -d'/' -f1)
  else
    echo -e "${RED}Aktif network interface bulunamadı!${NC}"
    exit 1
  fi

  # Gateway bilgisini al
  DEFAULT_GATEWAY=$(ip route | grep default | grep "$MAIN_INTERFACE" | awk '{print $3}' | head -n 1)

  # Incus/LXD bridge bilgileri
  INCUS_BRIDGE="lxdbr0"
  INCUS_IP="10.226.202.1"
  INCUS_NETWORK="10.226.202.0/24"

  echo -e "${GREEN}Bulunan interface'ler:${NC}"
  [ -n "$WIRED_INTERFACE" ] && echo -e "  Kablolu: $WIRED_INTERFACE"
  [ -n "$WIRELESS_INTERFACE" ] && echo -e "  Kablosuz: $WIRELESS_INTERFACE"
  echo -e "${GREEN}Aktif interface: $MAIN_INTERFACE${NC}"
  echo -e "${GREEN}IP Adresi: $MAIN_IP${NC}"
  echo -e "${GREEN}Gateway: $DEFAULT_GATEWAY${NC}"
}

# cleanup_mullvad fonksiyonunu güncelleyelim
cleanup_mullvad() {
  echo -e "${YELLOW}Mullvad VPN kontrol ediliyor...${NC}"

  if command -v mullvad >/dev/null 2>&1; then
    # Önce Mullvad'ın durumunu kontrol et
    if mullvad status 2>/dev/null | grep -q "Connected"; then
      echo "Mullvad VPN bağlantısı kesiliyor..."
      mullvad disconnect
      sleep 2
    else
      echo "Mullvad VPN zaten bağlı değil"
    fi

    # Daemon çalışıyor mu kontrol et
    if systemctl is-active --quiet mullvad-daemon; then
      echo "Mullvad servisi durduruluyor..."
      systemctl stop mullvad-daemon
      echo "Mullvad servisi durduruldu"
    fi
  else
    echo "Mullvad VPN kurulu değil"
  fi
}

backup_current_settings() {
  local BACKUP_DIR="/tmp/network_backup_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP_DIR"

  echo -e "${YELLOW}Mevcut ağ ayarları yedekleniyor...${NC}"
  ip route show >"$BACKUP_DIR/routes.txt"
  cp /etc/resolv.conf "$BACKUP_DIR/resolv.conf.backup"
  ip addr show >"$BACKUP_DIR/interfaces.txt"

  if command -v nmcli >/dev/null 2>&1; then
    nmcli connection show >"$BACKUP_DIR/nm_connections.txt"
  fi

  echo -e "${GREEN}Yedekleme tamamlandı: $BACKUP_DIR${NC}"
}

cleanup_vpn() {
  echo -e "${YELLOW}VPN bağlantıları kontrol ediliyor...${NC}"

  # VPN süreçlerini durdur
  VPN_PROCESSES=("openvpn" "openfortivpn" "openconnect" "vpnc" "xl2tpd" "strongswan" "pptp" "sstp-client")
  for vpn in "${VPN_PROCESSES[@]}"; do
    if pgrep "$vpn" >/dev/null; then
      echo "$vpn süreçleri durduruluyor..."
      killall -SIGTERM "$vpn" 2>/dev/null
      sleep 1
      killall -SIGKILL "$vpn" 2>/dev/null
    fi
  done

  # NetworkManager VPN bağlantılarını durdur
  if command -v nmcli >/dev/null 2>&1; then
    nmcli connection show --active | grep -i "vpn" | cut -d' ' -f1 | while read -r conn; do
      echo "NetworkManager VPN bağlantısı durduruluyor: $conn"
      nmcli connection down "$conn"
    done
  fi

  # TUN/TAP interface'lerini temizle
  for tun in $(ip link show | grep -E 'tun[0-9]+|tap[0-9]+' | cut -d: -f2 | awk '{print $1}'); do
    ip link set "$tun" down 2>/dev/null
    ip link delete "$tun" 2>/dev/null
  done
}

reset_network() {
  echo -e "${YELLOW}Ağ ayarları sıfırlanıyor...${NC}"

  # Route tablosunu temizle
  ip route flush table main

  # Ana interface için route'ları ekle
  if [ -n "$DEFAULT_GATEWAY" ] && [ -n "$MAIN_INTERFACE" ]; then
    echo "Ana interface route'ları ekleniyor..."
    ip route add default via "$DEFAULT_GATEWAY" dev "$MAIN_INTERFACE" proto dhcp src "$MAIN_IP" metric 600
    ip route add "192.168.0.0/24" dev "$MAIN_INTERFACE" proto kernel scope link src "$MAIN_IP" metric 600
  fi

  # Incus/LXD bridge için route ekle
  if ip link show "$INCUS_BRIDGE" >/dev/null 2>&1; then
    echo "Incus/LXD bridge route'u ekleniyor..."
    ip route add "$INCUS_NETWORK" dev "$INCUS_BRIDGE" proto kernel scope link src "$INCUS_IP"
  fi

  # DNS ayarlarını güncelle
  setup_dns

  # DHCP'yi yenile
  dhclient -r "$MAIN_INTERFACE"
  dhclient "$MAIN_INTERFACE"
}

setup_dns() {
  echo -e "${YELLOW}DNS ayarları yapılandırılıyor...${NC}"

  if systemctl is-active --quiet systemd-resolved; then
    local dns_servers=""
    for server in "${DNS_SERVERS[@]}"; do
      dns_servers+="${server%#*} "
    done

    cat >/etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=${dns_servers}
FallbackDNS=1.1.1.1 9.9.9.9 8.8.8.8 8.8.4.4
DNSStubListener=yes
DNSSEC=allow-downgrade
DNSOverTLS=no
EOF

    systemctl restart systemd-resolved
  else
    truncate -s 0 /etc/resolv.conf
    for server in "${DNS_SERVERS[@]}"; do
      echo "nameserver ${server%#*}" >>/etc/resolv.conf
    done
  fi
}

restart_networking() {
  echo -e "${YELLOW}Network servisleri yeniden başlatılıyor...${NC}"

  if systemctl is-active --quiet NetworkManager; then
    systemctl restart NetworkManager
  elif systemctl is-active --quiet networking; then
    systemctl restart networking
  fi

  if systemctl is-active --quiet systemd-resolved; then
    systemctl restart systemd-resolved
  fi
}

check_incus_status() {
  echo -e "${YELLOW}Incus/LXD durumu kontrol ediliyor...${NC}"

  if command -v incus >/dev/null 2>&1; then
    if ! ip link show "$INCUS_BRIDGE" >/dev/null 2>&1; then
      echo "Incus bridge yeniden başlatılıyor..."
      incus network restart "$INCUS_BRIDGE"
    fi
  elif command -v lxc >/dev/null 2>&1; then
    if ! ip link show "$INCUS_BRIDGE" >/dev/null 2>&1; then
      echo "LXD bridge yeniden başlatılıyor..."
      lxc network restart "$INCUS_BRIDGE"
    fi
  fi
}

show_status() {
  echo -e "\n${BLUE}=== Network Durumu ===${NC}"

  echo -e "\n${YELLOW}Route Tablosu:${NC}"
  ip route

  echo -e "\n${YELLOW}Interface Durumları:${NC}"
  ip -br addr show

  echo -e "\n${YELLOW}DNS Ayarları:${NC}"
  if systemctl is-active --quiet systemd-resolved; then
    resolvectl status
  else
    cat /etc/resolv.conf
  fi
}

# Ana program
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Network Ayarları Sıfırlama Scripti   ${NC}"
echo -e "${BLUE}========================================${NC}"

# Kullanıcı onayı
echo -e "${RED}UYARI: Bu işlem tüm network ayarlarınızı sıfırlayacak.${NC}"
read -p "Devam etmek istiyor musunuz? (e/h): " confirm
if [ "$confirm" != "e" ]; then
  echo -e "${YELLOW}İşlem iptal edildi.${NC}"
  exit 0
fi

# Ana işlem sırası
get_network_info
backup_current_settings
cleanup_mullvad
cleanup_vpn
reset_network
check_incus_status
restart_networking
show_status

echo -e "\n${GREEN}Tüm network ayarları başarıyla sıfırlandı.${NC}"
echo -e "${YELLOW}Not: Herhangi bir sorun yaşarsanız, yedeklenen ayarlar: /tmp/network_backup_* dizininde bulunmaktadır.${NC}"
