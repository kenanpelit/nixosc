#!/usr/bin/env bash
#
#   Date: 2025-06-10
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   monitor_brightness.sh - Dell UP2716D harici monitör parlaklık kontrolü (Otomatik Algılama)
#

# Yapılandırma
MONITOR_NAME="DELL UP2716D"
NOTIFY_TIMEOUT=1500
CACHE_FILE="/tmp/monitor_brightness_cache"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Hata mesajı iletişimi
show_error() {
	echo -e "${RED}HATA: $1${RESET}" >&2
	notify-send -t 3000 -u critical "Monitör Parlaklık Hatası" "$1" 2>/dev/null || true
	exit 1
}

# Bilgi mesajı
show_info() {
	echo -e "${BLUE}INFO: $1${RESET}"
}

# Başarı mesajı
show_success() {
	echo -e "${GREEN}BAŞARI: $1${RESET}"
}

# Uyarı mesajı
show_warning() {
	echo -e "${YELLOW}UYARI: $1${RESET}"
}

# Kullanımı göster
show_usage() {
	echo -e "${CYAN}Kullanım: $0 [SEÇENEK]${RESET}"
	echo
	echo "Seçenekler:"
	echo "  [0-100]       Parlaklığı belirtilen yüzdeye ayarla"
	echo "  +N            Parlaklığı N% arttır (ör: +5)"
	echo "  -N            Parlaklığı N% azalt (ör: -5)"
	echo "  g, get        Mevcut parlaklığı göster"
	echo "  d, detect     Bağlı monitörleri algıla ve göster"
	echo "  s, scan       Monitörleri tara ve cache'le"
	echo "  c, check      Kontrol edilebilen monitör değerlerini göster"
	echo "  i, info       Monitör bilgilerini göster"
	echo "  debug, test   Hata ayıklama ve tanı bilgileri"
	echo "  scan-all      Tüm bus'ları test et ve çalışanı bul"
	echo "  test-bus N    Belirli bus numarasını test et"
	echo "  force-bus N X Bus N ile zorla parlaklığı X'e ayarla"
	echo "  r, reset      Cache'i temizle ve yeniden tara"
	echo "  h, help       Bu yardım mesajını göster"
	echo
	echo "Örnekler:"
	echo "  $0 70         Parlaklığı %70'e ayarla"
	echo "  $0 +10        Parlaklığı %10 arttır"
	echo "  $0 -15        Parlaklığı %15 azalt"
	echo "  $0 g          Mevcut parlaklığı göster"
	echo "  $0 s          Monitörleri tara"
}

# Monitörleri algıla ve en uygun bus'ı bul
detect_and_find_monitor() {
	show_info "Monitörler algılanıyor..."

	# ddcutil'in mevcut olup olmadığını kontrol et
	if ! command -v ddcutil &>/dev/null; then
		show_error "ddcutil komutu bulunamadı. Lütfen ddcutil'i yükleyin."
	fi

	show_info "ddcutil versiyonu: $(ddcutil --version 2>/dev/null | head -1 || echo 'Bilinmiyor')"

	# Monitörleri algıla
	local detect_output
	local detect_error
	if ! detect_output=$(ddcutil detect 2>&1); then
		detect_error="$detect_output"
		show_error "ddcutil detect başarısız oldu. Hata: $detect_error"
	fi

	# Çıktıyı kontrol et
	if [[ -z "$detect_output" || "$detect_output" == *"No displays found"* ]]; then
		show_error "Hiçbir monitör bulunamadı. ddcutil detect boş sonuç döndü."
	fi

	echo -e "${PURPLE}Algılanan Monitörler:${RESET}"
	echo "$detect_output"
	echo

	# Dell monitörünü ara
	local dell_bus=""
	local dell_model=""

	# Her satırı işle
	while IFS= read -r line; do
		# Bus numarasını ara
		if [[ "$line" =~ Display\ ([0-9]+) ]]; then
			current_bus="${BASH_REMATCH[1]}"
		fi

		# Dell modelini ara
		if [[ "$line" =~ Model:.*DELL.*UP2716D ]] || [[ "$line" =~ Model:.*Dell.*UP2716D ]]; then
			dell_bus="$current_bus"
			dell_model=$(echo "$line" | grep -o "Model:.*" | cut -d: -f2- | xargs)
			break
		fi

		# Genel Dell monitörü ara (spesifik model bulunamazsa)
		if [[ -z "$dell_bus" && ("$line" =~ Model:.*DELL || "$line" =~ Model:.*Dell) ]]; then
			dell_bus="$current_bus"
			dell_model=$(echo "$line" | grep -o "Model:.*" | cut -d: -f2- | xargs)
		fi
	done <<<"$detect_output"

	if [[ -n "$dell_bus" ]]; then
		show_success "Dell monitör bulundu!"
		echo -e "  ${GREEN}Bus: $dell_bus${RESET}"
		echo -e "  ${GREEN}Model: $dell_model${RESET}"

		# Cache'e kaydet
		echo "$dell_bus" >"$CACHE_FILE"
		return 0
	else
		show_warning "Dell UP2716D monitör bulunamadı."
		echo
		show_info "Bulunan tüm monitörler:"

		# Tüm monitörleri listele
		local bus_number=""
		while IFS= read -r line; do
			if [[ "$line" =~ Display\ ([0-9]+) ]]; then
				bus_number="${BASH_REMATCH[1]}"
			elif [[ "$line" =~ Model: ]]; then
				local model=$(echo "$line" | cut -d: -f2- | xargs)
				echo -e "  ${CYAN}Bus $bus_number: $model${RESET}"
			fi
		done <<<"$detect_output"

		echo
		echo -e "${YELLOW}Manuel olarak bus numarası belirtmek isterseniz:${RESET}"
		echo "  Bu script'i düzenleyip I2C_BUS değişkenini güncelleyin"
		return 1
	fi
}

# Cache'den bus numarasını al
get_cached_bus() {
	if [[ -f "$CACHE_FILE" ]]; then
		cat "$CACHE_FILE"
	else
		echo ""
	fi
}

# Monitör bus numarasını al (cache'den veya algılayarak)
get_monitor_bus() {
	local cached_bus=$(get_cached_bus)

	# Cache'de bus varsa önce onu test et
	if [[ -n "$cached_bus" ]]; then
		if test_bus_connection "$cached_bus"; then
			echo "$cached_bus"
			return 0
		else
			show_warning "Cache'deki bus ($cached_bus) artık çalışmıyor, yeniden algılanıyor..."
			rm -f "$CACHE_FILE"
		fi
	fi

	# Yeniden algıla
	if detect_and_find_monitor; then
		get_cached_bus
	else
		echo ""
	fi
}

# Bus bağlantısını test et
test_bus_connection() {
	local bus="$1"
	ddcutil --bus "$bus" getvcp 10 &>/dev/null
}

# Mevcut parlaklığı al
get_brightness() {
	local bus=$(get_monitor_bus)

	if [[ -z "$bus" ]]; then
		show_error "Monitör bulunamadı veya erişilemiyor."
	fi

	local brightness
	brightness=$(ddcutil --bus "$bus" getvcp 10 2>/dev/null | grep -oP 'current value =\s*\K\d+')

	if [[ -z "$brightness" ]]; then
		echo "-1"
	else
		echo "$brightness"
	fi
}

# Parlaklık gösterge çubuğu - ASCII
show_brightness_bar() {
	local brightness=$1
	local bar_width=20
	local filled_width=$((brightness * bar_width / 100))
	local empty_width=$((bar_width - filled_width))

	printf "["
	printf "%${filled_width}s" | tr ' ' '█'
	printf "%${empty_width}s" | tr ' ' '░'
	printf "] %d%%\n" "$brightness"
}

# Bağlı monitörleri göster
detect_monitors() {
	show_info "Tüm bağlı monitörler algılanıyor..."
	echo

	if ddcutil detect; then
		show_success "Algılama tamamlandı."
	else
		show_error "Monitörleri algılarken hata oluştu."
	fi
}

# Monitörleri tara ve cache'le
scan_monitors() {
	show_info "Monitörler taranıyor ve cache'leniyor..."
	rm -f "$CACHE_FILE" # Eski cache'i temizle

	if detect_and_find_monitor; then
		show_success "Tarama tamamlandı ve cache'lendi."
	else
		show_error "Uygun monitör bulunamadı."
	fi
}

# Kontrol edilebilen monitör değerlerini göster
check_monitor() {
	local bus=$(get_monitor_bus)

	if [[ -z "$bus" ]]; then
		show_error "Monitör bulunamadı."
	fi

	show_info "Dell monitörünün mevcut değerleri kontrol ediliyor..."
	echo -e "${CYAN}I2C Bus: $bus${RESET}"
	echo

	if ddcutil --bus "$bus" getvcp 10; then
		show_success "Kontrol tamamlandı."
	else
		show_error "Monitör değerlerini kontrol ederken hata oluştu."
	fi
}

# Monitör bilgilerini göster
show_monitor_info() {
	local bus=$(get_monitor_bus)

	if [[ -z "$bus" ]]; then
		show_error "Monitör bulunamadı."
	fi

	show_info "Monitör bilgileri:"
	echo -e "${CYAN}I2C Bus: $bus${RESET}"
	echo -e "${CYAN}Hedef Model: $MONITOR_NAME${RESET}"
	echo

	show_info "Mevcut parlaklık durumu:"
	local current=$(get_brightness)
	if [[ "$current" != "-1" ]]; then
		echo -e "${GREEN}Parlaklık: %$current${RESET}"
		show_brightness_bar "$current"
	else
		show_error "Parlaklık okunamadı."
	fi
}

# Parlaklığı ayarla
set_brightness() {
	local brightness=$1
	local bus=$(get_monitor_bus)

	if [[ -z "$bus" ]]; then
		show_error "Monitör bulunamadı."
	fi

	show_info "Dell Monitör parlaklık değeri %$brightness olarak ayarlanıyor..."

	if ddcutil --bus "$bus" setvcp 10 "$brightness" 2>/dev/null; then
		show_success "Parlaklık %$brightness olarak ayarlandı."
		echo -e "${CYAN}Monitör: $MONITOR_NAME (I2C bus: $bus)${RESET}"
		show_brightness_bar "$brightness"
		notify-send -t "$NOTIFY_TIMEOUT" "Monitör Parlaklığı" "Dell Monitör: %$brightness" 2>/dev/null || true
	else
		show_error "Parlaklık değiştirilemedi. Dell monitörünüzün bağlı olduğundan emin olun."
	fi
}

# Parlaklığı arttır/azalt
adjust_brightness() {
	local adjustment=$1

	# Mevcut parlaklığı al
	local current=$(get_brightness)

	if [[ "$current" = "-1" ]]; then
		show_error "Mevcut parlaklık okunamadı. Monitörünüzün bağlı olduğundan emin olun."
	fi

	# Yeni değeri hesapla
	local new_value=$((current + adjustment))

	# Aralık içinde kaldığından emin ol
	if [[ "$new_value" -lt 0 ]]; then
		new_value=0
	elif [[ "$new_value" -gt 100 ]]; then
		new_value=100
	fi

	# Değişiklik olup olmadığını kontrol et
	if [[ "$new_value" -eq "$current" ]]; then
		show_info "Parlaklık zaten hedef değerde (%$current)."
		return 0
	fi

	# Yeni değeri ayarla
	set_brightness "$new_value"
}

# Cache'i temizle
reset_cache() {
	show_info "Cache temizleniyor..."
	rm -f "$CACHE_FILE"
	show_success "Cache temizlendi."

	show_info "Yeniden tarama yapılıyor..."
	scan_monitors
}

# Ana program
main() {
	# Parametre yok ise kullanımı göster
	if [[ $# -eq 0 ]]; then
		show_usage
		exit 0
	fi

	# Komut satırı argümanlarını işle
	case "$1" in
	# Yardım göster
	"h" | "help")
		show_usage
		;;

	# Mevcut parlaklığı göster
	"g" | "get")
		local current=$(get_brightness)
		if [[ "$current" = "-1" ]]; then
			show_error "Monitör parlaklığı okunamadı."
		fi
		echo -e "${GREEN}Dell Monitör - Mevcut parlaklık: %$current${RESET}"
		show_brightness_bar "$current"
		notify-send -t "$NOTIFY_TIMEOUT" "Dell Monitör Parlaklığı" "Mevcut: %$current" 2>/dev/null || true
		;;

	# Monitörleri algıla
	"d" | "detect")
		detect_monitors
		;;

	# Monitörleri tara ve cache'le
	"s" | "scan")
		scan_monitors
		;;

	# Monitör değerlerini kontrol et
	"c" | "check")
		check_monitor
		;;

	# Monitör bilgilerini göster
	"i" | "info")
		show_monitor_info
		;;

	# Tüm bus'ları test et
	"scan-all" | "test-all")
		show_info "Tüm I2C bus'ları test ediliyor..."
		echo

		for bus in {2..15}; do
			if [[ -e "/dev/i2c-$bus" ]]; then
				echo -e "${CYAN}=== Bus $bus Test ===${RESET}"

				# Bus adını göster
				local bus_name=""
				if [[ -f "/sys/bus/i2c/devices/i2c-$bus/name" ]]; then
					bus_name=$(cat "/sys/bus/i2c/devices/i2c-$bus/name")
					echo -e "${PURPLE}Bus Name: $bus_name${RESET}"
				fi

				# DDC test
				if timeout 5 sudo ddcutil --bus "$bus" getvcp 10 2>/dev/null; then
					show_success "Bus $bus: DDC ÇALIŞIYOR!"
					echo "$bus" >"$CACHE_FILE"
					echo -e "${GREEN}Bu bus cache'lendi.${RESET}"
					echo
					break
				else
					show_warning "Bus $bus: DDC çalışmıyor"
				fi
				echo
			fi
		done
		;;

	# Manuel bus test
	"test-bus")
		if [[ -z "$2" ]]; then
			show_error "Bus numarası belirtmelisiniz. Örnek: $0 test-bus 14"
		fi
		local test_bus="$2"
		show_info "Bus $test_bus test ediliyor..."
		echo

		show_info "Detect test:"
		sudo ddcutil --bus "$test_bus" detect || show_warning "Detect başarısız"
		echo

		show_info "VCP 10 (brightness) test:"
		sudo ddcutil --bus "$test_bus" getvcp 10 || show_warning "Brightness read başarısız"
		echo

		show_info "Manuel brightness set test (50%):"
		read -p "Parlaklığı %50'ye ayarlamayı denemek ister misiniz? (y/N): " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			sudo ddcutil --bus "$test_bus" setvcp 10 50 && show_success "Brightness set başarılı!"
		fi
		;;

	# Force bus kullanımı
	"force-bus")
		if [[ -z "$2" || -z "$3" ]]; then
			show_error "Kullanım: $0 force-bus BUS_NO BRIGHTNESS"
			show_error "Örnek: $0 force-bus 14 70"
		fi
		local force_bus="$2"
		local brightness="$3"

		show_info "Bus $force_bus ile zorla parlaklık %$brightness ayarlanıyor..."
		if sudo ddcutil --bus "$force_bus" setvcp 10 "$brightness"; then
			show_success "Parlaklık başarıyla ayarlandı!"

			# Cache'e kaydet
			echo "$force_bus" >"$CACHE_FILE"
			show_info "Bus $force_bus cache'lendi"
		else
			show_error "Parlaklık ayarlanamadı"
		fi
		;;

	# Hata ayıklama ve tanı
	"debug" | "test")
		show_info "Hata ayıklama ve tanı bilgileri:"
		echo

		# ddcutil kurulu mu?
		if command -v ddcutil &>/dev/null; then
			show_success "ddcutil kurulu"
			echo -e "${CYAN}Versiyon: $(ddcutil --version 2>/dev/null | head -1 || echo 'Alınamadı')${RESET}"
		else
			show_error "ddcutil kurulu değil"
		fi

		# i2c modülleri yüklü mü?
		show_info "I2C modül durumu:"
		lsmod | grep i2c || show_warning "I2C modülleri bulunamadı"
		echo

		# /dev/i2c* cihazları var mı?
		show_info "I2C cihazları:"
		ls -la /dev/i2c* 2>/dev/null || show_warning "I2C cihazları bulunamadı"
		echo

		# ddcutil environment kontrol
		show_info "ddcutil environment:"
		ddcutil environment 2>/dev/null || show_warning "ddcutil environment çalışmadı"
		echo

		# Basit detect deneme
		show_info "ddcutil detect test (hata çıktısı ile):"
		ddcutil detect 2>&1 || show_warning "ddcutil detect başarısız"
		;;

	# Cache'i temizle ve yeniden tara
	"r" | "reset")
		reset_cache
		;;

	# Parlaklığı arttır
	+[0-9]*)
		adjustment="${1:1}" # + işaretini kaldır
		adjust_brightness "$adjustment"
		;;

	# Parlaklığı azalt
	-[0-9]*)
		adjustment="${1:1}" # - işaretini kaldır
		adjust_brightness "-$adjustment"
		;;

	# Parlaklığı ayarla
	[0-9]*)
		if [[ "$1" -le 100 ]]; then
			set_brightness "$1"
		else
			show_error "Parlaklık değeri 0-100 arasında olmalıdır."
		fi
		;;

	# Geçersiz seçenek
	*)
		show_error "Geçersiz argüman: $1"
		show_usage
		;;
	esac
}

# Programı çalıştır
main "$@"
