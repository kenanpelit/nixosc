#!/usr/bin/env bash

# ===================================================================
# Gelişmiş NixOS Profil Yönetim Scripti
# Author: Kenan Pelit
# Version: 1.1.0
# Description: NixOS sistem profillerini yönetir, karşılaştırır ve yedekler
# ===================================================================

# Renkler ve Stiller - ASCII escape formatı
CYAN="\033[0;36m"
ORANGE="\033[0;33m"
BLUE="\033[0;34m"
GREEN="\033[0;32m"
RED="\033[0;31m"
GRAY="\033[0;90m"
WHITE="\033[0;97m"
YELLOW="\033[0;33m"
PURPLE="\033[0;35m"
NC="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Sistem Dizinleri
SYSTEM_PROFILES="/nix/var/nix/profiles/system-profiles"
SYSTEM_PROFILE="/nix/var/nix/profiles/system"
NIX_STORE="/nix/store"
BACKUP_DIR="$HOME/.nix-profile-backups"
CONFIG_DIR="$HOME/.config/nixos-profiles"
CONFIG_FILE="$CONFIG_DIR/settings.conf"

# Box Drawing Karakterleri
TOP_CORNER="╭"
BOT_CORNER="╰"
VERTICAL="│"
TEE="├"
LAST_TEE="└"
HORIZONTAL="─"
BAR="═"

# Global Değişkenler
SORT_BY="date"      # date, size, name
SHOW_DETAILS=false  # Detaylı bilgileri göster/gizle
AUTO_BACKUP=false   # Silme öncesi otomatik yedekleme
CONFIRM_DELETE=true # Silme işlemi onay
MAX_BACKUPS=10      # Maksimum yedek sayısı

# Yapılandırma dosyası oluşturma/yükleme
setup_config() {
	mkdir -p "$CONFIG_DIR"

	# Yapılandırma dosyası yoksa oluştur
	if [[ ! -f "$CONFIG_FILE" ]]; then
		echo "# NixOS Profil Yönetim Scripti Yapılandırması" >"$CONFIG_FILE"
		echo "SORT_BY=\"$SORT_BY\"" >>"$CONFIG_FILE"
		echo "SHOW_DETAILS=$SHOW_DETAILS" >>"$CONFIG_FILE"
		echo "AUTO_BACKUP=$AUTO_BACKUP" >>"$CONFIG_FILE"
		echo "CONFIRM_DELETE=$CONFIRM_DELETE" >>"$CONFIG_FILE"
		echo "MAX_BACKUPS=$MAX_BACKUPS" >>"$CONFIG_FILE"
	else
		# Yapılandırma dosyasını yükle
		source "$CONFIG_FILE"
	fi
}

# Yapılandırma dosyasını güncelleme
update_config() {
	echo "# NixOS Profil Yönetim Scripti Yapılandırması" >"$CONFIG_FILE"
	echo "SORT_BY=\"$SORT_BY\"" >>"$CONFIG_FILE"
	echo "SHOW_DETAILS=$SHOW_DETAILS" >>"$CONFIG_FILE"
	echo "AUTO_BACKUP=$AUTO_BACKUP" >>"$CONFIG_FILE"
	echo "CONFIRM_DELETE=$CONFIRM_DELETE" >>"$CONFIG_FILE"
	echo "MAX_BACKUPS=$MAX_BACKUPS" >>"$CONFIG_FILE"
	echo -e "${GREEN}${BOLD}✓ Yapılandırma kaydedildi${NC}"
}

# Log fonksiyonu
log_message() {
	local level=$1
	local message=$2
	local log_file="$CONFIG_DIR/profile-manager.log"
	local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

	mkdir -p "$(dirname "$log_file")"
	echo "[$timestamp] [$level] $message" >>"$log_file"

	case $level in
	"ERROR") echo -e "${RED}${BOLD}❌ $message${NC}" ;;
	"WARNING") echo -e "${YELLOW}${BOLD}⚠️  $message${NC}" ;;
	"INFO") echo -e "${BLUE}${BOLD}ℹ️  $message${NC}" ;;
	"SUCCESS") echo -e "${GREEN}${BOLD}✅ $message${NC}" ;;
	esac
}

# Yardımcı Fonksiyonlar
format_date() {
	local path=$1
	local date

	if [[ "$path" == *"system-profiles"* ]]; then
		date=$(stat -L -c %Y "$path" 2>/dev/null)
	else
		date=$(stat -L -c %Y "$path/system" 2>/dev/null)
	fi

	if [ $? -eq 0 ] && [ -n "$date" ]; then
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
			if [ -n "$size" ]; then
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
		target="$path" # Doğrudan path'i kullan
	fi

	if [ -n "$target" ]; then
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
	local -a profiles=("$@")
	local -a valid_profiles=()

	for profile in "${profiles[@]}"; do
		if [ -L "$profile" ] && [ -e "$(readlink -f "$profile")" ]; then
			valid_profiles+=("$profile")
		fi
	done

	echo "${valid_profiles[@]}"
}

get_profile_details() {
	local profile=$1
	local target=$(readlink -f "$profile")
	local result=""

	# Paket sayısı
	local package_count=$(nix-store -q --references "$target" 2>/dev/null | wc -l)
	result+="Paket Sayısı: ${BLUE}${package_count}${NC}\n"

	# Bağımlılık sayısı
	local dep_count=$(nix-store -q --requisites "$target" 2>/dev/null | wc -l)
	result+="Bağımlılık: ${BLUE}${dep_count}${NC}\n"

	# Sıkıştırılmış boyut
	local compressed_size=$(nix path-info -S "$target" 2>/dev/null | cut -f2)
	if [ -n "$compressed_size" ]; then
		result+="Sıkıştırılmış: ${BLUE}$(numfmt --to=iec-i --suffix=B "$compressed_size")${NC}\n"
	fi

	# Oluşturulma tarihi (derleme tarihi) - JQ hatası burada
	# Bu bölümü kaldır veya aşağıdaki gibi güvenli hale getir
	if command -v jq >/dev/null 2>&1; then
		local json_output=$(nix path-info --json "$target" 2>/dev/null)
		if [ -n "$json_output" ] && echo "$json_output" | jq -e 'if type=="array" then .[0].registrationTime else null end' &>/dev/null; then
			local build_time=$(echo "$json_output" | jq -r 'if type=="array" then .[0].registrationTime else empty end')
			if [ -n "$build_time" ]; then
				result+="Derleme: ${BLUE}$(date -d "@$build_time" "+%Y-%m-%d %H:%M")${NC}\n"
			fi
		fi
	fi

	echo -e "$result"
}

# Profil Sıralama
sort_profiles() {
	local -a profiles=("$@")
	local -a sorted=()

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
			local size=$(du -b "$(readlink -f "$p")" 2>/dev/null | cut -f1)
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
	echo -e "${VERTICAL} Otomatik Yedekleme: ${ORANGE}$([ "$AUTO_BACKUP" = true ] && echo "açık" || echo "kapalı")${NC}"
	echo
}

# Aktif Sistem Bilgileri
print_active_system() {
	local target=$(readlink -f "$SYSTEM_PROFILE")
	local size=$(du -sh "$target" 2>/dev/null | cut -f1)
	local date=$(stat -L -c %Y "$target")
	local hash=$(basename "$target")
	local uptime=$(uptime | sed 's/.*up \([^,]*\),.*/\1/') # Bu satırı değiştirin
	local kernel=$(uname -r)

	echo -e "${GREEN}${BOLD}⚡ Aktif Sistem Profili${NC}"
	echo -e "${TEE}${HORIZONTAL} Hash    $(format_hash "$hash")"
	echo -e "${TEE}${HORIZONTAL} Link    ${ORANGE}${target}${NC}"
	echo -e "${TEE}${HORIZONTAL} Boyut   ${BLUE}${size}${NC}"
	echo -e "${TEE}${HORIZONTAL} Çalışma ${PURPLE}${uptime}${NC}"
	echo -e "${LAST_TEE}${HORIZONTAL} Çekirdek ${PURPLE}${kernel}${NC}"

	if [ "$SHOW_DETAILS" = true ]; then
		local details=$(get_profile_details "$target")
		echo -e "${VERTICAL}  ${GRAY}$details${NC}"
	fi
	echo
}

# Profilleri Listeleme
list_profiles() {
	local show_numbers=$1
	# Sadece geçerli sembolik linkleri bul
	local -a profiles
	mapfile -t profiles < <(find "$SYSTEM_PROFILES" -maxdepth 1 -type l -exec test -e {} \; -print)

	local -a valid_profiles
	valid_profiles=($(filter_valid_profiles "${profiles[@]}"))

	local -a sorted_profiles
	sorted_profiles=($(sort_profiles "${valid_profiles[@]}"))

	local counter=1
	local last_index=${#sorted_profiles[@]}

	echo -e "${GREEN}${BOLD}📦 Mevcut Profiller (${#sorted_profiles[@]})${NC}"

	if [ ${#sorted_profiles[@]} -eq 0 ]; then
		echo -e "   ${GRAY}Profil bulunamadı${NC}"
		return 0
	fi

	for profile in "${sorted_profiles[@]}"; do
		local name=$(basename "$profile")
		local target=$(readlink -f "$profile")
		local hash=$(basename "$target")
		local size=$(du -sh "$target" 2>/dev/null | cut -f1)
		local date=$(stat -L -c %Y "$profile")
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
		echo -e "${subprefix}${HORIZONTAL} Hash    $(format_hash "$hash")"
		echo -e "${subprefix}${HORIZONTAL} Boyut   ${BLUE}${size}${NC}"
		echo -e "${last_subprefix}${HORIZONTAL} Tarih   $(format_date "$date")"

		if [ "$SHOW_DETAILS" = true ]; then
			local details=$(get_profile_details "$target")
			echo -e "   ${GRAY}$details${NC}"
		fi
		((counter++))
	done
	echo
	return ${#sorted_profiles[@]}
}

# Profil Karşılaştırma
compare_profiles() {
	local profile1=$1
	local profile2=$2

	if [[ ! -L $profile1 ]] || [[ ! -L $profile2 ]]; then
		log_message "ERROR" "Geçersiz profil!"
		return 1
	fi

	local target1=$(readlink -f "$profile1")
	local target2=$(readlink -f "$profile2")

	local name1=$(basename "$profile1")
	local name2=$(basename "$profile2")

	echo -e "${CYAN}${BOLD}🔍 Profil Karşılaştırması${NC}"
	echo -e "${TEE}${HORIZONTAL} Profil 1: ${CYAN}${name1}${NC} ($(format_date "$profile1"))"
	echo -e "${LAST_TEE}${HORIZONTAL} Profil 2: ${CYAN}${name2}${NC} ($(format_date "$profile2"))"
	echo

	# Paket farklılıkları
	echo -e "${ORANGE}${BOLD}📦 Paket Farklılıkları:${NC}"

	# Paketleri çıkar
	local pkgs1=$(nix-store -q --references "$target1" 2>/dev/null)
	local pkgs2=$(nix-store -q --references "$target2" 2>/dev/null)

	# Paket farklılıklarını bul ve daha temiz göster
	local only_in_1=$(comm -23 <(echo "$pkgs1" | sort) <(echo "$pkgs2" | sort))
	local only_in_2=$(comm -13 <(echo "$pkgs1" | sort) <(echo "$pkgs2" | sort))

	local count_1=$(echo "$only_in_1" | grep -v '^$' | wc -l)
	local count_2=$(echo "$only_in_2" | grep -v '^$' | wc -l)

	echo -e "${GREEN}Yalnızca '${name1}' profilinde olan paketler (${count_1}):${NC}"
	if [ $count_1 -eq 0 ]; then
		echo -e "   ${GRAY}Farklı paket yok${NC}"
	else
		echo "$only_in_1" | while read -r pkg; do
			if [ -n "$pkg" ]; then
				local pkgname=$(basename "$pkg" | cut -d'-' -f2-)
				echo -e " + ${BLUE}${pkgname}${NC} (${GRAY}${pkg}${NC})"
			fi
		done
	fi

	echo
	echo -e "${RED}Yalnızca '${name2}' profilinde olan paketler (${count_2}):${NC}"
	if [ $count_2 -eq 0 ]; then
		echo -e "   ${GRAY}Farklı paket yok${NC}"
	else
		echo "$only_in_2" | while read -r pkg; do
			if [ -n "$pkg" ]; then
				local pkgname=$(basename "$pkg" | cut -d'-' -f2-)
				echo -e " - ${BLUE}${pkgname}${NC} (${GRAY}${pkg}${NC})"
			fi
		done
	fi

	# Özet bilgiler
	echo
	echo -e "${ORANGE}${BOLD}📊 Özet:${NC}"
	echo -e "${TEE}${HORIZONTAL} '${name1}' özgü paket sayısı: ${GREEN}${count_1}${NC}"
	echo -e "${TEE}${HORIZONTAL} '${name2}' özgü paket sayısı: ${RED}${count_2}${NC}"
	echo -e "${LAST_TEE}${HORIZONTAL} Toplam farklılık: ${PURPLE}$((count_1 + count_2))${NC}"
}

# Eski yedekleri temizle
clean_old_backups() {
	if [ ! -d "$BACKUP_DIR" ]; then
		return 0
	fi

	local -a backups
	mapfile -t backups < <(find "$BACKUP_DIR" -name "*.tar.gz" -printf "%T@ %p\n" | sort -n | cut -d' ' -f2-)

	local count=${#backups[@]}
	if [ $count -le $MAX_BACKUPS ]; then
		return 0
	fi

	local to_delete=$((count - MAX_BACKUPS))
	for ((i = 0; i < to_delete; i++)); do
		rm -f "${backups[$i]}"
		log_message "INFO" "Eski yedek silindi: $(basename "${backups[$i]}")"
	done
}

# Profil Yedekleme
backup_profile() {
	local profile=$1
	local name=$(basename "$profile")
	local target=$(readlink -f "$profile")
	local backup_path="$BACKUP_DIR/${name}-$(date +%Y%m%d-%H%M%S).tar.gz"

	mkdir -p "$BACKUP_DIR"

	echo -e "${CYAN}${BOLD}💾 Profil Yedekleniyor...${NC}"
	echo -e "${TEE}${HORIZONTAL} Profil: ${CYAN}${name}${NC}"
	echo -e "${LAST_TEE}${HORIZONTAL} Hedef: ${ORANGE}${backup_path}${NC}"

	if tar -czf "$backup_path" -C "$(dirname "$target")" "$(basename "$target")"; then
		log_message "SUCCESS" "Yedekleme başarılı: $name -> $backup_path"
		clean_old_backups
	else
		log_message "ERROR" "Yedekleme başarısız: $name"
		return 1
	fi
}

# Profil Geri Yükleme
restore_profile() {
	local backup_file=$1
	local name=$(basename "$backup_file" .tar.gz | cut -d'-' -f1)
	local restore_path="$SYSTEM_PROFILES/$name"

	echo -e "${CYAN}${BOLD}📥 Profil Geri Yükleniyor...${NC}"
	echo -e "${TEE}${HORIZONTAL} Yedek: ${CYAN}$(basename "$backup_file")${NC}"
	echo -e "${LAST_TEE}${HORIZONTAL} Hedef: ${ORANGE}${restore_path}${NC}"

	if [ -e "$restore_path" ]; then
		if [ "$CONFIRM_DELETE" = true ]; then
			echo -ne "${YELLOW}${BOLD}⚠️  Bu isimde bir profil zaten var. Üzerine yazılsın mı? (e/H) ${NC}"
			read -r overwrite
			if [[ ! $overwrite =~ ^[Ee]$ ]]; then
				log_message "INFO" "Geri yükleme iptal edildi (kullanıcı tarafından): $backup_file"
				return 0
			fi
		fi

		if [ "$AUTO_BACKUP" = true ]; then
			backup_profile "$restore_path"
		fi

		sudo rm -f "$restore_path"
	fi

	local temp_dir=$(mktemp -d)
	if tar -xzf "$backup_file" -C "$temp_dir" &&
		sudo cp -a "$temp_dir"/* "$NIX_STORE/" &&
		sudo ln -sf "$NIX_STORE/$(basename "$(tar -tzf "$backup_file" | head -1)")" "$restore_path"; then
		rm -rf "$temp_dir"
		log_message "SUCCESS" "Geri yükleme başarılı: $backup_file -> $restore_path"
	else
		rm -rf "$temp_dir"
		log_message "ERROR" "Geri yükleme başarısız: $backup_file"
		return 1
	fi
}

# Profil Silme
delete_profile() {
	local profile_number=$1
	local -a profiles

	mapfile -t profiles < <(find "$SYSTEM_PROFILES" -maxdepth 1 -type l -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-)

	if [ $profile_number -gt 0 ] && [ $profile_number -le ${#profiles[@]} ]; then
		local selected_profile=${profiles[$((profile_number - 1))]}
		local profile_name=$(basename "$selected_profile")
		local current_profile=$(readlink -f "$SYSTEM_PROFILE")
		local selected_target=$(readlink -f "$selected_profile")

		# Aktif profil kontrolü
		if [ "$current_profile" = "$selected_target" ]; then
			log_message "ERROR" "Aktif profil silinemez!"
			return 1
		fi

		if [ "$CONFIRM_DELETE" = true ]; then
			echo -ne "${YELLOW}${BOLD}⚠️  '${profile_name}' profili silinecek. Emin misiniz? (e/H) ${NC}"
			read -r confirm
			if [[ ! $confirm =~ ^[Ee]$ ]]; then
				log_message "INFO" "Silme işlemi iptal edildi (kullanıcı tarafından): $profile_name"
				return 0
			fi
		fi

		if [ "$AUTO_BACKUP" = true ]; then
			backup_profile "$selected_profile"
		fi

		echo -e "${ORANGE}${BOLD}🗑️  Siliniyor: ${NC}${profile_name}"
		if sudo nix profile wipe-history --profile "$selected_profile" && sudo rm -f "$selected_profile"; then
			log_message "SUCCESS" "Profil başarıyla silindi: $profile_name"
		else
			log_message "ERROR" "Profil silinemedi: $profile_name"
			return 1
		fi
	else
		log_message "ERROR" "Geçersiz profil numarası: $profile_number"
		return 1
	fi
}

# Yedek Yönetimi Menüsü
show_backup_menu() {
	while true; do
		clear
		echo -e "${CYAN}${BOLD}${TOP_CORNER}${BAR} Yedek Yönetimi ${BAR}${NC}"
		echo

		# Yedekleri listele
		local -a backups
		if [ -d "$BACKUP_DIR" ]; then
			mapfile -t backups < <(find "$BACKUP_DIR" -name "*.tar.gz" -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-)
		fi

		echo -e "${GREEN}${BOLD}📦 Mevcut Yedekler (${#backups[@]})${NC}"

		if [ ${#backups[@]} -eq 0 ]; then
			echo -e "   ${GRAY}Yedek bulunamadı${NC}"
		else
			local counter=1
			for backup in "${backups[@]}"; do
				local backup_name=$(basename "$backup")
				local backup_date=$(stat -c "%y" "$backup" | cut -d. -f1)
				local backup_size=$(du -h "$backup" | cut -f1)

				if [ $counter -eq ${#backups[@]} ]; then
					echo -e "${LAST_TEE}${HORIZONTAL} ${ORANGE}[${counter}]${NC} ${CYAN}${backup_name}${NC} (${BLUE}${backup_size}${NC}, ${GRAY}${backup_date}${NC})"
				else
					echo -e "${TEE}${HORIZONTAL} ${ORANGE}[${counter}]${NC} ${CYAN}${backup_name}${NC} (${BLUE}${backup_size}${NC}, ${GRAY}${backup_date}${NC})"
				fi
				((counter++))
			done
		fi

		echo
		echo -e "${BOLD}Yedek Yönetimi:${NC}"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}b${NC} - Aktif profili yedekle"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}c${NC} - Profili yedekle (numara ile)"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}r${NC} - Yedekten geri yükle"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}d${NC} - Yedek sil"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}p${NC} - Yedekleri temizle (${ORANGE}$MAX_BACKUPS${NC} adete kadar tut)"
		echo -e "${LAST_TEE}${HORIZONTAL} ${WHITE}q${NC} - Ana menüye dön"

		echo
		echo -ne "${BOLD}Komut: ${NC}"
		read -r backup_cmd

		# Komut işleme...
		case $backup_cmd in
		b) backup_profile "$SYSTEM_PROFILE" ;;
		c)
			echo -ne "\n${BOLD}Yedeklenecek profil numarası: ${NC}"
			read -r profile_num
			# İşlemlere devam...
			;;
		# ... diğer komutlar ...
		esac

		echo -ne "\n${GRAY}Devam etmek için Enter'a basın...${NC}"
		read -r
	done
}

# Ayarlar Menüsü
show_settings_menu() {
	while true; do
		clear
		echo -e "${CYAN}${BOLD}${TOP_CORNER}${BAR} Ayarlar Menüsü ${BAR}${NC}"
		echo
		echo -e "${BOLD}Mevcut Ayarlar:${NC}"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}1${NC} - Sıralama: ${ORANGE}$SORT_BY${NC}"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}2${NC} - Detaylar: ${ORANGE}$([ "$SHOW_DETAILS" = true ] && echo "Açık" || echo "Kapalı")${NC}"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}3${NC} - Otomatik Yedekleme: ${ORANGE}$([ "$AUTO_BACKUP" = true ] && echo "Açık" || echo "Kapalı")${NC}"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}4${NC} - Silme Onayı: ${ORANGE}$([ "$CONFIRM_DELETE" = true ] && echo "Açık" || echo "Kapalı")${NC}"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}5${NC} - Maksimum Yedek: ${ORANGE}$MAX_BACKUPS${NC}"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}s${NC} - Kaydet ve Çık"
		echo -e "${LAST_TEE}${HORIZONTAL} ${WHITE}q${NC} - Kaydetmeden Çık"
		echo
		echo -ne "${BOLD}Komut: ${NC}"
		read -r setting_cmd

		case $setting_cmd in
		1)
			echo -e "\n${CYAN}${BOLD}Sıralama Seçenekleri:${NC}"
			echo -e "1) ${ORANGE}date${NC} - Tarihe göre"
			echo -e "2) ${ORANGE}size${NC} - Boyuta göre"
			echo -e "3) ${ORANGE}name${NC} - İsme göre"
			echo -ne "\nSeçiminiz: "
			read -r sort_choice
			case $sort_choice in
			1) SORT_BY="date" ;;
			2) SORT_BY="size" ;;
			3) SORT_BY="name" ;;
			*) echo -e "${RED}${BOLD}❌ Hata: Geçersiz seçim!${NC}" ;;
			esac
			;;
		2)
			SHOW_DETAILS=$([ "$SHOW_DETAILS" = true ] && echo false || echo true)
			echo -e "${GREEN}${BOLD}✓ Detaylar $([ "$SHOW_DETAILS" = true ] && echo "açıldı" || echo "kapatıldı")${NC}"
			;;
		3)
			AUTO_BACKUP=$([ "$AUTO_BACKUP" = true ] && echo false || echo true)
			echo -e "${GREEN}${BOLD}✓ Otomatik Yedekleme $([ "$AUTO_BACKUP" = true ] && echo "açıldı" || echo "kapatıldı")${NC}"
			;;
		4)
			CONFIRM_DELETE=$([ "$CONFIRM_DELETE" = true ] && echo false || echo true)
			echo -e "${GREEN}${BOLD}✓ Silme Onayı $([ "$CONFIRM_DELETE" = true ] && echo "açıldı" || echo "kapatıldı")${NC}"
			;;
		5)
			echo -ne "\n${BOLD}Maksimum yedek sayısı (1-50): ${NC}"
			read -r max_backups
			if [[ $max_backups =~ ^[0-9]+$ ]] && [ $max_backups -ge 1 ] && [ $max_backups -le 50 ]; then
				MAX_BACKUPS=$max_backups
				echo -e "${GREEN}${BOLD}✓ Maksimum yedek sayısı güncellendi: $MAX_BACKUPS${NC}"
			else
				echo -e "${RED}${BOLD}❌ Hata: Geçersiz değer! (1-50 arası olmalı)${NC}"
			fi
			;;
		s | S)
			update_config
			break
			;;
		q | Q)
			echo -e "${YELLOW}${BOLD}⚠️  Değişiklikler kaydedilmedi${NC}"
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
		echo -e "${TEE}${HORIZONTAL} ${WHITE}b${NC} - Yedek yönetimi"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}g${NC} - Günlüğü görüntüle"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}s${NC} - Sıralama değiştir (${ORANGE}$SORT_BY${NC})"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}t${NC} - Detayları $([ "$SHOW_DETAILS" = true ] && echo "gizle" || echo "göster")"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}a${NC} - Tüm eski profilleri sil"
		echo -e "${TEE}${HORIZONTAL} ${WHITE}o${NC} - Ayarlar"
		echo -e "${LAST_TEE}${HORIZONTAL} ${WHITE}q${NC} - Çıkış"
		echo
		echo -ne "${BOLD}Komut: ${NC}"
		read -r cmd

		case $cmd in
		[dD])
			while true; do
				echo -ne "\n${BOLD}Silinecek profil numarası (çıkmak için 'q'): ${NC}"
				read -r num
				[ "$num" = "q" ] && break
				delete_profile $num && break
			done
			;;
		c)
			echo -ne "1. profil numarası: "
			read -r num1
			echo -ne "2. profil numarası: "
			read -r num2

			if [[ $num1 =~ ^[0-9]+$ ]] && [[ $num2 =~ ^[0-9]+$ ]] &&
				[ $num1 -gt 0 ] && [ $num2 -gt 0 ] &&
				[ $num1 -le $total_profiles ] && [ $num2 -le $total_profiles ]; then
				local profiles=($(find "$SYSTEM_PROFILES" -maxdepth 1 -type l -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-))
				compare_profiles "${profiles[$((num1 - 1))]}" "${profiles[$((num2 - 1))]}"
			else
				log_message "ERROR" "Geçersiz profil numarası!"
			fi
			;;
		b)
			# Yedek yönetimi menüsünü göster
			show_backup_menu
			;;
		g)
			# Günlüğü görüntüle
			local log_file="$CONFIG_DIR/profile-manager.log"
			if [ -f "$log_file" ]; then
				clear
				echo -e "${CYAN}${BOLD}${TOP_CORNER}${BAR} Sistem Günlüğü ${BAR}${NC}"
				echo
				echo -e "${GREEN}${BOLD}📋 Son Olaylar:${NC}"

				# En son 20 satırı göster, renklendir
				tail -n 20 "$log_file" | while IFS= read -r line; do
					if [[ $line == *"[ERROR]"* ]]; then
						echo -e "${RED}$line${NC}"
					elif [[ $line == *"[WARNING]"* ]]; then
						echo -e "${YELLOW}$line${NC}"
					elif [[ $line == *"[SUCCESS]"* ]]; then
						echo -e "${GREEN}$line${NC}"
					elif [[ $line == *"[INFO]"* ]]; then
						echo -e "${BLUE}$line${NC}"
					else
						echo -e "${GRAY}$line${NC}"
					fi
				done
			else
				log_message "INFO" "Günlük dosyası bulunamadı!"
			fi
			;;
		s)
			echo -e "\n${CYAN}${BOLD}Sıralama Seçenekleri:${NC}"
			echo -e "1) ${ORANGE}date${NC} - Tarihe göre"
			echo -e "2) ${ORANGE}size${NC} - Boyuta göre"
			echo -e "3) ${ORANGE}name${NC} - İsme göre"
			echo -ne "\nSeçiminiz: "
			read -r sort_choice
			case $sort_choice in
			1) SORT_BY="date" ;;
			2) SORT_BY="size" ;;
			3) SORT_BY="name" ;;
			*) log_message "ERROR" "Geçersiz seçim: $sort_choice" ;;
			esac
			;;
		t)
			SHOW_DETAILS=$([ "$SHOW_DETAILS" = true ] && echo false || echo true)
			echo -e "${GREEN}${BOLD}✓ Detaylar $([ "$SHOW_DETAILS" = true ] && echo "açıldı" || echo "kapatıldı")${NC}"
			;;
		o)
			# Ayarlar menüsünü göster
			show_settings_menu
			;;
		a)
			echo -e "${ORANGE}${BOLD}⚠️  Tüm eski profiller silinecek!${NC}"
			echo -ne "${RED}Onaylıyor musunuz? (e/H) ${NC}"
			read -r confirm
			if [[ $confirm =~ ^[Ee]$ ]]; then
				local active_profile=$(readlink -f "$SYSTEM_PROFILE")
				for profile in $(find "$SYSTEM_PROFILES" -maxdepth 1 -type l); do
					local target=$(readlink -f "$profile")
					if [ "$target" != "$active_profile" ]; then
						if [ "$AUTO_BACKUP" = true ]; then
							backup_profile "$profile"
						fi

						if sudo nix profile wipe-history --profile "$profile" && sudo rm -f "$profile"; then
							log_message "SUCCESS" "Profil silindi: $(basename "$profile")"
						else
							log_message "ERROR" "Profil silinemedi: $(basename "$profile")"
						fi
					fi
				done
				log_message "SUCCESS" "Eski profiller temizlendi"
			fi
			;;
		q)
			break
			;;
		*)
			log_message "ERROR" "Geçersiz komut: $cmd"
			;;
		esac

		echo -ne "\n${GRAY}Devam etmek için Enter'a basın...${NC}"
		read -r
	done
}

# Ana menü fonksiyonu, ayarlar menüsü ve diğer işlevler...

# Ana Program işleme kısmı
main() {
	# Yapılandırma dosyasını yükle
	setup_config

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
		backup_profile "$SYSTEM_PROFILE"
		;;
	# Diğer seçenekler...
	"")
		show_main_menu
		;;
	*)
		log_message "ERROR" "Geçersiz parametre: $1"
		show_help
		exit 1
		;;
	esac
}

# Programı çalıştır
main "$@"
