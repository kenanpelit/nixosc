#!/usr/bin/env bash

# ===================================================================
# NixOS Profil Yönetim Scripti
# Author: Kenan Pelit
# Description: NixOS sistem profillerini listeler, yönetir ve siler
# ===================================================================

# Renkler ve Stiller
readonly CYAN=$'\033[0;36m'
readonly ORANGE=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly GREEN=$'\033[0;32m'
readonly RED=$'\033[0;31m'
readonly GRAY=$'\033[0;90m'
readonly WHITE=$'\033[0;97m'
readonly NC=$'\033[0m'
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'

# Sistem Dizinleri
readonly SYSTEM_PROFILES="/nix/var/nix/profiles/system-profiles"
readonly SYSTEM_PROFILE="/nix/var/nix/profiles/system"
readonly NIX_STORE="/nix/store"

# Box Drawing Karakterleri
readonly TOP_CORNER="╭"
readonly BOT_CORNER="╰"
readonly VERTICAL="│"
readonly TEE="├"
readonly LAST_TEE="└"
readonly HORIZONTAL="─"
readonly BAR="═"

# Yardımcı Fonksiyonlar
format_date() {
	local timestamp=$1
	if [[ $timestamp =~ "1970" ]]; then
		echo -e "${GRAY}Tarih bilgisi yok${NC}"
	else
		date -d "@$timestamp" "+%Y-%m-%d %H:%M"
	fi
}

format_size() {
	local size=$(numfmt --to=iec-i --suffix=B $1)
	echo -e "${BLUE}${size}${NC}"
}

format_hash() {
	local hash=$1
	echo -e "${ORANGE}${hash:0:7}...${hash: -7}${NC}"
}

# Başlık Yazdırma
print_header() {
	echo
	echo -e "${CYAN}${BOLD}${TOP_CORNER}${BAR} NixOS Sistem Profilleri ${BAR}${NC}"
	echo
}

# Aktif Sistem Bilgileri
print_active_system() {
	local target=$(readlink -f $SYSTEM_PROFILE)
	local size=$(du -sh $target 2>/dev/null | cut -f1)
	local date=$(stat -L -c %Y $target)

	echo -e "${GREEN}${BOLD}⚡ Aktif Sistem Profili${NC}"
	echo -e "${TEE}${HORIZONTAL} Link    ${ORANGE}${target}${NC}"
	echo -e "${TEE}${HORIZONTAL} Boyut   ${BLUE}${size}${NC}"
	echo -e "${LAST_TEE}${HORIZONTAL} Tarih   ${BLUE}$(format_date $date)${NC}"
	echo
}

# Profilleri Listeleme
list_profiles() {
	local show_numbers=$1
	local profiles=($(find $SYSTEM_PROFILES -maxdepth 1 -type l -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-))
	local counter=1

	echo -e "${GREEN}${BOLD}📦 Mevcut Profiller${NC}"

	for profile in "${profiles[@]}"; do
		local name=$(basename $profile)
		local target=$(readlink -f $profile)
		local hash=$(basename $target)
		local size=$(du -sh $target 2>/dev/null | cut -f1)
		local date=$(stat -L -c %Y $profile)

		if [ "$show_numbers" = true ]; then
			echo -e "${TEE}${HORIZONTAL} ${ORANGE}[${counter}]${NC} ${CYAN}${BOLD}${name}${NC}"
		else
			echo -e "${TEE}${HORIZONTAL} ${CYAN}${BOLD}${name}${NC}"
		fi
		echo -e "${VERTICAL}  ${TEE}${HORIZONTAL} Hash    $(format_hash $hash)"
		echo -e "${VERTICAL}  ${TEE}${HORIZONTAL} Boyut   ${BLUE}${size}${NC}"
		echo -e "${VERTICAL}  ${LAST_TEE}${HORIZONTAL} Tarih   $(format_date $date)"
		((counter++))
	done
	echo
	return ${#profiles[@]}
}

# İstatistikleri Yazdırma
print_stats() {
	local total_size=$(du -sh $SYSTEM_PROFILES 2>/dev/null | cut -f1)
	local profile_count=$(ls -1 $SYSTEM_PROFILES | wc -l)
	local nix_disk=$(df -h /nix | awk 'NR==2 {print $3 "/" $2}')
	local store_size=$(du -sh $NIX_STORE 2>/dev/null | cut -f1)

	echo -e "${GREEN}${BOLD}📊 Profil İstatistikleri${NC}"
	echo -e "${TEE}${HORIZONTAL} Toplam Profil   ${BLUE}${profile_count}${NC}"
	echo -e "${TEE}${HORIZONTAL} Toplam Boyut    ${BLUE}${total_size}${NC}"
	echo -e "${TEE}${HORIZONTAL} /nix Kullanım   ${BLUE}${nix_disk}${NC}"
	echo -e "${LAST_TEE}${HORIZONTAL} Store Boyutu    ${BLUE}${store_size}${NC}"
}

# Profil Silme
delete_profile() {
	local profile_number=$1
	local profiles=($(find $SYSTEM_PROFILES -maxdepth 1 -type l -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-))

	if [ $profile_number -gt 0 ] && [ $profile_number -le ${#profiles[@]} ]; then
		local selected_profile=${profiles[$((profile_number - 1))]}
		local profile_name=$(basename $selected_profile)
		local current_profile=$(readlink -f $SYSTEM_PROFILE)
		local selected_target=$(readlink -f $selected_profile)

		# Aktif profil kontrolü
		if [ "$current_profile" = "$selected_target" ]; then
			echo -e "${RED}${BOLD}❌ Hata: Aktif profil silinemez!${NC}"
			return 1
		fi

		echo -e "${ORANGE}${BOLD}🗑️  Silinecek: ${NC}${profile_name}"
		echo -ne "${RED}Bu profili silmek istediğinizden emin misiniz? (e/H) ${NC}"
		read -r confirm

		if [[ $confirm =~ ^[Ee]$ ]]; then
			if sudo nix-env --profile $selected_profile --delete-generations old; then
				sudo rm -f $selected_profile
				echo -e "${GREEN}${BOLD}✅ Profil başarıyla silindi.${NC}"
			else
				echo -e "${RED}${BOLD}❌ Hata: Profil silinemedi!${NC}"
				return 1
			fi
		else
			echo -e "${BLUE}ℹ️  İşlem iptal edildi.${NC}"
		fi
	else
		echo -e "${RED}${BOLD}❌ Hata: Geçersiz profil numarası!${NC}"
		return 1
	fi
}

# İnteraktif Silme Modu
interactive_delete() {
	while true; do
		clear
		echo -e "${CYAN}${BOLD}${TOP_CORNER}${BAR} NixOS Profil Yöneticisi - Silme Modu ${BAR}${NC}\n"
		list_profiles true
		total_profiles=$?

		echo -e "${BOLD}Komutlar:${NC}"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}[1-$total_profiles]${NC} - Profil sil"
		echo -e "${LAST_TEE}${HORIZONTAL} ${WHITE}q${NC}          - Çıkış"
		echo
		echo -ne "${BOLD}Komut: ${NC}"
		read -r cmd

		case $cmd in
		[0-9]*)
			if [ $cmd -gt 0 ] && [ $cmd -le $total_profiles ]; then
				delete_profile $cmd
				echo -ne "\n${GRAY}Devam etmek için Enter'a basın...${NC}"
				read -r
			else
				echo -e "${RED}${BOLD}❌ Hata: Geçersiz numara!${NC}"
				sleep 1
			fi
			;;
		q | Q)
			break
			;;
		*)
			echo -e "${RED}${BOLD}❌ Hata: Geçersiz komut!${NC}"
			sleep 1
			;;
		esac
	done
}

# Yardım Mesajı
show_help() {
	echo -e "${BOLD}Kullanım:${NC}"
	echo -e "  $0 [SEÇENEKLER]"
	echo
	echo -e "${BOLD}Seçenekler:${NC}"
	echo -e "  ${TEE}${HORIZONTAL} ${WHITE}-l, --list${NC}     Profilleri listele (varsayılan)"
	echo -e "  ${TEE}${HORIZONTAL} ${WHITE}-d, --delete${NC}   İnteraktif silme modu"
	echo -e "  ${LAST_TEE}${HORIZONTAL} ${WHITE}-h, --help${NC}     Bu yardım mesajını göster"
	echo
	echo -e "${BOLD}Örnekler:${NC}"
	echo -e "  ${TEE}${HORIZONTAL} $0             Profilleri listele"
	echo -e "  ${LAST_TEE}${HORIZONTAL} sudo $0 -d      İnteraktif silme modunu başlat"
}

# Ana Program
case "$1" in
-h | --help)
	show_help
	;;
-d | --delete)
	if [ "$EUID" -eq 0 ]; then
		interactive_delete
	else
		echo -e "${RED}${BOLD}❌ Hata: Root yetkisi gerekli!${NC}"
		echo -e "Lütfen ${WHITE}sudo $0 -d${NC} şeklinde çalıştırın."
		exit 1
	fi
	;;
-l | --list | "")
	clear
	print_header
	print_active_system
	list_profiles false
	print_stats
	;;
*)
	echo -e "${RED}${BOLD}❌ Hata: Geçersiz parametre!${NC}"
	show_help
	exit 1
	;;
esac
