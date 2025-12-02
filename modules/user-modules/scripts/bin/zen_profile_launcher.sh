#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: ZenBrowserLauncher - Zen Browser Profil Yöneticisi
#
# Bu script Zen Browser'ı farklı profillerle başlatmak için tasarlanmış
# bir profil yöneticisidir. Temel özellikleri:
#
# - Önceden tanımlı profil listesi
# - İki çalıştırma modu:
#   - Doğrudan profil başlatma (parametre ile)
#   - İnteraktif profil seçimi (menü ile)
# - Wayland optimizasyonu
# - Crash reporter devre dışı bırakma
# - Bildirim sistemi entegrasyonu
#
# Profiller:
# - CompecTA: İş ortamı
# - Discord: Discord web
# - Kenp: Kişisel profil
# - NoVpn: VPN bypass
# - Proxy: Proxy ayarlı
# - Spotify: Müzik
# - Whats: WhatsApp web
#
# Kullanım:
# ./zen-browser-launcher [profil_adı]
#
# License: MIT
#
#######################################
# Profil listesi
profiles=("CompecTA" "Discord" "Kenp" "NoVpn" "Proxy" "Spotify" "Whats")

# Parametre olarak profil adı girilmişse kontrol et
if [[ -n "$1" ]]; then
  profile="$1"

  # Girilen profilin geçerli olup olmadığını kontrol et
  if [[ " ${profiles[@]} " =~ " ${profile} " ]]; then
    echo "$profile profili başlatılıyor..."
    GDK_BACKEND=wayland MOZ_CRASHREPORTER_DISABLE=1 zen -P "$profile" >>/dev/null 2>&1 &
    disown
    notify-send -t 5000 "Zen Browser" "$profile profili başlatıldı."
    exit 0
  else
    echo "Geçersiz profil adı: $profile"
    echo "Geçerli profiller: ${profiles[*]}"
    exit 1
  fi
fi

# Parametre girilmemişse seçim menüsü sun
echo "Zen Browser Profilleri:"
for i in "${!profiles[@]}"; do
  echo "$((i + 1))) ${profiles[$i]}"
done
echo "0) Çıkış"

# Kullanıcıdan seçim al
read -p "Bir profil seçin (1-${#profiles[@]} veya 0): " choice

# Seçim kontrolü
if [[ "$choice" -eq 0 ]]; then
  echo "Çıkış yapılıyor..."
  exit 0
elif [[ "$choice" -ge 1 && "$choice" -le ${#profiles[@]} ]]; then
  profile="${profiles[$((choice - 1))]}"
  echo "$profile profili başlatılıyor..."

  # Zen Browser'ı seçilen profille başlat
  GDK_BACKEND=wayland MOZ_CRASHREPORTER_DISABLE=1 zen -P "$profile" >>/dev/null 2>&1 &
  disown
  notify-send -t 5000 "Zen Browser" "$profile profili başlatıldı."
else
  echo "Geçersiz seçim! Lütfen 0 ile ${#profiles[@]} arasında bir seçim yapın."
fi
