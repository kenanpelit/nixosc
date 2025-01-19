#!/usr/bin/env bash

# Fonksiyon: Kullanım bilgisini göster
show_usage() {
  echo "Kullanım: $0 [backup|restore]"
  echo "  backup  : ~/.config/oh-my-tmux ve ~/.config/tmux dizinlerini yedekler"
  echo "  restore : Yedeklenen dizinleri geri yükler"
  exit 1
}

# Parametre kontrolü
if [ $# -ne 1 ]; then
  show_usage
fi

# Yedek dosyasının adı ve yolu
BACKUP_FILE="tmux_backup.tar.gz"
OH_MY_TMUX_DIR="$HOME/.config/oh-my-tmux"
TMUX_DIR="$HOME/.config/tmux"

backup() {
  echo "Yedekleme işlemi başlıyor..."

  # Dizinlerin varlığını kontrol et
  if [ ! -d "$OH_MY_TMUX_DIR" ] || [ ! -d "$TMUX_DIR" ]; then
    echo "Hata: Yedeklenecek dizinlerden biri veya her ikisi mevcut değil!"
    echo "Kontrol edilen dizinler:"
    echo "- $OH_MY_TMUX_DIR"
    echo "- $TMUX_DIR"
    exit 1
  fi

  # Yedekleme işlemini gerçekleştir
  tar -czf "$BACKUP_FILE" -C "$HOME/.config" oh-my-tmux tmux

  if [ $? -eq 0 ]; then
    echo "Yedekleme başarılı!"
    echo "Yedek dosyası: $BACKUP_FILE"
  else
    echo "Yedekleme sırasında bir hata oluştu!"
    exit 1
  fi
}

restore() {
  echo "Geri yükleme işlemi başlıyor..."

  # Yedek dosyasının varlığını kontrol et
  if [ ! -f "$BACKUP_FILE" ]; then
    echo "Hata: $BACKUP_FILE bulunamadı!"
    exit 1
  fi

  # Hedef dizinleri kontrol et ve varsa yedekle
  if [ -d "$OH_MY_TMUX_DIR" ]; then
    mv "$OH_MY_TMUX_DIR" "${OH_MY_TMUX_DIR}.old"
    echo "Mevcut oh-my-tmux dizini yedeklendi: ${OH_MY_TMUX_DIR}.old"
  fi

  if [ -d "$TMUX_DIR" ]; then
    mv "$TMUX_DIR" "${TMUX_DIR}.old"
    echo "Mevcut tmux dizini yedeklendi: ${TMUX_DIR}.old"
  fi

  # Geri yükleme işlemini gerçekleştir
  tar -xzf "$BACKUP_FILE" -C "$HOME/.config"

  if [ $? -eq 0 ]; then
    echo "Geri yükleme başarılı!"
    # Eski yedekleri temizleme seçeneği sun
    read -p "Eski yedek dizinleri silinsin mi? (e/h): " answer
    if [ "$answer" = "e" ]; then
      rm -rf "${OH_MY_TMUX_DIR}.old" "${TMUX_DIR}.old"
      echo "Eski yedekler temizlendi."
    fi
  else
    echo "Geri yükleme sırasında bir hata oluştu!"
    # Hata durumunda eski dizinleri geri getir
    if [ -d "${OH_MY_TMUX_DIR}.old" ]; then
      mv "${OH_MY_TMUX_DIR}.old" "$OH_MY_TMUX_DIR"
    fi
    if [ -d "${TMUX_DIR}.old" ]; then
      mv "${TMUX_DIR}.old" "$TMUX_DIR"
    fi
    exit 1
  fi
}

# Ana işlem kontrolü
case "$1" in
"backup")
  backup
  ;;
"restore")
  restore
  ;;
*)
  show_usage
  ;;
esac
