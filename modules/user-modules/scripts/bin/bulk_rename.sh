#!/usr/bin/env bash

# Hata durumunda script'i durdur
set -e

# Help fonksiyonu
show_help() {
	cat <<'EOF'
=== DOSYA YENİDEN ADLANDIRMA ARACI ===

Bu script, belirtilen dizindeki aynı uzantılı dosyaları ardışık sayılarla yeniden adlandırır.

KULLANIM:
  ./rename_files.sh [SEÇENEKLER]

SEÇENEKLER:
  -h, --help     Bu yardım mesajını göster
  -v, --version  Versiyon bilgisini göster

ÇALIŞMA PRENSİBİ:
  1. Hedef dizin yolunu sorar
  2. Dosya uzantısını sorar (birden fazla uzantı desteklenir)
  3. Başlangıç numarasını sorar (otomatik sıfırla doldurur)
  4. Önizleme gösterir
  5. Kullanıcı onayı alır
  6. Orijinal dosyaları yedekler
  7. Dosyaları yeniden adlandırır

ÖRNEK KULLANIM:
  Dizin: /home/user/photos
  Uzantı: jpg,png,jpeg (veya sadece jpg)
  Başlangıç: 1
  
  Sonuç:
  IMG_2023_01_15.jpg -> 01.jpg
  IMG_2023_01_16.png -> 02.png  
  IMG_2023_01_17.jpeg -> 03.jpeg

GÜVENLİK ÖZELLİKLERİ:
  • Orijinal dosyalar yedeklenir
  • İşlem öncesi önizleme gösterilir
  • Kullanıcı onayı alınır
  • Hata durumunda geri alma imkanı
  • Geçici dosyalar otomatik temizlenir

YEDEK DOSYALAR:
  Orijinal dosyalar şu formatta yedeklenir:
  backup_YYYYMMDD_HHMMSS/

DESTEKLENEN UZANTI FORMATLARI:
  • Tek uzantı: jpg
  • Çoklu uzantı: jpg,png,jpeg
  • Boşluklu: jpg, png, jpeg

SÜRÜM: 2.1
YAZAR: Geliştirilmiş Bash Script
LİSANS: MIT
EOF
}

# Versiyon bilgisi
show_version() {
	echo "Dosya Yeniden Adlandırma Aracı v2.1"
	echo "Bash Script - Gelişmiş Sürüm"
	echo "Copyright (c) 2024"
}

# Komut satırı argümanlarını kontrol et
case "${1:-}" in
-h | --help)
	show_help
	exit 0
	;;
-v | --version)
	show_version
	exit 0
	;;
-*)
	echo "Bilinmeyen seçenek: $1"
	echo "Yardım için: $0 --help"
	exit 1
	;;
esac

# Fonksiyon: Hata mesajı göster ve çık
error_exit() {
	echo "HATA: $1" >&2
	exit 1
}

# Fonksiyon: Dizin var mı kontrol et
check_directory() {
	if [ ! -d "$1" ]; then
		error_exit "Dizin mevcut değil: $1"
	fi
}

# Fonksiyon: Sayı kontrolü
is_number() {
	[[ $1 =~ ^[0-9]+$ ]]
}

# Fonksiyon: Uzantıları parse et
parse_extensions() {
	local input="$1"
	# Virgül ve boşluklarla ayır, boş olanları filtrele
	echo "$input" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'
}

# Fonksiyon: Belirtilen uzantılardaki dosyaları bul
find_files_by_extensions() {
	local extensions=("$@")
	local find_args=()

	# Her uzantı için -name parametresi ekle
	for ext in "${extensions[@]}"; do
		if [ ${#find_args[@]} -gt 0 ]; then
			find_args+=("-o")
		fi
		find_args+=("-name" "*.$ext")
	done

	# find komutunu çalıştır
	find . -maxdepth 1 -type f \( "${find_args[@]}" \) 2>/dev/null | sort
}

# Fonksiyon: Dosya sayısını say
count_files_by_extensions() {
	local extensions=("$@")
	find_files_by_extensions "${extensions[@]}" | wc -l
}

echo "=== Dosya Yeniden Adlandırma Aracı ==="
echo

# Kullanıcıdan yeniden adlandırma yapılacak dizinin tam yolunu al
echo "Yeniden adlandırma yapılacak dizinin tam yolunu girin:"
read -e -r target_dir

# Dizin kontrolü
check_directory "$target_dir"

# Dizine git
cd "$target_dir" || error_exit "Dizine gidilemedi: $target_dir"

echo "Mevcut dizin: $(pwd)"
echo

# Dosya uzantısını al
echo "Dosya uzantısı(ları)nı girin:"
echo "Örnekler:"
echo "  - Tek uzantı: jpg"
echo "  - Çoklu uzantı: jpg,png,jpeg"
echo "  - Boşluklu: jpg, png, jpeg"
read -r extension_input

# Uzantı kontrolü
if [ -z "$extension_input" ]; then
	error_exit "Uzantı boş olamaz"
fi

# Uzantıları parse et
mapfile -t extensions < <(parse_extensions "$extension_input")

if [ ${#extensions[@]} -eq 0 ]; then
	error_exit "Geçerli uzantı bulunamadı"
fi

echo "İşlenecek uzantılar: ${extensions[*]}"

# Belirtilen uzantıya sahip dosyaları say
file_count=$(count_files_by_extensions "${extensions[@]}")

if [ "$file_count" -eq 0 ]; then
	error_exit "Bu dizinde belirtilen uzantılı dosya bulunamadı: ${extensions[*]}"
fi

echo "Bulunan dosya sayısı: $file_count"
echo

# Başlangıç numarasını al
echo "Yeniden adlandırmaya başlanacak numara (örn: 1, 100):"
read -r start_number

# Numara kontrolü
if ! is_number "$start_number"; then
	error_exit "Lütfen geçerli bir sayı girin"
fi

# Sıfır padding uzunluğunu hesapla
total_digits=${#file_count}
if [ $total_digits -lt 2 ]; then
	total_digits=2
fi

echo
echo "Önizleme (sıfırla doldurma: $total_digits haneli):"
echo "=================================================="

# Dosya sıralama seçenekleri
echo "Dosya sıralama seçenekleri:"
echo "1) Alfabetik sıra (varsayılan)"
echo "2) Rastgele karıştır"
echo "3) Dosya boyutuna göre (küçükten büyüğe)"
echo "4) Değişiklik tarihine göre (eskiden yeniye)"
read -p "Seçiminiz (1-4, varsayılan: 1): " sort_option

# Dosyaları al ve sırala
mapfile -t all_files < <(find_files_by_extensions "${extensions[@]}")

case "${sort_option:-1}" in
1)
	echo "Alfabetik sıralama kullanılıyor..."
	mapfile -t all_files < <(printf '%s\n' "${all_files[@]}" | sort)
	;;
2)
	echo "Rastgele karıştırılıyor..."
	mapfile -t all_files < <(printf '%s\n' "${all_files[@]}" | shuf)
	;;
3)
	echo "Dosya boyutuna göre sıralanıyor..."
	mapfile -t all_files < <(printf '%s\n' "${all_files[@]}" | xargs ls -lS | awk 'NR>1 {print $NF}')
	;;
4)
	echo "Değişiklik tarihine göre sıralanıyor..."
	mapfile -t all_files < <(printf '%s\n' "${all_files[@]}" | xargs ls -lt | awk 'NR>1 {print $NF}')
	;;
*)
	echo "Geçersiz seçenek, alfabetik sıra kullanılıyor..."
	mapfile -t all_files < <(printf '%s\n' "${all_files[@]}" | sort)
	;;
esac

# Önizleme göster
counter=$start_number

for file_path in "${all_files[@]}"; do
	file=$(basename "$file_path")
	# Dosya gerçekten var mı kontrol et
	[ -f "$file" ] || continue

	# Orijinal uzantıyı koru
	original_ext="${file##*.}"

	# Sıfırla doldurulmuş numara oluştur
	padded_number=$(printf "%0${total_digits}d" $counter)
	new_name="$padded_number.$original_ext"

	echo "$file -> $new_name"
	counter=$((counter + 1))
done

echo
echo "Bu işlem yukarıdaki dosyaları yeniden adlandıracak."
echo "Devam etmek istiyor musunuz? (y/N):"
read -r confirmation

if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
	echo "İşlem iptal edildi."
	exit 0
fi

echo
echo "Yeniden adlandırma başlıyor..."

# Geçici dizin oluştur
temp_dir=$(mktemp -d -p "$target_dir" rename_temp_XXXXXX)
echo "Geçici dizin: $temp_dir"

# Temizlik fonksiyonu
cleanup() {
	if [ -d "$temp_dir" ]; then
		echo "Geçici dizin temizleniyor..."
		rm -rf "$temp_dir"
	fi
}

# Script çıkışında temizlik yap
trap cleanup EXIT

# Dosyaları geçici dizine taşı ve yeniden adlandır
counter=$start_number
success_count=0

for file_path in "${all_files[@]}"; do
	file=$(basename "$file_path")
	# Dosya gerçekten var mı kontrol et
	[ -f "$file" ] || continue

	# Orijinal uzantıyı koru
	original_ext="${file##*.}"

	# Sıfırla doldurulmuş numara oluştur
	padded_number=$(printf "%0${total_digits}d" $counter)
	new_name="$padded_number.$original_ext"

	# Dosyayı geçici dizine kopyala (güvenlik için)
	if cp "$file" "$temp_dir/$new_name"; then
		echo "✓ $file -> $new_name"
		success_count=$((success_count + 1))
		counter=$((counter + 1))
	else
		echo "✗ HATA: $file kopyalanamadı"
	fi
done

echo
echo "Yeniden adlandırma tamamlandı. Başarılı: $success_count/$file_count"

# Orijinal dosyaları yedekle
backup_dir="$target_dir/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

echo "Orijinal dosyalar yedekleniyor: $backup_dir"
for file_path in "${all_files[@]}"; do
	file=$(basename "$file_path")
	[ -f "$file" ] || continue
	mv "$file" "$backup_dir/"
done

# Yeni dosyaları ana dizine taşı
echo "Yeni dosyalar ana dizine taşınıyor..."
mv "$temp_dir"/* "$target_dir/" 2>/dev/null || true

echo
echo "İşlem tamamlandı!"
echo "Yedek dosyalar: $backup_dir"
echo
echo "Sonuç:"
echo "======"

# Sonuçları göster
for ext in "${extensions[@]}"; do
	if ls *."$ext" >/dev/null 2>&1; then
		ls -la *."$ext" | sort -V
	fi
done
