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
  2. Dosya uzantısını sorar
  3. Başlangıç numarasını sorar
  4. Önizleme gösterir
  5. Kullanıcı onayı alır
  6. Orijinal dosyaları yedekler
  7. Dosyaları yeniden adlandırır

ÖRNEK KULLANIM:
  Dizin: /home/user/photos
  Uzantı: jpg
  Başlangıç: 1
  
  Sonuç:
  IMG_2023_01_15.jpg -> 1.jpg
  IMG_2023_01_16.jpg -> 2.jpg
  IMG_2023_01_17.jpg -> 3.jpg

GÜVENLİK ÖZELLİKLERİ:
  • Orijinal dosyalar yedeklenir
  • İşlem öncesi önizleme gösterilir
  • Kullanıcı onayı alınır
  • Hata durumunda geri alma imkanı
  • Geçici dosyalar otomatik temizlenir

YEDEK DOSYALAR:
  Orijinal dosyalar şu formatta yedeklenir:
  backup_YYYYMMDD_HHMMSS/

DİKKAT EDİLECEK NOKTALAR:
  • Script, belirtilen uzantıdaki TÜM dosyaları değiştirir
  • Hedef dizinde yazma izni gereklidir
  • Yeterli disk alanı olduğundan emin olun
  • İşlem geri alınamaz (yedek hariç)

HATA DURUMUNDA:
  • Yedek klasöründen dosyaları geri yükleyebilirsiniz
  • Geçici dosyalar otomatik silinir
  • Hata mesajları detaylı açıklama içerir

ÖRNEKLER:
  # Fotoğrafları yeniden adlandır
  ./rename_files.sh
  > Dizin: /home/user/photos
  > Uzantı: jpg
  > Başlangıç: 001

  # Müzik dosyalarını yeniden adlandır  
  ./rename_files.sh
  > Dizin: /home/user/music
  > Uzantı: mp3
  > Başlangıç: 1

YETKİ GEREKSİNİMLERİ:
  • Hedef dizinde okuma/yazma izni
  • Geçici dosya oluşturma izni
  • Yedek dizini oluşturma izni

DESTEKLENEN DOSYA TÜRLERI:
  Tüm dosya uzantıları desteklenir (jpg, png, mp3, txt, pdf, vb.)

SÜRÜM: 2.0
YAZAR: Geliştirilmiş Bash Script
LİSANS: MIT

Daha fazla bilgi için: https://github.com/example/rename-files
EOF
}

# Versiyon bilgisi
show_version() {
	echo "Dosya Yeniden Adlandırma Aracı v2.0"
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
echo "Dosya uzantısını girin (örn: jpg, txt, pdf):"
read -r extension

# Uzantı kontrolü
if [ -z "$extension" ]; then
	error_exit "Uzantı boş olamaz"
fi

# Belirtilen uzantıya sahip dosyaları say
file_count=$(find . -maxdepth 1 -name "*.$extension" -type f | wc -l)

if [ "$file_count" -eq 0 ]; then
	error_exit "Bu dizinde .$extension uzantılı dosya bulunamadı"
fi

echo "Bulunan .$extension dosya sayısı: $file_count"
echo

# Başlangıç numarasını al
echo "Yeniden adlandırmaya başlanacak numara (örn: 1, 100):"
read -r start_number

# Numara kontrolü
if ! is_number "$start_number"; then
	error_exit "Lütfen geçerli bir sayı girin"
fi

echo
echo "Önizleme:"
echo "=========="

# Önizleme göster
counter=$start_number
for file in *."$extension"; do
	# Dosya gerçekten var mı kontrol et (glob expansion için)
	[ -f "$file" ] || continue
	echo "$file -> $counter.$extension"
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

for file in *."$extension"; do
	# Dosya gerçekten var mı kontrol et
	[ -f "$file" ] || continue

	new_name="$counter.$extension"

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
for file in *."$extension"; do
	[ -f "$file" ] || continue
	mv "$file" "$backup_dir/"
done

# Yeni dosyaları ana dizine taşı
echo "Yeni dosyalar ana dizine taşınıyor..."
mv "$temp_dir"/*."$extension" "$target_dir/" 2>/dev/null || true

echo
echo "İşlem tamamlandı!"
echo "Yedek dosyalar: $backup_dir"
echo
echo "Sonuç:"
echo "======"
ls -la *."$extension" 2>/dev/null | sort -V || echo "Yeniden adlandırılmış dosya bulunamadı"
