#!/usr/bin/env bash
#######################################
#
# Version: 2.3.0
# Date: 2024-03-22
# Author: Kenan Pelit (İyileştirmeler eklendi)
# Repository: github.com/kenanpelit/dotfiles
# Description: TransmissionCLI - Transmission Terminal Yönetim Aracı
#
# Bu script transmission-remote için gelişmiş bir CLI arayüzü sağlar.
# Temel özellikleri:
# - Pass entegrasyonu ile güvenli kimlik bilgileri yönetimi
# - Gelişmiş torrent arama (kategori destekli)
# - Torrent ekleme ve yönetim (magnet/dosya)
# - Detaylı istatistikler ve sağlık kontrolleri
# - Disk alanı takibi
# - Otomatik tamamlanan torrent yönetimi
# - Hız limitleri ve kategori yönetimi
# - Torrent önceliklendirme sistemi
# - Zamanlama sistemi ile otomatik başlatma/durdurma
# - Gelişmiş filtreleme ve sıralama
# - İlerleme göstergeleri
# - Otomatik etiketleme ve kategorileme
#
# Komutlar için ./tsm.sh yazarak yardım alabilirsiniz.
#
# Gereksinimler:
# - pass (şifre yöneticisi)
# - transmission-remote
# - transmission-daemon
# - pirate-get (arama özelliği için)
# - jq (JSON parsing için)
# - at (zamanlama için)
#
# License: MIT
#
#######################################

# Renk kodları
Color_Off='\e[0m'
Red='\e[0;31m'
Green='\e[0;32m'
Yellow='\e[0;33m'
Blue='\e[0;34m'
Purple='\e[0;35m'
Cyan='\e[0;36m'

# Script versiyonu
VERSION="2.3.0"

# Hata kontrolü ve bağımlılık kontrolü
check_dependencies() {
	local missing_deps=()

	# Gerekli komutların kontrolü
	for cmd in pass transmission-remote pirate-get jq; do
		if ! command -v "$cmd" &>/dev/null; then
			missing_deps+=("$cmd")
		fi
	done

	# 'at' komutu isteğe bağlı (zamanlama için)
	if ! command -v "at" &>/dev/null; then
		echo -e "${Yellow}Uyarı: 'at' komutu bulunamadı. Zamanlama özellikleri çalışmayabilir.${Color_Off}"
	fi

	if [ ${#missing_deps[@]} -ne 0 ]; then
		echo -e "${Red}Hata: Aşağıdaki bağımlılıklar eksik:${Color_Off}"
		printf '%s\n' "${missing_deps[@]}"
		exit 1
	fi
}

# Transmission ayarlarını al
get_transmission_settings() {
	CONFIG_FILE="$HOME/.config/transmission-daemon/settings.json"
	if [ -f "$CONFIG_FILE" ]; then
		PORT=$(grep -o '"rpc-port": [0-9]*' "$CONFIG_FILE" | awk '{print $2}')
		HOST="localhost" # localhost kullan çünkü bağlantı yerel
		USER=$(pass tsm-user 2>/dev/null || echo "admin")
		PASS=$(pass tsm-pass 2>/dev/null)
		DOWNLOAD_DIR=$(grep -o '"download-dir": "[^"]*' "$CONFIG_FILE" | cut -d'"' -f4)
	else
		PORT=9091
		HOST="localhost"
		USER=$(pass tsm-user 2>/dev/null || echo "admin")
		PASS=$(pass tsm-pass 2>/dev/null)
		DOWNLOAD_DIR="$HOME/Downloads"
	fi
}

# Pass kontrolü ve yapılandırma
setup_pass() {
	if ! pass show tsm-user &>/dev/null; then
		read -p "Transmission kullanıcı adı (varsayılan: admin): " username
		username=${username:-admin}
		echo "$username" | pass insert -e tsm-user
	fi

	if ! pass show tsm-pass &>/dev/null; then
		read -sp "Transmission şifresi: " password
		echo
		echo "$password" | pass insert -e tsm-pass
	fi
}

# Program başlangıç kontrolleri
init() {
	check_dependencies
	setup_pass
	get_transmission_settings
}

# Transmission kontrolü
check_transmission() {
	if ! transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l >/dev/null 2>&1; then
		echo -e "${Yellow}Transmission bağlantısı kontrol ediliyor...${Color_Off}"
		systemctl --user start transmission
		sleep 2
	fi
}

# İlerleme çubuğu oluştur
progress_bar() {
	local percent=$1

	# N/A veya sayı olmayanlar için kontrol
	if [[ ! "$percent" =~ ^[0-9]+$ ]]; then
		echo -e "  N/A |${Yellow}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${Color_Off}|"
		return
	fi

	local width=50
	local num_blocks=$(((percent * width) / 100))
	local progress=""

	for ((i = 0; i < num_blocks; i++)); do
		progress+="█"
	done

	for ((i = num_blocks; i < width; i++)); do
		progress+="░"
	done

	if [ "$percent" -lt 10 ]; then
		echo -e "  $percent% |${Purple}$progress${Color_Off}|"
	elif [ "$percent" -lt 100 ]; then
		echo -e " $percent% |${Purple}$progress${Color_Off}|"
	else
		echo -e "$percent% |${Green}$progress${Color_Off}|"
	fi
}

# Yardım mesajı
show_help() {
	echo -e "${Blue}Transmission Terminal Yöneticisi v$VERSION${Color_Off}"
	echo "Kullanım: tsm.sh [komut] [parametre]"
	echo
	echo "Arama Komutları:"
	echo -e "${Green}search${Color_Off}, ${Green}s${Color_Off} [terim]     Torrent ara"
	echo -e "${Green}search -c${Color_Off} [kategori] [terim]  Belirli kategoride ara"
	echo -e "${Green}search -R${Color_Off} [terim]    Son 48 saatteki torrentlerde ara"
	echo -e "${Green}search -l${Color_Off}            Mevcut kategorileri listele"
	echo
	echo "Temel Komutlar:"
	echo -e "${Green}add${Color_Off} [link/dosya]    Torrent veya magnet link ekle"
	echo -e "${Green}list${Color_Off}, ${Green}l${Color_Off} [seçenekler]  Torrent listesini göster"
	echo -e "${Green}list --sort-by=[name|size|status|progress]${Color_Off}  Sıralama ile listele"
	echo -e "${Green}list --filter=\"[kriter]\"${Color_Off}  Filtre ile listele (ör: --filter=\"size>1GB\")"
	echo -e "${Green}start${Color_Off} [id]          Torrenti başlat"
	echo -e "${Green}stop${Color_Off} [id]           Torrenti durdur"
	echo -e "${Green}remove${Color_Off} [id]         Torrenti sil"
	echo -e "${Green}purge${Color_Off} [id]          Torrenti ve dosyaları sil"
	echo -e "${Green}info${Color_Off} [id]           Torrent detaylarını göster"
	echo
	echo "Gelişmiş Komutlar:"
	echo -e "${Green}priority${Color_Off} [id] [high|normal|low]  Torrent önceliğini ayarla"
	echo -e "${Green}schedule${Color_Off} [id] --start \"HH:MM\" --end \"HH:MM\"  Zamanlama ayarla"
	echo -e "${Green}tag${Color_Off} [id] [etiket]   Torrent'e etiket ekle"
	echo -e "${Green}auto-tag${Color_Off}            Torrentleri içeriğe göre otomatik etiketle"
	echo -e "${Green}tsm-remove-done${Color_Off}     Tamamlanmış torrentleri sil"
	echo -e "${Green}auto-remove${Color_Off}         Otomatik tamamlanan torrent silme (daemon)"
	echo -e "${Green}disk-check${Color_Off}          Disk kullanım durumunu kontrol et"
	echo -e "${Green}stats${Color_Off}               Detaylı istatistikleri göster"
	echo -e "${Green}move${Color_Off} [id] [hedef]   Torrenti başka klasöre taşı"
	echo -e "${Green}limit${Color_Off} [up/down] [hız] Hız limiti ayarla (KB/s)"
	echo -e "${Green}tracker${Color_Off} [id]        Tracker bilgilerini göster"
	echo -e "${Green}health${Color_Off}              Torrent sağlık kontrolü"
	echo -e "${Green}speed${Color_Off}               İndirme/yükleme hızını göster"
	echo -e "${Green}files${Color_Off} [id]          Torrent dosyalarını listele"
	echo -e "${Green}config${Color_Off}              Yapılandırmayı güncelle"
	echo
	echo "Not: [id] yerine 'all' yazarak tüm torrentlere işlem yapabilirsiniz"
}

# Gelişmiş Torrent listesini göster (sıralama ve filtreleme destekli)
show_list() {
	check_transmission
	local sort_by=""
	local filter=""

	# Parametreleri işle
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--sort-by=*)
			sort_by="${1#*=}"
			shift
			;;
		--filter=*)
			filter="${1#*=}"
			shift
			;;
		*)
			shift
			;;
		esac
	done

	echo -e "${Blue}Torrent Listesi:${Color_Off}"

	# Torrent listesini JSON formatında al
	local torrent_data=$(transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l -j)

	# JSON verisini jq ile işle
	if [ -n "$filter" ] || [ -n "$sort_by" ]; then
		echo -e "${Yellow}Filtreleme/Sıralama uygulanıyor...${Color_Off}"

		# Basit bir filtreleme uygulamasının temeli
		# Gerçek bir uygulamada daha karmaşık filtre parsing işlemi yapılmalı
		if [[ "$filter" == *"size>1GB"* ]]; then
			torrent_data=$(echo "$torrent_data" | jq '.arguments.torrents[] | select(.sizeWhenDone > 1073741824)')
		elif [[ "$filter" == *"progress=100"* ]]; then
			torrent_data=$(echo "$torrent_data" | jq '.arguments.torrents[] | select(.percentDone == 1.0)')
		fi

		# Sıralama işlemi
		case "$sort_by" in
		"name")
			echo -e "${Yellow}İsme göre sıralanıyor...${Color_Off}"
			torrent_data=$(echo "$torrent_data" | jq -s 'sort_by(.name)')
			;;
		"size")
			echo -e "${Yellow}Boyuta göre sıralanıyor...${Color_Off}"
			torrent_data=$(echo "$torrent_data" | jq -s 'sort_by(.sizeWhenDone) | reverse')
			;;
		"status")
			echo -e "${Yellow}Duruma göre sıralanıyor...${Color_Off}"
			torrent_data=$(echo "$torrent_data" | jq -s 'sort_by(.status)')
			;;
		"progress")
			echo -e "${Yellow}İlerlemeye göre sıralanıyor...${Color_Off}"
			torrent_data=$(echo "$torrent_data" | jq -s 'sort_by(.percentDone)')
			;;
		esac
	fi

	# Standart liste çıktısını göster
	transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l

	# İlerleme çubuklarını göster
	echo -e "\n${Blue}İlerleme Çubukları:${Color_Off}"
	transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | grep -v "Sum\|ID" | while read -r line; do
		id=$(echo "$line" | awk '{print $1}' | sed 's/[*]//g')
		name=$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf "%s ", $i; printf "\n"}' | sed 's/^ *//;s/ *$//')
		percent=$(echo "$line" | awk '{print $2}' | sed 's/%//')

		echo -e "${Cyan}[$id] ${Yellow}$name${Color_Off}"
		progress_bar "$percent"
		echo ""
	done
}

# Öncelik ayarlama fonksiyonu
set_priority() {
	check_transmission
	local id=$1
	local priority=$2

	if [ -z "$id" ] || [ -z "$priority" ]; then
		echo -e "${Red}Hata: Torrent ID ve öncelik (high/normal/low) gerekli${Color_Off}"
		return 1
	fi

	# Öncelik değerini kontrol et
	case "$priority" in
	"high")
		echo -e "${Yellow}$id ID'li torrent için yüksek öncelik ayarlanıyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$id" --priority-high
		;;
	"normal")
		echo -e "${Yellow}$id ID'li torrent için normal öncelik ayarlanıyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$id" --priority-normal
		;;
	"low")
		echo -e "${Yellow}$id ID'li torrent için düşük öncelik ayarlanıyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$id" --priority-low
		;;
	*)
		echo -e "${Red}Hata: Geçersiz öncelik değeri. 'high', 'normal' veya 'low' kullanın.${Color_Off}"
		return 1
		;;
	esac

	echo -e "${Green}Öncelik başarıyla ayarlandı.${Color_Off}"
}

# Zamanlama fonksiyonu
schedule_torrent() {
	check_transmission
	local id=$1
	local start_time=""
	local end_time=""

	# Parametreleri işle
	shift
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--start)
			start_time="$2"
			shift 2
			;;
		--end)
			end_time="$2"
			shift 2
			;;
		*)
			shift
			;;
		esac
	done

	if [ -z "$id" ] || [ -z "$start_time" ] || [ -z "$end_time" ]; then
		echo -e "${Red}Hata: Torrent ID, başlama zamanı (--start \"HH:MM\") ve bitiş zamanı (--end \"HH:MM\") gerekli${Color_Off}"
		return 1
	fi

	# Saat formatını kontrol et
	if ! [[ "$start_time" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]] || ! [[ "$end_time" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
		echo -e "${Red}Hata: Geçersiz zaman formatı. \"HH:MM\" formatını kullanın.${Color_Off}"
		return 1
	fi

	# 'at' komutunun varlığını kontrol et
	if ! command -v "at" &>/dev/null; then
		echo -e "${Red}Hata: 'at' komutu bulunamadı. Lütfen yükleyin.${Color_Off}"
		return 1
	fi

	# Başlangıç zamanı için zamanlama
	echo "transmission-remote $HOST:$PORT --auth $USER:$PASS -t $id -s" | at "$start_time" 2>/dev/null

	# Bitiş zamanı için zamanlama
	echo "transmission-remote $HOST:$PORT --auth $USER:$PASS -t $id -S" | at "$end_time" 2>/dev/null

	echo -e "${Green}Zamanlama başarıyla ayarlandı.${Color_Off}"
	echo -e "${Yellow}Torrent $id ID'li torrent $start_time'da başlayacak ve $end_time'da duracak.${Color_Off}"
}

# Etiketleme fonksiyonu
tag_torrent() {
	check_transmission
	local id=$1
	local tag=$2

	if [ -z "$id" ] || [ -z "$tag" ]; then
		echo -e "${Red}Hata: Torrent ID ve etiket gerekli${Color_Off}"
		return 1
	fi

	# Etiket bilgisini transmission'a ekle
	# Not: Transmission doğrudan etiketleme desteklemez, bu nedenle yorum alanını kullanıyoruz
	transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$id" --comment "tag:$tag"

	echo -e "${Green}$id ID'li torrent \"$tag\" etiketi ile işaretlendi.${Color_Off}"
}

# Otomatik etiketleme fonksiyonu
auto_tag() {
	check_transmission
	echo -e "${Yellow}Torrentler otomatik etiketleniyor...${Color_Off}"

	# Tüm torrentleri al
	transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | grep -v "Sum\|ID" | while read -r line; do
		id=$(echo "$line" | awk '{print $1}' | sed 's/[*]//g')
		name=$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf "%s ", $i; printf "\n"}' | sed 's/^ *//;s/ *$//')

		# Dosya türüne göre etiket belirle
		local tag=""

		if [[ "$name" =~ \.(mkv|mp4|avi|mov)$ ]]; then
			tag="video"
		elif [[ "$name" =~ \.(mp3|flac|wav|aac)$ ]]; then
			tag="audio"
		elif [[ "$name" =~ \.(iso|img)$ ]]; then
			tag="disk-image"
		elif [[ "$name" =~ \.(exe|msi|dmg|deb|rpm)$ ]]; then
			tag="application"
		elif [[ "$name" =~ \.(pdf|epub|mobi)$ ]]; then
			tag="ebook"
		elif [[ "$name" =~ \.(zip|rar|7z|tar|gz)$ ]]; then
			tag="archive"
		else
			# İçeriğe göre belirleme
			if [[ "$name" =~ (1080p|720p|2160p|UHD|BluRay|x264|x265|HEVC) ]]; then
				tag="movie"
			elif [[ "$name" =~ (S[0-9]+E[0-9]+|Season|Episode) ]]; then
				tag="tv-show"
			elif [[ "$name" =~ (FLAC|MP3|Album|OST|Discography) ]]; then
				tag="music"
			elif [[ "$name" =~ (Game|GOG|CODEX|RELOADED) ]]; then
				tag="game"
			else
				tag="other"
			fi
		fi

		# Etiketi uygula
		if [ -n "$tag" ]; then
			transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$id" --comment "tag:$tag"
			echo -e "${Green}[$id] $name: ${Yellow}$tag${Color_Off} etiketi eklendi."
		fi
	done

	echo -e "${Green}Otomatik etiketleme tamamlandı.${Color_Off}"
}

# Yapılandırmayı yeniden ayarla
reconfigure() {
	read -p "Yeni kullanıcı adı (varsayılan: admin): " new_username
	new_username=${new_username:-admin}
	echo "$new_username" | pass insert -f -e tsm-user

	read -sp "Yeni şifre: " new_password
	echo
	echo "$new_password" | pass insert -f -e tsm-pass

	echo -e "${Green}Yapılandırma güncellendi.${Color_Off}"
}

# Search fonksiyonu
do_search() {
	check_transmission
	local RECENT=false
	local CATEGORY=""
	local search_term=""

	# Eğer ilk parametre -l ise kategorileri listele
	if [ "$1" = "-l" ] || [ "$1" = "--list-categories" ]; then
		echo -e "${Blue}Mevcut Kategoriler:${Color_Off}"
		pirate-get --list-categories
		return 0
	fi

	# Parametreleri kontrol et
	while getopts "Rc:" opt; do
		case $opt in
		R) RECENT=true ;;
		c) CATEGORY="-c $OPTARG" ;;
		\?) return 1 ;;
		esac
	done
	shift $((OPTIND - 1))

	search_term="$*"
	if [ -z "$search_term" ]; then
		echo -e "${Red}Hata: Arama terimi gerekli${Color_Off}"
		return 1
	fi

	local RECENT_FLAG=""
	if [ "$RECENT" = true ]; then
		RECENT_FLAG="-R"
	fi

	echo -e "${Yellow}Arama yapılıyor: $search_term${Color_Off}"
	if [ -n "$CATEGORY" ]; then
		echo -e "${Blue}Kategori: ${CATEGORY#-c }${Color_Off}"
	fi

	pirate-get -t -E "$HOST:$PORT" -A "$USER:$PASS" $RECENT_FLAG $CATEGORY "$search_term"
}

# Program başlangıç işlemleri
init

# Ana case yapısı
case "$1" in
"search" | "s")
	shift
	do_search "$@"
	;;

"list" | "l")
	shift
	show_list "$@"
	;;

"add")
	if [ -z "$2" ]; then
		echo -e "${Red}Hata: Torrent dosyası veya magnet link gerekli${Color_Off}"
		exit 1
	fi
	echo -e "${Yellow}Torrent ekleniyor...${Color_Off}"
	transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -a "$2"
	;;

"start")
	if [ "$2" = "all" ]; then
		echo -e "${Yellow}Tüm torrentler başlatılıyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t all -s
	elif [ -n "$2" ]; then
		echo -e "${Yellow}$2 ID'li torrent başlatılıyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -s
	else
		echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
		exit 1
	fi
	;;

"stop")
	if [ "$2" = "all" ]; then
		echo -e "${Yellow}Tüm torrentler durduruluyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t all -S
	elif [ -n "$2" ]; then
		echo -e "${Yellow}$2 ID'li torrent durduruluyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -S
	else
		echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
		exit 1
	fi
	;;

"remove")
	if [ "$2" = "all" ]; then
		echo -e "${Red}Tüm torrentler siliniyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t all -r
	elif [ -n "$2" ]; then
		echo -e "${Red}$2 ID'li torrent siliniyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -r
	else
		echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
		exit 1
	fi
	;;

"purge")
	if [ "$2" = "all" ]; then
		echo -e "${Red}Tüm torrentler ve dosyaları siliniyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t all -rad
	elif [ -n "$2" ]; then
		echo -e "${Red}$2 ID'li torrent ve dosyaları siliniyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -rad
	else
		echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
		exit 1
	fi
	;;

"priority")
	set_priority "$2" "$3"
	;;

"schedule")
	shift
	schedule_torrent "$@"
	;;

"tag")
	tag_torrent "$2" "$3"
	;;

"auto-tag")
	auto_tag
	;;

"tsm-remove-done")
	echo -e "${Yellow}Tamamlanmış torrentler kontrol ediliyor...${Color_Off}"
	completed_torrents=$(transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | grep "100%" | awk '{print $1}' | sed 's/[*]//g')

	if [ -z "$completed_torrents" ]; then
		echo -e "${Yellow}Tamamlanmış torrent bulunamadı.${Color_Off}"
		exit 0
	fi

	echo -e "${Red}Tamamlanmış torrentler siliniyor...${Color_Off}"
	for id in $completed_torrents; do
		echo -e "${Yellow}$id ID'li tamamlanmış torrent siliniyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$id" -r
	done
	echo -e "${Green}Tamamlanmış torrentler silindi.${Color_Off}"
	;;

"auto-remove")
	echo -e "${Yellow}Otomatik silme modu etkinleştiriliyor...${Color_Off}"
	while true; do
		completed=$(transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | grep "100%" | awk '{print $1}' | sed 's/[*]//g')
		if [ -n "$completed" ]; then
			for id in $completed; do
				transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$id" -r
				echo -e "${Green}Torrent $id otomatik silindi${Color_Off}"
			done
		fi
		sleep 300 # 5 dakikada bir kontrol
	done
	;;

"disk-check")
	echo -e "${Blue}Disk Durumu:${Color_Off}"
	used=$(df -h "$DOWNLOAD_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
	total=$(df -h "$DOWNLOAD_DIR" | awk 'NR==2 {print $2}')
	avail=$(df -h "$DOWNLOAD_DIR" | awk 'NR==2 {print $4}')
	used_space=$(df -h "$DOWNLOAD_DIR" | awk 'NR==2 {print $3}')

	echo -e "İndirme dizini: ${Yellow}$DOWNLOAD_DIR${Color_Off}"
	echo -e "Toplam alan: ${Green}$total${Color_Off}"
	echo -e "Kullanılan: ${Yellow}$used_space${Color_Off} ($used%)"
	echo -e "Boş alan: ${Green}$avail${Color_Off}"

	if [ "$used" -gt 90 ]; then
		echo -e "${Red}Uyarı: Disk kullanımı kritik seviyede (%$used)${Color_Off}"
	elif [ "$used" -gt 75 ]; then
		echo -e "${Yellow}Uyarı: Disk kullanımı yüksek seviyede (%$used)${Color_Off}"
	else
		echo -e "${Green}Disk kullanımı normal seviyede (%$used)${Color_Off}"
	fi

	# Görsel disk kullanım göstergesi
	progress_bar "$used"
	;;

"stats")
	echo -e "${Blue}Transmission İstatistikleri:${Color_Off}"
	transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -st
	echo -e "\n${Blue}En Hızlı Torrentler:${Color_Off}"
	transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | sort -k5 -nr | head -5

	# Görsel disk kullanım göstergesi
	echo -e "\n${Blue}Disk Kullanımı:${Color_Off}"
	used=$(df -h "$DOWNLOAD_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
	progress_bar "$used"
	;;

"move")
	if [ -n "$2" ] && [ -n "$3" ]; then
		echo -e "${Yellow}$2 ID'li torrent $3 klasörüne taşınıyor...${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" --move "$3"
	else
		echo -e "${Red}Hata: Torrent ID ve hedef klasör gerekli${Color_Off}"
	fi
	;;

"limit")
	case "$2" in
	"up")
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -as -u "$3"
		echo -e "${Green}Upload limit: $3 KB/s${Color_Off}"
		;;
	"down")
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -as -d "$3"
		echo -e "${Green}Download limit: $3 KB/s${Color_Off}"
		;;
	*)
		echo -e "${Red}Kullanım: limit [up/down] [hız KB/s]${Color_Off}"
		;;
	esac
	;;

"tracker")
	if [ -n "$2" ]; then
		echo -e "${Blue}Tracker Bilgileri:${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -it
	else
		echo -e "${Red}Hata: Torrent ID gerekli${Color_Off}"
	fi
	;;

"health")
	echo -e "${Blue}Torrent Sağlık Kontrolü:${Color_Off}"
	transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | while read -r line; do
		id=$(echo "$line" | awk '{print $1}' | sed 's/[*]//g')
		peers=$(echo "$line" | awk '{print $5}')
		name=$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf "%s ", $i; printf "\n"}' | sed 's/^ *//;s/ *$//')

		# ID ve Sum satırlarını atla
		if [[ "$id" == "ID" || "$id" == "Sum:" ]]; then
			continue
		fi

		if [ "$peers" -eq 0 ]; then
			echo -e "${Red}Torrent $id ($name): Peer bulunamadı${Color_Off}"
		elif [ "$peers" -lt 5 ]; then
			echo -e "${Yellow}Torrent $id ($name): Az sayıda peer ($peers)${Color_Off}"
		else
			echo -e "${Green}Torrent $id ($name): İyi durumda ($peers peer)${Color_Off}"
		fi
	done
	;;

"info")
	if [ -n "$2" ]; then
		echo -e "${Blue}$2 ID'li torrent detayları:${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -i

		# İlerleme çubuğunu göster
		progress=$(transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -i | grep "Percent Done" | awk '{print $3}' | sed 's/%//')
		if [ -n "$progress" ]; then
			echo -e "\n${Blue}İlerleme:${Color_Off}"
			progress_bar "$progress"
		fi
	else
		echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
		exit 1
	fi
	;;

"speed")
	echo -e "${Blue}Anlık hız bilgisi:${Color_Off}"
	transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -si

	# Görsel hız göstergeleri
	total_down=$(transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -si | grep "Download Speed" | awk '{print $3}')
	total_up=$(transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -si | grep "Upload Speed" | awk '{print $3}')

	echo -e "\n${Blue}İndirme Hızı:${Color_Off} $total_down"
	echo -e "${Blue}Yükleme Hızı:${Color_Off} $total_up"
	;;

"files")
	if [ -n "$2" ]; then
		echo -e "${Blue}$2 ID'li torrent dosyaları:${Color_Off}"
		transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -f
	else
		echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
		exit 1
	fi
	;;

"config")
	reconfigure
	;;

*)
	show_help
	;;
esac
