#!/usr/bin/env bash
#
#   Date: 2025-04-11
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   monitor_brightness.sh - Dell UP2716D harici monitör parlaklık kontrolü
#

# Yapılandırma - Dell monitörünüz için doğru bus
I2C_BUS="7" # Dell UP2716D monitörünüz için sabit bus numarası
NOTIFY_TIMEOUT=1500
MONITOR_NAME="DELL UP2716D"

# Hata mesajı iletişimi
show_error() {
	echo "HATA: $1" >&2
	notify-send -t 3000 -u critical "Monitör Parlaklık Hatası" "$1" 2>/dev/null || true
	exit 1
}

# Kullanımı göster
show_usage() {
	echo "Kullanım: $0 [SEÇENEK]"
	echo
	echo "Seçenekler:"
	echo "  [0-100]       Parlaklığı belirtilen yüzdeye ayarla"
	echo "  +N            Parlaklığı N% arttır (ör: +5)"
	echo "  -N            Parlaklığı N% azalt (ör: -5)"
	echo "  g, get        Mevcut parlaklığı göster"
	echo "  d, detect     Bağlı monitörleri algıla ve göster"
	echo "  c, check      Kontrol edilebilen monitör değerlerini göster"
	echo "  h, help       Bu yardım mesajını göster"
	echo
	echo "Örnekler:"
	echo "  $0 70         Parlaklığı %70'e ayarla"
	echo "  $0 +10        Parlaklığı %10 arttır"
	echo "  $0 -15        Parlaklığı %15 azalt"
	echo "  $0 g          Mevcut parlaklığı göster"
	echo "  $0 d          Bağlı monitörleri algıla"
}

# Mevcut parlaklığı al
get_brightness() {
	ddcutil --bus "$I2C_BUS" getvcp 10 2>/dev/null | grep -oP 'current value =\s*\K\d+' || echo "-1"
}

# Parlaklık gösterge çubuğu - ASCII
show_brightness_bar() {
	local brightness=$1
	local bar_width=20
	local filled_width=$((brightness * bar_width / 100))
	local empty_width=$((bar_width - filled_width))

	printf "["
	printf "%${filled_width}s" | tr ' ' '#'
	printf "%${empty_width}s" | tr ' ' '-'
	printf "] %d%%\n" "$brightness"
}

# Bağlı monitörleri göster
detect_monitors() {
	echo "Bağlı monitörleri algılama..."

	if ddcutil detect; then
		echo "Algılama tamamlandı."
	else
		show_error "Monitörleri algılarken hata oluştu."
	fi
}

# Kontrol edilebilen monitör değerlerini göster
check_monitor() {
	echo "Dell monitörünün ($MONITOR_NAME) mevcut değerleri kontrol ediliyor..."
	echo "I2C Bus: $I2C_BUS"

	if ddcutil --bus "$I2C_BUS" getvcp 10; then
		echo "Kontrol tamamlandı."
	else
		show_error "Monitör değerlerini kontrol ederken hata oluştu."
	fi
}

# Parlaklığı ayarla
set_brightness() {
	local brightness=$1

	echo "Dell Monitör parlaklık değeri %$brightness olarak ayarlanıyor..."
	if ddcutil --bus "$I2C_BUS" setvcp 10 "$brightness"; then
		echo "Parlaklık %$brightness olarak ayarlandı."
		echo "Monitör: $MONITOR_NAME (I2C bus: $I2C_BUS)"
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

	if [ "$current" = "-1" ]; then
		show_error "Mevcut parlaklık okunamadı. Monitörünüzün bağlı olduğundan emin olun."
		exit 1
	fi

	# Yeni değeri hesapla
	local new_value=$((current + adjustment))

	# Aralık içinde kaldığından emin ol
	if [ "$new_value" -lt 0 ]; then
		new_value=0
	elif [ "$new_value" -gt 100 ]; then
		new_value=100
	fi

	# Yeni değeri ayarla
	set_brightness "$new_value"
}

# Ana program
main() {
	# Parametre yok ise kullanımı göster
	if [ $# -eq 0 ]; then
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
		current=$(get_brightness)
		if [ "$current" = "-1" ]; then
			show_error "Monitör parlaklığı okunamadı. Monitörünüzün bağlı olduğundan emin olun."
		fi
		echo "Dell Monitör - Mevcut parlaklık: %$current"
		show_brightness_bar "$current"
		notify-send -t "$NOTIFY_TIMEOUT" "Dell Monitör Parlaklığı" "Mevcut: %$current" 2>/dev/null || true
		;;

	# Monitörleri algıla
	"d" | "detect")
		detect_monitors
		;;

	# Monitör değerlerini kontrol et
	"c" | "check")
		check_monitor
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
		if [ "$1" -le 100 ]; then
			set_brightness "$1"
		else
			echo "Hata: Parlaklık değeri 0-100 arasında olmalıdır."
			exit 1
		fi
		;;

	# Geçersiz seçenek
	*)
		echo "Geçersiz argüman: $1"
		show_usage
		exit 1
		;;
	esac
}

# Programı çalıştır
main "$@"
