#!/usr/bin/env bash

# semsumo-start.sh
# Basit Semsumo başlatma scripti
# Tüm grup uygulamalarını başlatır

# Ekrana bilgi mesajı
echo "Semsumo başlatılıyor - Tüm gruplar yükleniyor..."

# Ana dizine git (isteğe bağlı - genellikle script çalışmasını etkilemez)
cd "$HOME" 2>/dev/null || true

# Komut mevcut mu kontrol et
if ! command -v semsumo &>/dev/null; then
	echo "Hata: semsumo komutu bulunamadı!"
	echo "Lütfen semsumo'nun yüklü ve PATH'te olduğundan emin olun."
	exit 1
fi

# Semsumo'yu çalıştır ve tüm grupları başlat
semsumo group all

# Çıkış kodu kontrol et
if [ $? -eq 0 ]; then
	echo "Semsumo başlatıldı - Tüm gruplar yüklendi!"
else
	echo "Semsumo başlatma hatası!"
fi

exit 0
