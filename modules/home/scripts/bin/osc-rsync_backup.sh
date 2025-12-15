#!/usr/bin/env bash
# osc-rsync_backup.sh - rsync tabanlı yedekleme aracı
# Kaynaktan hedefe artımlı yedek alır, log ve dry-run seçenekleri içerir.

###############################################################################
# Betik Adı     : backup.sh
# Açıklama      : Bu script kullanıcının ev dizinini ($HOME) belirtilen hedef
#                 dizine rsync kullanarak yedekler. Dışlama listesi için
#                 $HOME/.rsync-homedir-excludes dosyasını kullanır.
#
# Kullanım      : ./backup.sh <hedef_dizin>
# Örnek         : ./backup.sh /mnt/archto/home
#
# Özellikler    : - Hedef dizin kontrolü
#                 - Detaylı loglama ($HOME/.log/rsync_backup.log)
#                 - Masaüstü bildirimleri (notify-send)
#                 - İlerleme bilgisi
#                 - Yedekleme süresi hesaplama
#
# Parametreler  : --del              : Hedefte fazla olan dosyaları siler
#                 --stats            : İstatistik gösterir
#                 --partial          : Yarım kalan transferleri devam ettirir
#                 --append           : Var olan dosyalara ekleme yapar
#                 --append-verify    : Ekleme sırasında doğrulama yapar
#                 --info=progress2   : Detaylı ilerleme bilgisi gösterir
#
# Yazar         : Kenan Pelit
# Tarih         : 2024
###############################################################################

# Hata durumunda scripti durdur
set -e

# Kullanım bilgisi fonksiyonu
usage() {
	echo "Kullanım: $0 <hedef_dizin>"
	echo "Not: Script $HOME dizinini yedekler."
	echo
	echo "Örnek:"
	echo "  $0 /mnt/archto/home    # /mnt/archto/home dizinine yedekle"
	echo "  $0 /hay                # /hay dizinine yedekle"
	echo "  $0 /kenp               # /kenp dizinine yedekle"
	echo "  $0 /arch/root/home     # /arch/root/home dizinine yedekle"
	exit 1
}

# Parametreleri kontrol et
if [ $# -ne 1 ]; then
	echo "Hata: Hedef dizin belirtilmedi!"
	usage
fi

# Değişkenleri tanımla
SOURCE_DIR="$HOME"
TARGET_DIR="$1"
EXCLUDE_FILE="$HOME/.rsync-homedir-excludes"
LOG_DIR="$HOME/.log"
LOG_FILE="$LOG_DIR/rsync_backup.log"

# Log dizininin varlığını kontrol et ve gerekirse oluştur
if [ ! -d "$LOG_DIR" ]; then
	mkdir -p "$LOG_DIR"
fi

# Hedef dizinin varlığını kontrol et
if [ ! -d "$TARGET_DIR" ]; then
	echo "Hata: Hedef dizin ($TARGET_DIR) bulunamadı!"
	echo "Hedef dizinin mevcut ve bağlı olduğundan emin olun."
	exit 1
fi

# Exclude dosyasının varlığını kontrol et
if [ ! -f "$EXCLUDE_FILE" ]; then
	echo "Uyarı: Dışlama listesi ($EXCLUDE_FILE) bulunamadı!"
	echo "Yedekleme tüm dosyaları içerecek şekilde devam edecek."
fi

# Yedekleme başlangıç zamanı
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Yedekleme başlatıldı bildirimi
notify-send "Yedekleme Başlatıldı" "Yedekleme işlemi başlatılıyor: $SOURCE_DIR -> $TARGET_DIR"
echo "[${START_TIME}] Yedekleme başlatıldı: $SOURCE_DIR -> $TARGET_DIR" | tee -a "$LOG_FILE"

# rsync komutu
rsync -avzhPr \
	--del \
	--stats \
	--partial \
	--append \
	--append-verify \
	--info=progress2 \
	${EXCLUDE_FILE:+--exclude-from="$EXCLUDE_FILE"} \
	"$SOURCE_DIR" \
	"$TARGET_DIR" 2>&1 | tee -a "$LOG_FILE"

# Yedekleme bitiş zamanı
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Yedekleme tamamlandı bildirimi
notify-send "Yedekleme Tamamlandı" "Yedekleme işlemi başarıyla tamamlandı: $TARGET_DIR"
echo "[${END_TIME}] Yedekleme tamamlandı: $SOURCE_DIR -> $TARGET_DIR" | tee -a "$LOG_FILE"

# Yedekleme süresini hesapla ve kaydet
START_SECONDS=$(date -d "$START_TIME" +%s)
END_SECONDS=$(date -d "$END_TIME" +%s)
DURATION=$((END_SECONDS - START_SECONDS))
DURATION_FORMAT=$(date -u -d @${DURATION} +"%H:%M:%S")
echo "[${END_TIME}] Toplam süre: ${DURATION_FORMAT}" | tee -a "$LOG_FILE"
echo "----------------------------------------" >>"$LOG_FILE"
