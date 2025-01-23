#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Chrome Profile Launcher
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Google Chrome profile launcher utility with window management
#                and configuration support
#
#   Features:
#   - Profile-based Chrome launching
#   - Custom window class and title setting
#   - Profile discovery and validation
#   - Command-line argument passthrough
#   - Chrome state file integration
#   - Profile listing capabilities
#
#   License: MIT
#
#===============================================================================

set -euo pipefail

usage() {
	echo "Kullanım: $0 <profil_ismi> [--class=SINIF] [--title=BASLIK] [chrome_parametreleri]"
	echo "Mevcut profiller:"
	jq -r '.profile.info_cache | to_entries | map(.key + ": " + .value.name) | .[]' <"${HOME}/.config/google-chrome/Local State" 2>/dev/null | sort -k1,1 -k2,2n || echo "Chrome profil bilgisi okunamadı!"
	exit 1
}

# Parametre kontrolü
[ $# -eq 0 ] && usage

profile_name=$1
shift

# Varsayılan değerler
window_class=""
window_title=""
chrome_args=()

# Parametreleri işle
while [ $# -gt 0 ]; do
	case "$1" in
	--class=*)
		window_class="${1#*=}"
		;;
	--title=*)
		window_title="${1#*=}"
		;;
	*)
		chrome_args+=("$1")
		;;
	esac
	shift
done

local_state="${HOME}/.config/google-chrome/Local State"

# Profil anahtarını bul
profile_key=$(jq -r --arg name "$profile_name" \
	'.profile.info_cache | to_entries | .[] | 
    select(.value.name == $name) | .key' <"$local_state")

if [ -z "$profile_key" ]; then
	echo "Hata: '$profile_name' isimli profil bulunamadı."
	echo "Mevcut profiller:"
	jq -r '.profile.info_cache | to_entries | map(.key + ": " + .value.name) | .[]' <"$local_state" | sort -k1,1 -k2,2n
	exit 1
fi

# Chrome komut satırı argümanlarını oluştur
cmd=(google-chrome-stable --profile-directory="$profile_key")

# Class ve title parametrelerini ekle
[ -n "$window_class" ] && cmd+=(--class="$window_class")
[ -n "$window_title" ] && cmd+=("--window-name=$window_title")

# Diğer Chrome parametrelerini ekle
[ ${#chrome_args[@]} -gt 0 ] && cmd+=("${chrome_args[@]}")

# Chrome'u başlat
"${cmd[@]}"
