#!/usr/bin/env bash

# ===================================================================
# Gelişmiş NixOS Profil Yönetim Scripti
# Author: Kenan Pelit
# Description: NixOS sistem profillerini yönetir, karşılaştırır ve yedekler
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
readonly BACKUP_DIR="$HOME/.nix-profile-backups"

# Box Drawing Karakterleri
readonly TOP_CORNER="╭"
readonly BOT_CORNER="╰"
readonly VERTICAL="│"
readonly TEE="├"
readonly LAST_TEE="└"
readonly HORIZONTAL="─"
readonly BAR="═"

# Global Değişkenler
SORT_BY="date" # date, size, name
SHOW_DETAILS=false

# Yardımcı Fonksiyonlar
format_date() {
	local path=$1
	local date

	if [[ "$path" == *"system-profiles"* ]]; then
		date=$(stat -L -c %Y "$path" 2>/dev/null)
	else
		date=$(stat -L -c %Y "$path/system" 2>/dev/null)
	fi

	if [ $? -eq 0 ] && [ ! -z "$date" ]; then
		date -d "@$date" "+%Y-%m-%d %H:%M"
	else
		echo -e "${GRAY}$(date '+%Y-%m-%d %H:%M')${NC}"
	fi
}

format_size() {
	local file=$1
	if [ -L "$file" ]; then
		local target=$(readlink -f "$file")
		if [ -e "$target" ]; then
			local size=$(du -sh "$target" 2>/dev/null | cut -f1)
			if [ ! -z "$size" ]; then
				echo -e "${BLUE}${size}${NC}"
			else
				echo -e "${GRAY}Boyut alınamadı${NC}"
			fi
		else
			echo -e "${GRAY}Hedef bulunamadı${NC}"
		fi
	else
		echo -e "${GRAY}Link değil${NC}"
	fi
}

format_hash() {
	local path=$1
	local target

	if [[ "$path" == *"system-profiles"* ]]; then
		target=$(readlink -f "$path" 2>/dev/null)
	else
		target=$(readlink -f "$path/system" 2>/dev/null)
	fi

	if [ ! -z "$target" ]; then
		local hash=$(basename "$target" 2>/dev/null)
		if [ ${#hash} -ge 14 ]; then
			echo -e "${ORANGE}${hash:0:7}...${hash: -7}${NC}"
		else
			echo -e "${ORANGE}${hash}${NC}"
		fi
	else
		echo -e "${GRAY}Hash alınamadı${NC}"
	fi
}

# Geçerli profilleri filtrele
filter_valid_profiles() {
	local profiles=("$@")
	local valid_profiles=()

	for profile in "${profiles[@]}"; do
		if [ -L "$profile" ] && [ -e "$(readlink -f "$profile")" ]; then
			valid_profiles+=("$profile")
		fi
	done

	echo "${valid_profiles[@]}"
}

get_profile_details() {
	local profile=$1
	local target=$(readlink -f $profile)
	local result=""

	# Paket sayısı
	local package_count=$(nix-store -q --references $target 2>/dev/null | wc -l)
	result+="Paket Sayısı: ${BLUE}${package_count}${NC}\n"

	# Bağımlılık sayısı
	local dep_count=$(nix-store -q --requisites $target 2>/dev/null | wc -l)
	result+="Bağımlılık: ${BLUE}${dep_count}${NC}\n"

	# Sıkıştırılmış boyut
	local compressed_size=$(nix path-info -S $target 2>/dev/null | cut -f2)
	if [ ! -z "$compressed_size" ]; then
		result+="Sıkıştırılmış: ${BLUE}$(numfmt --to=iec-i --suffix=B $compressed_size)${NC}\n"
	fi

	echo -e "$result"
}

# Profil Sıralama
sort_profiles() {
	local profiles=("$@")
	local sorted=()

	case $SORT_BY in
	"date")
		# Son değiştirme tarihine göre sırala
		readarray -t sorted < <(for p in "${profiles[@]}"; do
			local date=$(stat -L -c %Y "$p" 2>/dev/null || echo 0)
			echo "$date|$p"
		done | sort -rn | cut -d'|' -f2)
		;;
	"size")
		# Boyuta göre sırala
		readarray -t sorted < <(for p in "${profiles[@]}"; do
			local size=$(du -b $(readlink -f "$p") 2>/dev/null | cut -f1)
			echo "${size:-0}|$p"
		done | sort -rn | cut -d'|' -f2)
		;;
	"name")
		# İsme göre sırala (özel profillerle normal profilleri ayrı tut)
		readarray -t sorted < <(for p in "${profiles[@]}"; do
			local name=$(basename "$p")
			# Özel profilleri (T1, T2 gibi) önce göster
			if [[ "$name" =~ ^T[0-9] ]]; then
				echo "0|$name|$p"
			elif [[ "$name" =~ ^kenp ]]; then
				echo "1|$name|$p"
			else
				echo "2|$name|$p"
			fi
		done | sort -t'|' -k1,1 -k2,2 | cut -d'|' -f3)
		;;
	esac

	echo "${sorted[@]}"
}

# Başlık Yazdırma
print_header() {
	echo
	echo -e "${CYAN}${BOLD}${TOP_CORNER}${BAR} NixOS Sistem Profilleri ${BAR}${NC}"
	echo -e "${VERTICAL} Sıralama: ${ORANGE}${SORT_BY}${NC}"
	echo -e "${VERTICAL} Detaylar: ${ORANGE}$([ "$SHOW_DETAILS" = true ] && echo "açık" || echo "kapalı")${NC}"
	echo
}

# Aktif Sistem Bilgileri
print_active_system() {
	local target=$(readlink -f $SYSTEM_PROFILE)
	local size=$(du -sh $target 2>/dev/null | cut -f1)
	local date=$(stat -L -c %Y $target)
	local hash=$(basename $target)

	echo -e "${GREEN}${BOLD}⚡ Aktif Sistem Profili${NC}"
	echo -e "${TEE}${HORIZONTAL} Hash    $(format_hash $hash)"
	echo -e "${TEE}${HORIZONTAL} Link    ${ORANGE}${target}${NC}"
	echo -e "${TEE}${HORIZONTAL} Boyut   ${BLUE}${size}${NC}"
	echo -e "${LAST_TEE}${HORIZONTAL} Tarih   $(format_date $date)"

	if [ "$SHOW_DETAILS" = true ]; then
		local details=$(get_profile_details $target)
		echo -e "${VERTICAL}  ${GRAY}$details${NC}"
	fi
	echo
}

# Profilleri Listeleme
list_profiles() {
	local show_numbers=$1
	# Sadece geçerli sembolik linkleri bul
	local profiles=($(find $SYSTEM_PROFILES -maxdepth 1 -type l -exec test -e {} \; -print))
	profiles=($(filter_valid_profiles "${profiles[@]}"))
	profiles=($(sort_profiles "${profiles[@]}"))
	local counter=1
	local last_index=${#profiles[@]}

	echo -e "${GREEN}${BOLD}📦 Mevcut Profiller${NC}"

	for profile in "${profiles[@]}"; do
		local name=$(basename $profile)
		local target=$(readlink -f $profile)
		local hash=$(basename $target)
		local size=$(du -sh $target 2>/dev/null | cut -f1)
		local date=$(stat -L -c %Y $profile)
		local is_last=$((counter == last_index))
		local prefix="${TEE}"
		local subprefix="${VERTICAL}  ${TEE}"
		local last_subprefix="${VERTICAL}  ${LAST_TEE}"

		if [ $is_last -eq 1 ]; then
			prefix="${LAST_TEE}"
			subprefix="   ${TEE}"
			last_subprefix="   ${LAST_TEE}"
		fi

		if [ "$show_numbers" = true ]; then
			echo -e "${prefix}${HORIZONTAL} ${ORANGE}[${counter}]${NC} ${CYAN}${BOLD}${name}${NC}"
		else
			echo -e "${prefix}${HORIZONTAL} ${CYAN}${BOLD}${name}${NC}"
		fi
		echo -e "${subprefix}${HORIZONTAL} Hash    $(format_hash $hash)"
		echo -e "${subprefix}${HORIZONTAL} Boyut   ${BLUE}${size}${NC}"
		echo -e "${last_subprefix}${HORIZONTAL} Tarih   $(format_date $date)"

		if [ "$SHOW_DETAILS" = true ]; then
			local details=$(get_profile_details $target)
			echo -e "   ${GRAY}$details${NC}"
		fi
		((counter++))
	done
	echo
	return ${#profiles[@]}
}

# Profil Karşılaştırma
compare_profiles() {
	local profile1=$1
	local profile2=$2

	if [[ ! -L $profile1 ]] || [[ ! -L $profile2 ]]; then
		echo -e "${RED}${BOLD}❌ Hata: Geçersiz profil!${NC}"
		return 1
	fi

	local target1=$(readlink -f $profile1)
	local target2=$(readlink -f $profile2)

	echo -e "${CYAN}${BOLD}🔍 Profil Karşılaştırması${NC}"
	echo -e "${TEE}${HORIZONTAL} Profil 1: ${CYAN}$(basename $profile1)${NC}"
	echo -e "${TEE}${HORIZONTAL} Profil 2: ${CYAN}$(basename $profile2)${NC}"
	echo

	# Paket farklılıkları
	echo -e "${ORANGE}${BOLD}📦 Paket Farklılıkları:${NC}"
	local pkgs1=$(nix-store -q --references $target1 2>/dev/null)
	local pkgs2=$(nix-store -q --references $target2 2>/dev/null)

	echo -e "${GREEN}Yalnızca Profil 1'de olan paketler:${NC}"
	comm -23 <(echo "$pkgs1" | sort) <(echo "$pkgs2" | sort)
	echo
	echo -e "${RED}Yalnızca Profil 2'de olan paketler:${NC}"
	comm -13 <(echo "$pkgs1" | sort) <(echo "$pkgs2" | sort)
}

# Profil Yedekleme
backup_profile() {
	local profile=$1
	local name=$(basename $profile)
	local target=$(readlink -f $profile)
	local backup_path="$BACKUP_DIR/$name-$(date +%Y%m%d-%H%M%S).tar.gz"

	mkdir -p $BACKUP_DIR

	echo -e "${CYAN}${BOLD}💾 Profil Yedekleniyor...${NC}"
	echo -e "${TEE}${HORIZONTAL} Profil: ${CYAN}$name${NC}"
	echo -e "${TEE}${HORIZONTAL} Hedef: ${ORANGE}$backup_path${NC}"

	if tar -czf "$backup_path" -C $(dirname $target) $(basename $target); then
		echo -e "${GREEN}${BOLD}✅ Yedekleme başarılı!${NC}"
	else
		echo -e "${RED}${BOLD}❌ Yedekleme başarısız!${NC}"
		return 1
	fi
}

# Profil Geri Yükleme
restore_profile() {
	local backup_file=$1
	local name=$(basename $backup_file .tar.gz)

	echo -e "${CYAN}${BOLD}📥 Profil Geri Yükleniyor...${NC}"
	echo -e "${TEE}${HORIZONTAL} Yedek: ${CYAN}$backup_file${NC}"

	if tar -xzf "$backup_file" -C $SYSTEM_PROFILES; then
		echo -e "${GREEN}${BOLD}✅ Geri yükleme başarılı!${NC}"
	else
		echo -e "${RED}${BOLD}❌ Geri yükleme başarısız!${NC}"
		return 1
	fi
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

		echo -e "${ORANGE}${BOLD}🗑️  Siliniyor: ${NC}${profile_name}"
		# Tek komutla hem profili hem de linkini sil
		if sudo nix profile wipe-history --profile $selected_profile && sudo rm -f $selected_profile; then
			echo -e "${GREEN}${BOLD}✅ Profil başarıyla silindi.${NC}"
		else
			echo -e "${RED}${BOLD}❌ Hata: Profil silinemedi!${NC}"
			return 1
		fi
	else
		echo -e "${RED}${BOLD}❌ Hata: Geçersiz profil numarası!${NC}"
		return 1
	fi
}

# İnteraktif Ana Menü
show_main_menu() {
	while true; do
		clear
		print_header
		print_active_system
		list_profiles true
		total_profiles=$?

		echo -e "${BOLD}Ana Menü:${NC}"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}d${NC} - Profil sil"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}c${NC} - Profilleri karşılaştır"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}b${NC} - Profil yedekle"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}r${NC} - Profil geri yükle"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}s${NC} - Sıralama değiştir (${ORANGE}$SORT_BY${NC})"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}t${NC} - Detayları $([ "$SHOW_DETAILS" = true ] && echo "gizle" || echo "göster")"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}a${NC} - Tüm eski profilleri sil"
		echo -e "${LAST_TEE}${HORIZONTAL} ${WHITE}q${NC} - Çıkış"
		echo
		echo -ne "${BOLD}Komut: ${NC}"
		read -r cmd

		case $cmd in
		d)
			echo -ne "Silinecek profil numarası: "
			read -r num
			delete_profile $num
			;;
		c)
			echo -ne "1. profil numarası: "
			read -r num1
			echo -ne "2. profil numarası: "
			read -r num2

			if [ $num1 -gt 0 ] && [ $num2 -gt 0 ] && [ $num1 -le $total_profiles ] && [ $num2 -le $total_profiles ]; then
				local profiles=($(find $SYSTEM_PROFILES -maxdepth 1 -type l -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-))
				compare_profiles "${profiles[$((num1 - 1))]}" "${profiles[$((num2 - 1))]}"
			else
				echo -e "${RED}${BOLD}❌ Hata: Geçersiz profil numarası!${NC}"
			fi
			;;
		b)
			echo -ne "Yedeklenecek profil numarası: "
			read -r num
			if [ $num -gt 0 ] && [ $num -le $total_profiles ]; then
				local profiles=($(find $SYSTEM_PROFILES -maxdepth 1 -type l -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-))
				backup_profile "${profiles[$((num - 1))]}"
			else
				echo -e "${RED}${BOLD}❌ Hata: Geçersiz profil numarası!${NC}"
			fi
			;;
		r)
			local backups=($(find $BACKUP_DIR -name "*.tar.gz" -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-))
			if [ ${#backups[@]} -eq 0 ]; then
				echo -e "${RED}${BOLD}❌ Hata: Yedek bulunamadı!${NC}"
			else
				echo -e "\n${CYAN}${BOLD}Mevcut Yedekler:${NC}"
				local counter=1
				for backup in "${backups[@]}"; do
					echo -e "${counter}) $(basename $backup)"
					((counter++))
				done
				echo -ne "\nGeri yüklenecek yedek numarası: "
				read -r num
				if [ $num -gt 0 ] && [ $num -le ${#backups[@]} ]; then
					restore_profile "${backups[$((num - 1))]}"
				else
					echo -e "${RED}${BOLD}❌ Hata: Geçersiz yedek numarası!${NC}"
				fi
			fi
			;;
		s)
			echo -e "\n${CYAN}${BOLD}Sıralama Seçenekleri:${NC}"
			echo -e "1) Tarihe göre"
			echo -e "2) Boyuta göre"
			echo -e "3) İsme göre"
			echo -ne "\nSeçiminiz: "
			read -r sort_choice
			case $sort_choice in
			1) SORT_BY="date" ;;
			2) SORT_BY="size" ;;
			3) SORT_BY="name" ;;
			*) echo -e "${RED}${BOLD}❌ Hata: Geçersiz seçim!${NC}" ;;
			esac
			;;
		t)
			SHOW_DETAILS=$([ "$SHOW_DETAILS" = true ] && echo false || echo true)
			;;
		a)
			echo -e "${ORANGE}${BOLD}⚠️  Tüm eski profiller silinecek!${NC}"
			echo -ne "${RED}Onaylıyor musunuz? (e/H) ${NC}"
			read -r confirm
			if [[ $confirm =~ ^[Ee]$ ]]; then
				local active_profile=$(readlink -f $SYSTEM_PROFILE)
				for profile in $(find $SYSTEM_PROFILES -maxdepth 1 -type l); do
					local target=$(readlink -f $profile)
					if [ "$target" != "$active_profile" ]; then
						if sudo nix profile wipe-history --profile $profile && sudo rm -f $profile; then
							echo -e "${GREEN}✓ $(basename $profile) silindi${NC}"
						else
							echo -e "${RED}✗ $(basename $profile) silinemedi${NC}"
						fi
					fi
				done
				echo -e "${GREEN}${BOLD}✅ Eski profiller temizlendi.${NC}"
			fi
			;;
		q)
			break
			;;
		*)
			echo -e "${RED}${BOLD}❌ Hata: Geçersiz komut!${NC}"
			;;
		esac

		echo -ne "\n${GRAY}Devam etmek için Enter'a basın...${NC}"
		read -r
	done
}

# İstatistikleri Yazdırma
print_stats() {
	local total_size=$(du -sh $SYSTEM_PROFILES 2>/dev/null | cut -f1)
	local profile_count=$(ls -1 $SYSTEM_PROFILES | wc -l)
	local nix_disk=$(df -h /nix | awk 'NR==2 {print $3 "/" $2}')
	local store_size=$(du -sh $NIX_STORE 2>/dev/null | cut -f1)
	local backup_size=0
	if [ -d "$BACKUP_DIR" ]; then
		backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
	fi

	echo -e "${GREEN}${BOLD}📊 Sistem İstatistikleri${NC}"
	echo -e "${TEE}${HORIZONTAL} Profil Sayısı   ${BLUE}${profile_count}${NC}"
	echo -e "${TEE}${HORIZONTAL} Profil Boyutu   ${BLUE}${total_size}${NC}"
	echo -e "${TEE}${HORIZONTAL} Yedek Boyutu    ${BLUE}${backup_size}${NC}"
	echo -e "${TEE}${HORIZONTAL} /nix Kullanım   ${BLUE}${nix_disk}${NC}"
	echo -e "${LAST_TEE}${HORIZONTAL} Store Boyutu    ${BLUE}${store_size}${NC}"
}

# Yardım Mesajı
show_help() {
	echo -e "${BOLD}Kullanım:${NC}"
	echo -e "  $0 [SEÇENEKLER]"
	echo
	echo -e "${BOLD}Seçenekler:${NC}"
	echo -e "${TEE}${HORIZONTAL} ${WHITE}-m, --menu${NC}    İnteraktif menüyü aç"
	echo -e "${TEE}${HORIZONTAL} ${WHITE}-l, --list${NC}    Profilleri listele"
	echo -e "${TEE}${HORIZONTAL} ${WHITE}-s, --stats${NC}   Sistem istatistiklerini göster"
	echo -e "${TEE}${HORIZONTAL} ${WHITE}-b, --backup${NC}  Aktif profili yedekle"
	echo -e "${LAST_TEE}${HORIZONTAL} ${WHITE}-h, --help${NC}    Bu yardım mesajını göster"
}

# Ana Program
case "$1" in
-h | --help)
	show_help
	;;
-m | --menu)
	show_main_menu
	;;
-l | --list)
	clear
	print_header
	print_active_system
	list_profiles false
	;;
-s | --stats)
	clear
	print_header
	print_stats
	;;
-b | --backup)
	backup_profile $SYSTEM_PROFILE
	;;
"")
	show_main_menu
	;;
*)
	echo -e "${RED}${BOLD}❌ Hata: Geçersiz parametre!${NC}"
	show_help
	exit 1
	;;
esac
