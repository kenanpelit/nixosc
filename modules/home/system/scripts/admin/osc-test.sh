#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Symlink Manager
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Manages symbolic links for configured directories between a
#                source repository and target location with backup functionality
#
#   Features:
#   - Creates symbolic links from source to target directories
#   - Automatic backup of existing directories
#   - Configurable directory list
#   - Dry-run mode for testing
#   - Color-coded status output
#   - Safety checks and confirmations
#
#   License: MIT
#
#===============================================================================

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ana dizinler
NIXOS_DIR="$HOME/.nixosc"
MODULES_DIR="$NIXOS_DIR/modules"

# Kategorileri listele
list_categories() {
	echo -e "${BLUE}Kategoriler:${NC}"
	for dir in "$MODULES_DIR/home"/*; do
		if [[ -d "$dir" ]]; then
			echo "  $(basename "$dir")"
		fi
	done
}

# Modülleri listele
list_modules() {
	local category=$1
	if [[ -d "$MODULES_DIR/home/$category" ]]; then
		echo -e "${BLUE}$category altındaki modüller:${NC}"
		for module in "$MODULES_DIR/home/$category"/*; do
			if [[ -d "$module" ]]; then
				echo "  $(basename "$module")"
			fi
		done
	else
		echo -e "${RED}Hata: '$category' kategorisi bulunamadı!${NC}"
		list_categories
		exit 1
	fi
}

# Kullanım fonksiyonu
show_usage() {
	echo "Kullanım: $(basename "$0") <scope> <category> <module> [flake]"
	echo "Örnek: $(basename "$0") home desktop rofi hay"
	echo
	list_categories
}

# Ana fonksiyon
main() {
	case $# in
	0)
		show_usage
		;;
	1)
		if [[ "$1" == "home" ]]; then
			list_categories
		else
			list_modules "$1"
		fi
		;;
	2)
		if [[ "$1" == "home" ]]; then
			list_modules "$2"
		else
			show_usage
		fi
		;;
	3 | 4)
		local scope=$1
		local category=$2
		local module=$3
		local flake=${4:-hay}

		# Dizin yolları
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

		echo -e "${GREEN}Test ediliyor: $scope/$category/$module${NC}"
		# Yapılandırmayı test et
		if sudo nixos-rebuild test --flake .#"$flake" -I nixos-config="$config_dir"; then
			echo -e "${GREEN}Test başarılı!${NC}"
		else
			echo -e "${RED}Test başarısız!${NC}"
			exit 1
		fi
		;;
	*)
		show_usage
		exit 1
		;;
	esac
}

# Scripti çalıştır
main "$@"
