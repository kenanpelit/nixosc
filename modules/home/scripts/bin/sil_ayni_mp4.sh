#!/usr/bin/env bash

# Dosya türünü ve kontrol edilecek dizini belirleyin
file_extension="mp4"
directory="${1:-.}"

# Verilen dizinde mp4 dosyalarını bulun
find "$directory" -type f -iname "*.$file_extension" | while read -r file; do
  # Dosyanın MD5 hash değerini alın
  file_hash=$(md5sum "$file" | awk '{ print $1 }')

  # Aynı hash'e sahip başka bir dosya var mı kontrol et
  duplicate=$(find "$directory" -type f -iname "*.$file_extension" ! -path "$file" -exec md5sum {} \; | awk -v hash="$file_hash" '$1 == hash { print $2 }')

  if [[ -n "$duplicate" ]]; then
    echo "Aynı içeriğe sahip dosya bulunmuş: $file"
    echo "Silmek için onay verin (y/n): "
    read -r confirmation
    if [[ "$confirmation" == "y" ]]; then
      rm "$file"
      echo "$file silindi."
    fi
  fi
done
