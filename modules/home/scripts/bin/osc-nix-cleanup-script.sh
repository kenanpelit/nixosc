#!/usr/bin/env bash
# osc-nix-cleanup-script.sh - Nix önbellek/derleme temizleyici
# nix-collect-garbage ve store temizliği yapar; disk alanını geri kazanır.

# Nix ve NixOS için gelişmiş kapsamlı temizlik öneri scripti
# Bu script, Nix store'u temizlemek için yapmanız gerekenleri size önerir

# Renkli çıktı için
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===========================================================${NC}"
echo -e "${BLUE}           NixOS Gelişmiş Temizlik Önerileri               ${NC}"
echo -e "${BLUE}===========================================================${NC}"

# Kullanıcıya önerileri göster
echo -e "\n${YELLOW}Aşağıdaki komutları sırasıyla çalıştırmanız önerilir:${NC}"

echo -e "\n${GREEN}[1]${NC} Temel temizlik için:"
echo -e "   • sudo nix-collect-garbage --delete-older-than 7d"
echo -e "   • sudo nix-store --gc"

echo -e "\n${GREEN}[2]${NC} Home-manager nesillerini temizlemek için:"
echo -e "   • LC_ALL=C home-manager expire-generations \"\$(LC_ALL=C date +%Y-%m-%d)\""

echo -e "\n${GREEN}[3]${NC} GC köklerini (roots) listelemek için:"
echo -e "   • nix-store --gc --print-roots | egrep -v \"^(/nix/var|/run/\\w+-system|\\{memory|/proc)\""

echo -e "\n${GREEN}[4]${NC} Güvenli olmayan GC köklerini kaldırmak için (dikkatli kullanın):"
echo -e "   • nix-store --gc --print-roots | egrep -v \"^(/nix/var|/run/\\w+-system|\\{memory|/proc)\" | awk '{ print \$1 }' | grep -vE 'home-manager|flake-registry\\.json' | xargs -L1 unlink"

echo -e "\n${GREEN}[5]${NC} Store'u optimize etmek için:"
echo -e "   • sudo nix-store --optimize"

echo -e "\n${GREEN}[6]${NC} Sistem yapılandırmasını yenilemek için:"
echo -e "   • sudo nixos-rebuild boot --delete-generations old"
echo -e "   • sudo nixos-rebuild switch"

echo -e "\n${GREEN}[7]${NC} Home-manager yapılandırmasını yenilemek için:"
echo -e "   • home-manager switch"

echo -e "\n${BLUE}===========================================================${NC}"

echo -e "\n${YELLOW}Notlar:${NC}"
echo -e "• Her komutu sırasıyla çalıştırmanız ve tamamlanmasını beklemeniz önerilir."
echo -e "• 4. adım güçlüdür ve bazı sembolik bağları kaldırır - dikkatli kullanın."
echo -e "• Bu temizlik işlemleri bittikten sonra, Hyprland yapılandırma hatalarınız çözülmüş olabilir."
echo -e "• Hyprland yapılandırmanızda windowrulev2 formatını kullanmayı unutmayın."
echo -e "• Temizlik işlemi tamamlandıktan sonra, oturumu yeniden başlatmak faydalı olabilir."

echo -e "\n${BLUE}===========================================================${NC}"
