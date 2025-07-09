#!/usr/bin/env bash

#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################

#########################################################################
# Gammastep Manager
#
# Bu script, Gammastep mavi ışık filtresini yönetmek için kullanılır.
# Gündüz ve gece modları için farklı renk sıcaklıkları ve parlaklık
# seviyeleri ayarlanabilir. Waybar entegrasyonu ile birlikte çalışır.
#
# Özellikler:
#   - Gammastep'i başlatma/durdurma/durum kontrolü
#   - Özelleştirilebilir renk sıcaklığı ve parlaklık ayarları
#   - Waybar entegrasyonu
#   - Sistem bildirimleri
#   - Konum tabanlı çalışma
#
# Gereksinimler:
#   - gammastep
#   - libnotify (notify-send için)
#   - waybar (opsiyonel)
#
#########################################################################

# Varsayılan ayarlar
MODE="wayland"             # Çalışma modu
LOCATION="41.0108:29.0219" # Enlem:Boylam (manuel olarak ayarlanmış)
TEMP_DAY=5000              # Gündüz renk sıcaklığı
TEMP_NIGHT=4500            # Gece renk sıcaklığı
BRIGHTNESS_DAY=0.9         # Gündüz parlaklık
BRIGHTNESS_NIGHT=0.8       # Gece parlaklık
GAMMA="1,0.2,0.1"          # RGB gamma ayarları

# Kullanım bilgisi
usage() {
  cat <<EOF
Gammastep Manager - Mavi Işık Filtresi Yönetim Aracı

KULLANIM:
    $(basename "$0") [KOMUT] [PARAMETRELER]

KOMUTLAR:
    start         Gammastep'i başlat
    stop          Gammastep'i durdur
    toggle        Gammastep'i aç/kapat
    status        Gammastep durumunu göster
    -h, --help    Bu yardım mesajını göster

PARAMETRELER:
    --temp-day VALUE      Gündüz renk sıcaklığı (Kelvin)
                         (varsayılan: $TEMP_DAY)
    --temp-night VALUE    Gece renk sıcaklığı (Kelvin)
                         (varsayılan: $TEMP_NIGHT)
    --bright-day VALUE    Gündüz parlaklığı (0.1-1.0)
                         (varsayılan: $BRIGHTNESS_DAY)
    --bright-night VALUE  Gece parlaklığı (0.1-1.0)
                         (varsayılan: $BRIGHTNESS_NIGHT)
    --location VALUE      Konum (format: enlem:boylam)
                         (varsayılan: $LOCATION)
    --gamma VALUE         Gamma değeri (format: r,g,b)
                         (varsayılan: $GAMMA)

ÖRNEKLER:
    # Varsayılan ayarlarla başlatma
    $(basename "$0") start

    # Özel gündüz/gece sıcaklıklarıyla başlatma
    $(basename "$0") start --temp-day 5000 --temp-night 3500

    # Özel konum ve parlaklık ayarlarıyla başlatma
    $(basename "$0") start --location 41.0:29.0 --bright-day 0.9

    # Durumu kontrol etme
    $(basename "$0") status

NOT:
    Renk sıcaklığı değerleri Kelvin cinsindendir.
    Düşük değerler (örn. 3000K) daha sıcak/kırmızımsı,
    yüksek değerler (örn. 6500K) daha soğuk/manvimsi renk verir.

EOF
}

# Gammastep durumunu kontrol et
check_status() {
  if pgrep gammastep &>/dev/null; then
    echo '{"class": "activated", "tooltip": "Gammastep is active"}'
    return 0
  else
    echo '{"class": "", "tooltip": "Gammastep is deactivated"}'
    return 1
  fi
}

# Gammastep'i başlat
start_gammastep() {
  if ! check_status &>/dev/null; then
    /usr/bin/gammastep -m "$MODE" \
      -l manual \
      -t "$TEMP_DAY:$TEMP_NIGHT" \
      -b "$BRIGHTNESS_DAY:$BRIGHTNESS_NIGHT" \
      -l "$LOCATION" \
      -g "$GAMMA" \
      >>/dev/null 2>&1 &

    disown
    notify-send -u low "Gammastep Başlatıldı" "Gündüz: $TEMP_DAY K, Gece: $TEMP_NIGHT K"
    return 0
  else
    echo "Gammastep zaten çalışıyor."
    return 1
  fi
}

# Gammastep'i durdur
stop_gammastep() {
  if check_status &>/dev/null; then
    pkill --signal SIGKILL gammastep
    notify-send -u low "Gammastep Durduruldu" "Gammastep uygulaması kapatıldı."
    return 0
  else
    echo "Gammastep zaten çalışmıyor."
    return 1
  fi
}

# Waybar'ı güncelle (eğer varsa)
update_waybar() {
  if command -v waybar &>/dev/null; then
    pkill -RTMIN+8 waybar
  fi
}

# Parametreleri işle
while [[ $# -gt 0 ]]; do
  case $1 in
  --temp-day)
    TEMP_DAY="$2"
    shift 2
    ;;
  --temp-night)
    TEMP_NIGHT="$2"
    shift 2
    ;;
  --bright-day)
    BRIGHTNESS_DAY="$2"
    shift 2
    ;;
  --bright-night)
    BRIGHTNESS_NIGHT="$2"
    shift 2
    ;;
  --location)
    LOCATION="$2"
    shift 2
    ;;
  --gamma)
    GAMMA="$2"
    shift 2
    ;;
  start)
    start_gammastep
    update_waybar
    exit $?
    ;;
  stop)
    stop_gammastep
    update_waybar
    exit $?
    ;;
  toggle)
    if check_status &>/dev/null; then
      stop_gammastep
    else
      start_gammastep
    fi
    update_waybar
    exit $?
    ;;
  status)
    check_status
    exit $?
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Geçersiz parametre: $1"
    usage
    exit 1
    ;;
  esac
done

# Eğer hiç parametre verilmemişse kullanım bilgisini göster
if [ $# -eq 0 ]; then
  usage
  exit 1
fi
