#!/usr/bin/env bash

# Video Kesme Script'i
# Kullanım: ./videokes.sh input.mp4

VIDEO_FILE="$1"
OUTPUT_DIR="kesitler"

# Çıktı klasörünü oluştur
mkdir -p "$OUTPUT_DIR"

if [ -z "$VIDEO_FILE" ]; then
	echo "Kullanım: $0 <video_dosyası>"
	echo "Örnek: $0 8_sinif_bir_kahraman_doguyor.mp4"
	exit 1
fi

if [ ! -f "$VIDEO_FILE" ]; then
	echo "Hata: '$VIDEO_FILE' dosyası bulunamadı!"
	exit 1
fi

# Dosya adını al (uzantısız)
BASENAME=$(basename "$VIDEO_FILE" .mp4)

echo "=== Video Kesme Menüsü ==="
echo "1) İlk X saniyeyi atla, kalanını al"
echo "2) Sadece ilk X dakika/saniyeyi al"
echo "3) Belirli aralığı kes (başlangıç-bitiş)"
echo "4) Video ortasından kesit al"
echo "5) Birden fazla aralığı kes"
echo "6) Video bilgilerini göster"
echo "7) TOPLU İŞLEM: Dizindeki tüm MP4'lerin ilk X saniyesini atla"
echo ""
read -p "Seçiminizi yapın (1-7): " CHOICE

case $CHOICE in
1)
	read -p "Kaç saniye atlanacak? (örnek: 14): " SKIP_SEC
	OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}_${SKIP_SEC}s_sonrasi.mp4"
	echo "İşleniyor: İlk $SKIP_SEC saniye atlanıyor..."
	ffmpeg -i "$VIDEO_FILE" -ss $SKIP_SEC -c copy "$OUTPUT_FILE"
	echo "Tamamlandı: $OUTPUT_FILE"
	;;
2)
	read -p "Kaç dakika alınacak? (örnek: 10 veya 5.5): " DURATION
	OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}_ilk_${DURATION}dk.mp4"
	echo "İşleniyor: İlk $DURATION dakika alınıyor..."
	ffmpeg -i "$VIDEO_FILE" -t $(echo "$DURATION * 60" | bc):00 -c copy "$OUTPUT_FILE"
	echo "Tamamlandı: $OUTPUT_FILE"
	;;
3)
	read -p "Başlangıç zamanı (DD:SS veya DD:MM:SS): " START_TIME
	read -p "Bitiş zamanı (DD:SS veya DD:MM:SS): " END_TIME
	OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}_${START_TIME//:/}-${END_TIME//:/}.mp4"
	echo "İşleniyor: $START_TIME - $END_TIME arası kesiliyor..."
	ffmpeg -i "$VIDEO_FILE" -ss "$START_TIME" -to "$END_TIME" -c copy "$OUTPUT_FILE"
	echo "Tamamlandı: $OUTPUT_FILE"
	;;
4)
	echo "Video ortasından kesit alma:"
	echo "Örnek format: 00:00:14 (14. saniye) veya 01:01:24 (1 saat 1 dakika 24 saniye)"
	read -p "Başlangıç zamanı (HH:MM:SS veya MM:SS): " START_TIME
	read -p "Bitiş zamanı (HH:MM:SS veya MM:SS): " END_TIME
	# Dosya adı için zamanları temizle
	START_CLEAN=$(echo "$START_TIME" | sed 's/:/_/g')
	END_CLEAN=$(echo "$END_TIME" | sed 's/:/_/g')
	OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}_${START_CLEAN}_to_${END_CLEAN}.mp4"
	echo "İşleniyor: $START_TIME - $END_TIME arası kesiliyor..."
	ffmpeg -i "$VIDEO_FILE" -ss "$START_TIME" -to "$END_TIME" -c copy "$OUTPUT_FILE"
	echo "Tamamlandı: $OUTPUT_FILE"
	# Kesit süresini hesapla ve göster
	echo ""
	echo "Kesit bilgileri:"
	echo "Başlangıç: $START_TIME"
	echo "Bitiş: $END_TIME"
	ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT_FILE" | awk '{printf "Süre: %.0f saniye (%.1f dakika)\n", $1, $1/60}'
	;;
5)
	echo "Birden fazla aralık kesimi:"
	echo "Format: başlangıç-bitiş (örnek: 01:30-03:45)"
	echo "Bitirmek için boş bırakın"
	COUNTER=1
	while true; do
		read -p "Aralık $COUNTER (başlangıç-bitiş): " RANGE
		if [ -z "$RANGE" ]; then
			break
		fi
		START_TIME=$(echo "$RANGE" | cut -d'-' -f1)
		END_TIME=$(echo "$RANGE" | cut -d'-' -f2)
		OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}_kesit_${COUNTER}.mp4"
		echo "İşleniyor: Kesit $COUNTER ($START_TIME - $END_TIME)..."
		ffmpeg -i "$VIDEO_FILE" -ss "$START_TIME" -to "$END_TIME" -c copy "$OUTPUT_FILE"
		echo "Tamamlandı: $OUTPUT_FILE"
		COUNTER=$((COUNTER + 1))
	done
	;;
6)
	echo "=== Video Bilgileri ==="
	ffprobe -v quiet -print_format json -show_format -show_streams "$VIDEO_FILE" | grep -E '"duration"|"width"|"height"|"bit_rate"'
	echo ""
	echo "Detaylı bilgi için:"
	echo "ffmpeg -i \"$VIDEO_FILE\""
	;;
7)
	echo "=== TOPLU İŞLEM: Dizindeki Tüm MP4 Dosyaları ==="
	# Mevcut dizindeki MP4 dosyalarını listele
	MP4_FILES=(*.mp4)
	if [ ! -e "${MP4_FILES[0]}" ]; then
		echo "Hata: Bu dizinde hiç MP4 dosyası bulunamadı!"
		exit 1
	fi

	echo "Bulunan MP4 dosyaları:"
	for file in "${MP4_FILES[@]}"; do
		echo "  - $file"
	done
	echo ""
	echo "Toplam ${#MP4_FILES[@]} dosya bulundu."

	read -p "Tüm dosyaların başından kaç saniye atlanacak? (örnek: 14): " SKIP_SEC
	read -p "Bu işlemi gerçekleştirmek istediğinizden emin misiniz? (y/N): " CONFIRM

	if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
		echo ""
		echo "Toplu işlem başlatılıyor..."
		PROCESSED=0
		FAILED=0

		for video in "${MP4_FILES[@]}"; do
			# Dosya adını al (uzantısız)
			FILE_BASENAME=$(basename "$video" .mp4)
			OUTPUT_FILE="$OUTPUT_DIR/${FILE_BASENAME}_${SKIP_SEC}s_sonrasi.mp4"

			echo "İşleniyor: $video (${SKIP_SEC}s atlanıyor...)"

			# ffmpeg çıktısını gizle, sadece hata durumunda göster
			if ffmpeg -i "$video" -ss "$SKIP_SEC" -c copy "$OUTPUT_FILE" -y 2>/dev/null; then
				echo "  ✓ Tamamlandı: $OUTPUT_FILE"
				PROCESSED=$((PROCESSED + 1))
			else
				echo "  ✗ Hata: $video işlenirken problem oluştu!"
				FAILED=$((FAILED + 1))
			fi
		done

		echo ""
		echo "=== TOPLU İŞLEM RAPORU ==="
		echo "Başarılı: $PROCESSED dosya"
		echo "Başarısız: $FAILED dosya"
		echo "Çıktı klasörü: $OUTPUT_DIR"
	else
		echo "İşlem iptal edildi."
		exit 0
	fi
	;;
*)
	echo "Geçersiz seçim!"
	exit 1
	;;
esac

echo ""
echo "İşlem tamamlandı! Kesitler '$OUTPUT_DIR' klasöründe."
