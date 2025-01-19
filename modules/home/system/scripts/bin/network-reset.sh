#!/usr/bin/env bash

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

help() {
  echo -e "${YELLOW}Route Tablosu Sıfırlama Scripti${NC}"
  echo -e "Kullanım: sudo $0 [SEÇENEK]\n"
  echo "Bu script şu işlemleri yapar:"
  echo "  - Mevcut route tablosunu yedekler"
  echo "  - Route tablosunu temizler"
  echo "  - Varsayılan route'ları ekler:"
  echo "    * Gateway (192.168.0.1)"
  echo "    * Yerel ağ (192.168.0.0/24)"
  echo "    * LXD bridge (varsa)"
  echo "  - Network servislerini yeniden başlatır"
  echo -e "\nSeçenekler:"
  echo "  -h, --help     Bu yardım mesajını gösterir"
  echo "  -y, --yes      Onay istemeden çalışır"
  echo -e "\nÖrnek:"
  echo "  sudo $0        Normal çalıştırma"
  echo "  sudo $0 -y     Onaysız çalıştırma"
  exit 0
}

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Bu script root yetkisi gerektirir.${NC}"
  echo "Lütfen 'sudo' ile çalıştırın."
  exit 1
fi

# Fonksiyonlar
backup_current_routes() {
  echo -e "${YELLOW}Mevcut route tablosu yedekleniyor...${NC}"
  ip route show >/tmp/route_backup_$(date +%Y%m%d_%H%M%S).txt
  echo -e "${GREEN}Yedekleme tamamlandı: /tmp/route_backup_$(date +%Y%m%d_%H%M%S).txt${NC}"
}

reset_routes() {
  echo -e "${YELLOW}Route tablosu sıfırlanıyor...${NC}"

  # Tüm route'ları temizle
  echo -e "Tüm route'lar siliniyor..."
  ip route flush table main

  # Varsayılan route'u yeniden ekle
  echo -e "Varsayılan route ekleniyor..."
  ip route add default via 192.168.0.1 dev wlp2s0 proto dhcp src 192.168.0.32 metric 600

  # Yerel ağ route'unu ekle
  echo -e "Yerel ağ route'u ekleniyor..."
  ip route add 192.168.0.0/24 dev wlp2s0 proto kernel scope link src 192.168.0.32 metric 600

  # LXD bridge route'unu ekle (eğer varsa)
  if ip link show lxdbr0 >/dev/null 2>&1; then
    echo -e "LXD bridge route'u ekleniyor..."
    ip route add 10.226.202.0/24 dev lxdbr0 proto kernel scope link src 10.226.202.1
  fi
}

restart_networking() {
  echo -e "${YELLOW}Network servisleri yeniden başlatılıyor...${NC}"

  # NetworkManager'ı yeniden başlat
  systemctl restart NetworkManager

  # DNS önbelleğini temizle
  systemd-resolve --flush-caches

  echo -e "${GREEN}Network servisleri yeniden başlatıldı.${NC}"
}

show_final_status() {
  echo -e "\n${YELLOW}Güncel route tablosu:${NC}"
  ip route

  echo -e "\n${YELLOW}Network interface durumları:${NC}"
  ip addr show

  echo -e "\n${YELLOW}DNS durumu:${NC}"
  systemd-resolve --status
}

# Ana program
echo -e "${YELLOW}Network Ayarları Sıfırlama Scripti${NC}"
echo "--------------------------------"

# Kullanıcı onayı
echo -e "${RED}UYARI: Bu işlem tüm network ayarlarınızı sıfırlayacak.${NC}"
read -p "Devam etmek istiyor musunuz? (e/h): " confirm
if [ "$confirm" != "e" ]; then
  echo -e "${YELLOW}İşlem iptal edildi.${NC}"
  exit 0
fi

# İşlemleri gerçekleştir
backup_current_routes
reset_routes
restart_networking
show_final_status

echo -e "\n${GREEN}Tüm network ayarları başarıyla sıfırlandı.${NC}"
echo -e "${YELLOW}Not: Eğer VPN bağlantınız hala aktifse, VPN servisini manuel olarak kapatmanız gerekebilir.${NC}"
