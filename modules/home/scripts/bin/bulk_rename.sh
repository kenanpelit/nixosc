#!/usr/bin/env bash

# Kullanıcıdan yedekleme yapılacak dizinin tam yolunu al
echo "Enter Absolute path where you want to perform a rename:"
read -e rename

# Girilen dizin mevcut mu kontrol et
if [ -d "$rename" ]; then
  cd "$rename" || exit 1 # Hata durumunda çıkış yap

  # Geçici dizin oluştur
  mkdir temp1
  temp="$rename/temp1"
  cd "$temp" || exit 1 # Hata durumunda çıkış yap

  mkdir final
  final="$temp/final"

  # Kullanıcıdan yeniden adlandırma için başlangıç numarasını ve dosya uzantısını al
  echo -n "Enter to rename from (number), excluding Extension: "
  read j
  echo -n "Enter Extension now: "
  read ex

  # Orijinal dizine geri dön
  cd "$rename" || exit 1 # Hata durumunda çıkış yap

  # Belirtilen uzantıya sahip dosyalar üzerinde döngü başlat
  for i in *."$ex"; do
    # Dosyayı geçici dizine taşı
    mv "$i" "$temp" || {
      echo "Failed to move $i"
      exit 1
    }                    # Hata kontrolü
    cd "$temp" || exit 1 # Hata durumunda çıkış yap

    # Dosyanın adını yeniden adlandır
    mv "$i" "$j.$ex" || {
      echo "Failed to rename $i"
      exit 1
    } # Hata kontrolü
    mv "$j.$ex" "$final" || {
      echo "Failed to move $j.$ex to $final"
      exit 1
    } # Hata kontrolü

    # Orijinal dizine geri dön
    cd "$rename" || exit 1 # Hata durumunda çıkış yap

    # Artık bir sonraki dosya için numarayı artır
    j=$((j + 1))
  done

  # Tüm dosyaları final dizininden orijinal dizine taşı
  cd "$final" || exit 1 # Hata durumunda çıkış yap
  mv *."$ex" "$rename" || {
    echo "Failed to move files to $rename"
    exit 1
  } # Hata kontrolü

  # Geçici dizinleri temizle
  cd "$temp" || exit 1 # Hata durumunda çıkış yap
  rmdir "$final" || {
    echo "Failed to remove $final"
    exit 1
  } # Hata kontrolü
  rmdir "$temp" || {
    echo "Failed to remove $temp"
    exit 1
  } # Hata kontrolü

  # Sonuçları listele
  ls "$rename" | sort -n
else
  echo "$rename: no such a directory exists."
fi
