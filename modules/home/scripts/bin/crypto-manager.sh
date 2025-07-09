#!/usr/bin/env bash

# =============================================================================
# SSH ve GnuPG Yönetim Scripti
# =============================================================================
#
# Bu script aşağıdaki işlemleri gerçekleştirir:
# 1. SSH ve GnuPG dizinlerindeki izinleri düzeltir
# 2. İsteğe bağlı olarak yedekleme yapar
# 3. GPG servislerini yönetir
#
# =============================================================================

# Renklendirme için ANSI kodları
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Varsayılan değerler
BACKUP_ENABLED=false
FIX_PERMISSIONS=false
RESTART_GPG=false
LIST_BACKUPS=false
DEFAULT_BACKUP_DIR="$HOME/.backups/crypto"
BACKUP_DIR="$DEFAULT_BACKUP_DIR"
BACKUP_COUNT=5

# Yardım mesajını göster
show_help() {
  cat <<EOF
Kullanım: $(basename $0) [SEÇENEKLER]

SSH ve GnuPG yapılandırmalarını yönetmek için kullanılan araç.

Seçenekler:
    -h, --help              Bu yardım mesajını gösterir
    -p, --fix-permissions   SSH ve GnuPG için izinleri düzeltir
    -b, --backup [DIR]      Yedekleme yapar. Opsiyonel olarak hedef dizin belirtilebilir
    -r, --restart-gpg       GPG servislerini yeniden başlatır
    -l, --list-backups      Mevcut yedekleri listeler
    -n, --backup-count N    Listelenecek yedek sayısı (varsayılan: 5)
    
Örnekler:
    $(basename $0) -p                    # Sadece izinleri düzeltir
    $(basename $0) -b                    # Varsayılan konuma yedek alır
    $(basename $0) -b /yedek/dizin       # Belirtilen konuma yedek alır
    $(basename $0) -p -b -r              # İzinleri düzeltir, yedek alır ve GPG'yi yeniden başlatır
    $(basename $0) -l -n 10              # Son 10 yedeği listeler
EOF
}

# Parametreleri işle
while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    show_help
    exit 0
    ;;
  -p | --fix-permissions)
    FIX_PERMISSIONS=true
    shift
    ;;
  -b | --backup)
    BACKUP_ENABLED=true
    if [ ! -z "$2" ] && [[ $2 != -* ]]; then
      BACKUP_DIR="$2"
      shift
    fi
    shift
    ;;
  -r | --restart-gpg)
    RESTART_GPG=true
    shift
    ;;
  -l | --list-backups)
    LIST_BACKUPS=true
    shift
    ;;
  -n | --backup-count)
    if [ ! -z "$2" ] && [[ $2 =~ ^[0-9]+$ ]]; then
      BACKUP_COUNT="$2"
      shift
    else
      echo -e "${RED}Hata: --backup-count için geçerli bir sayı belirtilmedi${NC}"
      exit 1
    fi
    shift
    ;;
  *)
    echo -e "${RED}Geçersiz parametre: $1${NC}"
    show_help
    exit 1
    ;;
  esac
done

# Hiç parametre verilmediyse yardım göster
if [ "$BACKUP_ENABLED" = false ] && [ "$FIX_PERMISSIONS" = false ] && [ "$RESTART_GPG" = false ] && [ "$LIST_BACKUPS" = false ]; then
  show_help
  exit 0
fi

# =============================================================================
# İzin Düzeltme Fonksiyonları
# =============================================================================

fix_ssh_permissions() {
  echo -e "${YELLOW}=== SSH İzinleri Kontrol Ediliyor ===${NC}"

  # SSH dizini izinleri
  if [ -d ~/.ssh ]; then
    if [ $(stat -c %a ~/.ssh) -ne 700 ]; then
      echo -e "${RED}~/.ssh dizin izinleri yanlış. Düzeltiliyor...${NC}"
      chmod 700 ~/.ssh
      echo -e "${GREEN}~/.ssh dizin izinleri düzeltildi (700)${NC}"
    else
      echo -e "${GREEN}~/.ssh dizin izinleri doğru (700)${NC}"
    fi

    # Özel anahtar izinleri (600)
    private_keys=("id_rsa" "id_ecdsa" "id_ed25519")
    for key in "${private_keys[@]}"; do
      if [ -f ~/.ssh/$key ]; then
        current_perm=$(stat -c %a ~/.ssh/$key)
        if [ "$current_perm" -ne 600 ]; then
          echo -e "${RED}~/.ssh/$key izinleri yanlış ($current_perm). Düzeltiliyor...${NC}"
          chmod 600 ~/.ssh/$key
          echo -e "${GREEN}~/.ssh/$key izinleri düzeltildi (600)${NC}"
        else
          echo -e "${GREEN}~/.ssh/$key izinleri doğru (600)${NC}"
        fi
      fi
    done

    # Genel anahtar izinleri (644)
    public_keys=("id_rsa.pub" "id_ecdsa.pub" "id_ed25519.pub")
    for key in "${public_keys[@]}"; do
      if [ -f ~/.ssh/$key ]; then
        current_perm=$(stat -c %a ~/.ssh/$key)
        if [ "$current_perm" -ne 644 ]; then
          echo -e "${RED}~/.ssh/$key izinleri yanlış ($current_perm). Düzeltiliyor...${NC}"
          chmod 644 ~/.ssh/$key
          echo -e "${GREEN}~/.ssh/$key izinleri düzeltildi (644)${NC}"
        else
          echo -e "${GREEN}~/.ssh/$key izinleri doğru (644)${NC}"
        fi
      fi
    done

    # Diğer önemli dosyaların izinleri (600)
    important_files=("authorized_keys" "known_hosts" "config")
    for file in "${important_files[@]}"; do
      if [ -f ~/.ssh/$file ]; then
        current_perm=$(stat -c %a ~/.ssh/$file)
        if [ "$current_perm" -ne 600 ]; then
          echo -e "${RED}~/.ssh/$file izinleri yanlış ($current_perm). Düzeltiliyor...${NC}"
          chmod 600 ~/.ssh/$file
          echo -e "${GREEN}~/.ssh/$file izinleri düzeltildi (600)${NC}"
        else
          echo -e "${GREEN}~/.ssh/$file izinleri doğru (600)${NC}"
        fi
      fi
    done
  else
    echo -e "${YELLOW}SSH dizini bulunamadı.${NC}"
  fi
}

fix_gpg_permissions() {
  echo -e "\n${YELLOW}=== GnuPG İzinleri Kontrol Ediliyor ===${NC}"

  if [ -d ~/.gnupg ]; then
    # Ana dizin izinleri
    if [ $(stat -c %a ~/.gnupg) -ne 700 ]; then
      echo -e "${RED}~/.gnupg dizin izinleri yanlış. Düzeltiliyor...${NC}"
      chmod 700 ~/.gnupg
      echo -e "${GREEN}~/.gnupg dizin izinleri düzeltildi (700)${NC}"
    else
      echo -e "${GREEN}~/.gnupg dizin izinleri doğru (700)${NC}"
    fi

    # Alt dizinler kontrolü
    gpg_subdirs=("private-keys-v1.d" "public-keys.d" "crls.d")
    for dir in "${gpg_subdirs[@]}"; do
      if [ -d ~/.gnupg/$dir ]; then
        current_perm=$(stat -c %a ~/.gnupg/$dir)
        if [ "$current_perm" -ne 700 ]; then
          echo -e "${RED}~/.gnupg/$dir dizin izinleri yanlış ($current_perm). Düzeltiliyor...${NC}"
          chmod 700 ~/.gnupg/$dir
          echo -e "${GREEN}~/.gnupg/$dir dizin izinleri düzeltildi (700)${NC}"
        else
          echo -e "${GREEN}~/.gnupg/$dir dizin izinleri doğru (700)${NC}"
        fi
      fi
    done

    # Dosya izinleri
    echo -e "${BLUE}GnuPG dosya izinleri kontrol ediliyor...${NC}"
    find ~/.gnupg -type f -exec bash -c '
            file="$1"
            current_perm=$(stat -c %a "$file")
            if [ "$current_perm" -ne 600 ]; then
                echo -e "${RED}$file izinleri yanlış ($current_perm). Düzeltiliyor...${NC}"
                chmod 600 "$file"
                echo -e "${GREEN}$file izinleri düzeltildi (600)${NC}"
            else
                echo -e "${GREEN}$file izinleri doğru (600)${NC}"
            fi
        ' bash {} \;
  else
    echo -e "${YELLOW}GnuPG dizini bulunamadı.${NC}"
  fi
}

restart_gpg_services() {
  echo -e "\n${YELLOW}=== GPG Servisleri Yeniden Başlatılıyor ===${NC}"

  # GPG servislerini durdur
  echo -e "${YELLOW}GPG servisleri durduruluyor...${NC}"
  gpgconf --kill all
  sleep 2

  # Soket dosyalarını temizle
  echo -e "${YELLOW}Soket dosyaları temizleniyor...${NC}"
  rm -f ~/.gnupg/S.gpg-agent*
  rm -f ~/.gnupg/S.scdaemon

  # GPG'yi yeniden başlat
  if pgrep -x "gpg-agent" >/dev/null; then
    echo -e "${YELLOW}GPG agent zaten çalışıyor. Yeniden başlatılıyor...${NC}"
    gpgconf --reload gpg-agent
    echo -e "${GREEN}GPG agent yeniden yüklendi${NC}"
  else
    if gpg-agent --daemon; then
      echo -e "${GREEN}GPG agent başarıyla başlatıldı${NC}"
    else
      echo -e "${RED}GPG agent başlatılamadı!${NC}"
    fi
  fi
}

backup_crypto() {
  echo -e "\n${YELLOW}=== Yedekleme İşlemi Başlatılıyor ===${NC}"

  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  SSH_BACKUP="ssh_backup_${TIMESTAMP}.tar.gz"
  GPG_BACKUP="gpg_backup_${TIMESTAMP}.tar.gz"

  # Dizin kontrolü ve oluşturma
  if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Yedekleme dizini oluşturuluyor: $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"
  fi

  # SSH yedekleme
  if [ -d "$HOME/.ssh" ]; then
    echo -e "${BLUE}SSH yapılandırması yedekleniyor...${NC}"
    tar -czf "$BACKUP_DIR/$SSH_BACKUP" -C "$HOME" .ssh 2>/dev/null
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}SSH yedekleme başarılı: $BACKUP_DIR/$SSH_BACKUP${NC}"
    else
      echo -e "${RED}SSH yedekleme başarısız!${NC}"
    fi
  fi

  # GnuPG yedekleme
  if [ -d "$HOME/.gnupg" ]; then
    echo -e "${BLUE}GnuPG yapılandırması yedekleniyor...${NC}"
    tar -czf "$BACKUP_DIR/$GPG_BACKUP" -C "$HOME" .gnupg 2>/dev/null
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}GnuPG yedekleme başarılı: $BACKUP_DIR/$GPG_BACKUP${NC}"
    else
      echo -e "${RED}GnuPG yedekleme başarısız!${NC}"
    fi
  fi

  # Yedeklerin izinlerini güvenli hale getirme
  chmod 600 "$BACKUP_DIR"/*.tar.gz 2>/dev/null

  # Özet bilgi
  echo -e "\n${GREEN}Yedekleme tamamlandı${NC}"
  echo -e "${BLUE}Yedekleme konumu: $BACKUP_DIR${NC}"
  echo -e "${BLUE}Yedek dosyaları:${NC}"
  ls -lh "$BACKUP_DIR"/*_${TIMESTAMP}.tar.gz 2>/dev/null
}

list_backups() {
  echo -e "\n${YELLOW}=== Mevcut Yedekler ===${NC}"
  if [ -d "$BACKUP_DIR" ]; then
    echo -e "${BLUE}Son $BACKUP_COUNT yedek:${NC}"
    ls -lh "$BACKUP_DIR" | grep -E "ssh_backup|gpg_backup" | sort -r | head -n "$BACKUP_COUNT"
  else
    echo -e "${YELLOW}Yedek dizini bulunamadı: $BACKUP_DIR${NC}"
  fi
}

# =============================================================================
# Ana Program
# =============================================================================

echo -e "${YELLOW}=== SSH ve GnuPG Yönetim Scripti ===${NC}"
echo "----------------------------------------"

# İzinleri düzelt
if [ "$FIX_PERMISSIONS" = true ]; then
  fix_ssh_permissions
  fix_gpg_permissions
fi

# GPG servislerini yeniden başlat
if [ "$RESTART_GPG" = true ]; then
  restart_gpg_services
fi

# Yedekleme işlemi
if [ "$BACKUP_ENABLED" = true ]; then
  backup_crypto
fi

# Yedekleri listele
if [ "$LIST_BACKUPS" = true ]; then
  list_backups
fi

echo -e "\n${GREEN}Tüm işlemler tamamlandı.${NC}"
