#!/usr/bin/env bash

WOFI_DIR="$HOME/.config/wofi"
ZEN_DIR="$HOME/.zen"

generate_menu() {
  echo "🌐 Zen-Kenp"
  echo "🌐 Zen-CompecTA"
  echo "🌐 Zen-Discord"
  echo "🌐 Zen-NoVpn"
  echo "🌐 Zen-Whats"
  echo "🌐 Zen-Proxy"
  echo "🌐 Zen-Spotify"
  echo "🌐 Zen-ChatGPT"
}

configure_session_restore() {
  local profile_name="$1"
  local profile_dir="$ZEN_DIR/${profile_name}"
  local prefs_file="$profile_dir/prefs.js"

  # Prefs dosyası yoksa oluştur
  if [ ! -f "$prefs_file" ]; then
    touch "$prefs_file"
  fi

  # Oturum geri yükleme ayarlarını kontrol et ve ekle
  if ! grep -q "browser.startup.page" "$prefs_file"; then
    echo 'user_pref("browser.startup.page", 3);' >>"$prefs_file"
  fi
  if ! grep -q "browser.sessionstore.resume_session_once" "$prefs_file"; then
    echo 'user_pref("browser.sessionstore.resume_session_once", false);' >>"$prefs_file"
  fi
  if ! grep -q "browser.sessionstore.resume_from_crash" "$prefs_file"; then
    echo 'user_pref("browser.sessionstore.resume_from_crash", true);' >>"$prefs_file"
  fi
}

launch_browser() {
  local selected="$1"
  local profile_name="${selected#🌐 Zen-}" # Remove emoji and "Zen-" prefix

  # Oturum geri yükleme ayarlarını yapılandır
  configure_session_restore "$profile_name"

  # Tarayıcıyı başlat
  zen-browser -P "$profile_name" --restore-session &

  # Loga kaydet
  echo "[$(date)] Launched Zen Browser with profile: $profile_name" >>"$HOME/.zen/launcher.log"
}

# Wofi menüsünü göster ve seçimi al
selected=$(generate_menu | wofi -d -i -p "Select Zen Profile")

# Eğer bir seçim yapıldıysa tarayıcıyı başlat
if [ ! -z "$selected" ]; then
  launch_browser "$selected"
fi
