#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: WallRenamer - Duvar Kağıdı Dosya Yeniden Adlandırma Aracı
#
# Bu script ~/.wall dizinindeki duvar kağıdı dosyalarını sıralı olarak
# yeniden adlandırmak için tasarlanmıştır. Temel özellikleri:
#
# - Dosya işlemleri
#   - jpg/jpeg/png uzantılı dosyaları işleme
#   - Sıralı numaralandırma (1.jpg, 2.jpg...)
#   - Güvenli dosya taşıma ve kopyalama
#
# - Güvenlik kontrolleri
#   - Geçici dizin kullanımı
#   - Dosya sayısı doğrulama
#   - Hata yakalama ve raporlama
#
# - Detaylı raporlama
#   - Uzantı bazlı dosya sayısı
#   - İşlem sonucu bildirimi
#   - Yeniden adlandırılan dosya listesi
#
# Dizin: ~/.wall/
# Desteklenen formatlar: jpg, jpeg, png
#
# License: MIT
#
#######################################
# Yedekleme yapılacak dizin ~/.wall
rename_dir="$HOME/Pictures/wallpapers/others"

# Dizinin mevcut olup olmadığını kontrol et
if [ -d "$rename_dir" ]; then
	# Geçici bir dizin oluştur
	temp_dir=$(mktemp -d)
	echo "Geçici dizin oluşturuldu: $temp_dir"

	cd "$rename_dir" || exit 1 # Hata durumunda çıkış yap

	# Toplam yeniden adlandırılan dosya sayısını takip etmek için bir sayaç
	total_renamed=0

	# Her bir dosya uzantısı için dosya sayısını kontrol et ve ardından isim değişikliği yap
	for ext in jpg jpeg png; do
		# Dosya sayısını hesapla
		file_count=$(ls *."$ext" 2>/dev/null | wc -l)
		echo "$ext uzantılı dosya sayısı: $file_count"

		# Eğer dosya varsa, dosya ismini değiştir
		if ((file_count > 0)); then
			# Başlangıç numarası
			j=1

			# İsim değiştirme işlemi (Geçici dizinde yapılıyor)
			for i in *."$ext"; do
				cp "$i" "$temp_dir/$j.$ext" || {
					echo "$i dosyasını kopyalama başarısız"
					exit 1
				}
				j=$((j + 1)) # Sıradaki dosya için numarayı artır
			done

			# Her dosya uzantısı türü için yeniden adlandırılan dosya sayısını artır
			total_renamed=$((total_renamed + file_count))
		else
			echo "$ext uzantılı dosya bulunamadı."
		fi
	done

	# Orijinal dizin ile geçici dizin arasındaki dosya sayısını karşılaştır
	original_count=$(find "$rename_dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | wc -l)
	temp_count=$(find "$temp_dir" -maxdepth 1 -type f | wc -l)

	if [[ "$original_count" -eq "$temp_count" ]]; then
		echo "Dosya sayısı eşleşiyor. Dosyalar taşınıyor..."

		# Orijinal dizindeki mevcut dosyaları sil
		rm "$rename_dir"/*."jpg" "$rename_dir"/*."jpeg" "$rename_dir"/*."png" 2>/dev/null

		# Geçici dizindeki dosyaları orijinal dizine taşı
		mv "$temp_dir"/* "$rename_dir" || {
			echo "Dosyaları $rename_dir dizinine taşıma başarısız"
			exit 1
		}

		# İşlem tamamlandığında bir bildirim gönder
		#notify-send "İsim Değiştirme Tamamlandı" "$total_renamed dosyanın ismi başarıyla değiştirildi."
	else
		echo "Hata: Geçici dizin ile orijinal dizindeki dosya sayısı eşleşmiyor!"
		notify-send "Hata" "Geçici ve orijinal dizindeki dosya sayısı eşleşmiyor!"
		exit 1
	fi

	# Geçici dizini temizle
	rmdir "$temp_dir" || {
		echo "Geçici dizin silinemedi"
		exit 1
	}

	# Sonuçları listele
	ls "$rename_dir" | sort -n
else
	echo "$rename_dir dizini mevcut değil."
	#notify-send "Hata" "$rename_dir dizini mevcut değil!"
fi
