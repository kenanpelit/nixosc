#!/usr/bin/env bash
# osc-test.sh - Hızlı test/deneme kancası
# Küçük komut/prototip denemeleri için şablon; log ve çıktıları gözlemlemek için.

#===============================================================================
#
#   Script: OSC Test Manager
#   Version: 2.0.0
#   Date: 2025-04-09
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: NixOS konfigürasyonları için test aracı. Belirtilen modülleri
#                test eder ve hızlı geliştirme için kullanılabilir.
#
#   Özellikler:
#   - Modül kategorilerini ve altındaki bileşenleri listeleme
#   - nixos-rebuild test komutu ile hızlı test etme
#   - Belirtilen flake ile özelleştirilebilir test
#   - Renkli ve açıklayıcı çıktılar
#   - Basit kullanıcı arayüzü
#
#   Kullanım:
#     ./test-nixos.sh home               # Tüm kategorileri listeler
#     ./test-nixos.sh desktop            # Kategori altındaki modülleri listeler
#     ./test-nixos.sh home desktop       # Belirtilen kategorideki modülleri listeler
#     ./test-nixos.sh home desktop rofi  # Belirtilen modülü test eder (varsayılan flake: hay)
#     ./test-nixos.sh home desktop rofi kenan # Belirtilen modülü özel flake ile test eder
#
#   Lisans: MIT
#
#===============================================================================

# Renk tanımlamaları
RED='\033[0;31m'    # Hata mesajları için
GREEN='\033[0;32m'  # Başarı mesajları için
YELLOW='\033[1;33m' # Uyarı ve dikkat çekmek için
BLUE='\033[0;34m'   # Bilgi başlıkları için
CYAN='\033[0;36m'   # Alt bilgiler ve detaylar için
BOLD='\033[1m'      # Kalın yazı
NC='\033[0m'        # Renk sıfırlama

# Ana dizinler
NIXOS_DIR="$HOME/.nixosc"
MODULES_DIR="$NIXOS_DIR/modules"

# Banner göster
show_banner() {
	echo -e "${BOLD}${BLUE}"
	echo "╔══════════════════════════════════════════════╗"
	echo "║               OSC Test Manager               ║"
	echo "╚══════════════════════════════════════════════╝${NC}"
	echo
}

# Kategorileri listele
list_categories() {
	echo -e "${BLUE}Mevcut kategoriler:${NC}"
	local categories=()

	# Kategorileri diziye ekle
	for dir in "$MODULES_DIR/home"/*; do
		if [[ -d "$dir" ]]; then
			categories+=("$(basename "$dir")")
		fi
	done

	# Kategorileri alfabetik sırala ve göster
	IFS=$'\n' sorted=($(sort <<<"${categories[*]}"))
	unset IFS

	for category in "${sorted[@]}"; do
		echo -e "  ${CYAN}→${NC} $category"
	done

	echo -e "\n${YELLOW}Kullanım:${NC} $(basename "$0") home <kategori> [<modül> [<flake>]]"
}

# Modülleri listele
list_modules() {
	local category=$1

	if [[ -d "$MODULES_DIR/home/$category" ]]; then
		echo -e "${BLUE}\"$category\" kategorisindeki modüller:${NC}"
		local modules=()

		# Modülleri diziye ekle
		for module in "$MODULES_DIR/home/$category"/*; do
			if [[ -d "$module" ]]; then
				modules+=("$(basename "$module")")
			fi
		done

		# Modülleri alfabetik sırala ve göster
		IFS=$'\n' sorted=($(sort <<<"${modules[*]}"))
		unset IFS

		for module in "${sorted[@]}"; do
			echo -e "  ${CYAN}→${NC} $module"
		done

		echo -e "\n${YELLOW}Test etmek için:${NC} $(basename "$0") home $category <modül> [<flake>]"
	else
		echo -e "${RED}Hata: '$category' kategorisi bulunamadı!${NC}"
		list_categories
		exit 1
	fi
}

# Kullanım fonksiyonu
show_usage() {
	show_banner
	echo -e "${BOLD}KULLANIM:${NC}"
	echo -e "  $(basename "$0") <scope> <kategori> <modül> [flake]"
	echo
	echo -e "${BOLD}ÖRNEKLER:${NC}"
	echo -e "  $(basename "$0") home               ${CYAN}# Tüm kategorileri listeler${NC}"
	echo -e "  $(basename "$0") desktop            ${CYAN}# Kategori altındaki modülleri listeler${NC}"
	echo -e "  $(basename "$0") home desktop       ${CYAN}# Belirtilen kategorideki modülleri listeler${NC}"
	echo -e "  $(basename "$0") home desktop rofi  ${CYAN}# Belirtilen modülü test eder (varsayılan flake: hay)${NC}"
	echo -e "  $(basename "$0") home desktop rofi kenan ${CYAN}# Belirtilen modülü özel flake ile test eder${NC}"
	echo
	list_categories
}

# Modülü test et
test_module() {
	local scope=$1
	local category=$2
	local module=$3
	local flake=${4:-hay}

	# Konfigürasyon dosyası yolu
	local config_dir="$MODULES_DIR/$scope/$category/$module/default.nix"

	# Dosya kontrolü
	if [[ ! -f $config_dir ]]; then
		echo -e "${RED}Hata: '$config_dir' yapılandırma dosyası bulunamadı!${NC}"
		list_modules "$category"
		exit 1
	fi

	# Çalışma dizinine git
	if ! cd "$NIXOS_DIR"; then
		echo -e "${RED}Hata: '$NIXOS_DIR' dizinine geçilemedi!${NC}"
		exit 1
	fi

	echo -e "${BLUE}${BOLD}TEST EDİLİYOR${NC}: $scope/$category/${BOLD}$module${NC} (flake: ${CYAN}$flake${NC})"
	echo -e "${YELLOW}Konfigürasyon${NC}: $config_dir"
	echo -e "${YELLOW}Komut${NC}: sudo nixos-rebuild test --flake .#$flake -I nixos-config=$config_dir"
	echo

	# Kullanıcıdan onay al
	read -p "Devam etmek istiyor musunuz? (E/h): " confirm
	if [[ "$confirm" == "h" || "$confirm" == "H" ]]; then
		echo -e "${YELLOW}İşlem iptal edildi.${NC}"
		exit 0
	fi

	echo
	echo -e "${BLUE}${BOLD}Test başlatılıyor...${NC}"
	echo "--------------------------------------------------------------------------------"

	# Yapılandırmayı test et
	if sudo nixos-rebuild test --flake .#"$flake" -I nixos-config="$config_dir"; then
		echo "--------------------------------------------------------------------------------"
		echo -e "${GREEN}${BOLD}TEST BAŞARILI!${NC} $scope/$category/$module konfigürasyonu başarıyla uygulandı."
	else
		echo "--------------------------------------------------------------------------------"
		echo -e "${RED}${BOLD}TEST BAŞARISIZ!${NC} Lütfen hataları kontrol edin."
		exit 1
	fi
}

# Ana fonksiyon
main() {
	case $# in
	0)
		show_usage
		;;
	1)
		show_banner
		if [[ "$1" == "home" ]]; then
			list_categories
		else
			list_modules "$1"
		fi
		;;
	2)
		show_banner
		if [[ "$1" == "home" ]]; then
			list_modules "$2"
		else
			show_usage
		fi
		;;
	3 | 4)
		show_banner
		local scope=$1
		local category=$2
		local module=$3
		local flake=${4:-hay}

		test_module "$scope" "$category" "$module" "$flake"
		;;
	*)
		show_usage
		exit 1
		;;
	esac
}

# Scripti çalıştır
main "$@"
