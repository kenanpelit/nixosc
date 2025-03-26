#!/usr/bin/env bash

# Nix ve NixOS için kapsamlı temizlik öneri scripti
# Bu script, Nix store'u temizlemek için yapmanız gerekenleri size önerir

# Renkli çıktı için
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===========================================================${NC}"
echo -e "${BLUE}           NixOS Kapsamlı Temizlik Önerileri               ${NC}"
echo -e "${BLUE}===========================================================${NC}"

# Kullanıcıya önerileri göster
echo -e "\n${YELLOW}Aşağıdaki komutları sırasıyla çalıştırmanız önerilir:${NC}"

echo -e "\n${GREEN}[1]${NC} Tüm eski nesilleri temizlemek için:"
echo -e "   • sudo nix-collect-garbage --delete-older-than 0d"

echo -e "\n${GREEN}[2]${NC} Tüm kullanıcı profillerini temizlemek için:"
echo -e "   • sudo find /nix/var/nix/profiles/per-user -type l -name '*-link' | xargs -r rm -f"

echo -e "\n${GREEN}[3]${NC} Sistem nesillerini temizlemek için:"
echo -e "   • sudo nixos-rebuild boot --delete-generations old"

echo -e "\n${GREEN}[4]${NC} Gereksiz paketleri temizlemek için:"
echo -e "   • sudo nix-store --gc"

echo -e "\n${GREEN}[5]${NC} Nix store'u optimize etmek için:"
echo -e "   • sudo nix-store --optimize"

echo -e "\n${GREEN}[6]${NC} Sistemi yeniden derlemek için:"
echo -e "   • sudo nixos-rebuild switch"

echo -e "\n${BLUE}===========================================================${NC}"

echo -e "\n${YELLOW}Notlar:${NC}"
echo -e "• Her komutu sırasıyla çalıştırmanız ve tamamlanmasını beklemeniz önerilir."
echo -e "• Bu temizlik işlemleri bittikten sonra, Hyprland yapılandırma hatalarınız çözülmüş olabilir."
echo -e "• Hyprland yapılandırmanızda windowrulev2 formatını kullanmayı unutmayın."
echo -e "• Temizlik işlemi tamamlandıktan sonra, oturumu yeniden başlatmak faydalı olabilir."

echo -e "\n${BLUE}===========================================================${NC}"
