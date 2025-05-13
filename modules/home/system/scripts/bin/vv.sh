#!/usr/bin/env bash
#===============================================================================
#
#   Script: vv - Günlük Not Alma Aracı
#   Version: 1.3.0
#   Date: 2025-05-01
#   Author: Kenan Pelit
#   Description: Otomatik numaralandırma ile günlük not tutma aracı
#
#   Features:
#   - Tarih bazlı otomatik dosya numaralandırma
#   - Alt dizin desteği (vv test/foo.txt gibi)
#   - fzf ile hızlı dosya seçimi
#   - fzf içinde Ctrl+D ile dosya silme özelliği
#   - Vim entegrasyonu ile kolay düzenleme
#
#   License: MIT
#
#===============================================================================

# Yapılandırma Değişkenleri
VV_DIR="${VV_DIR:-$HOME/.anote/scratch}"             # Ana dizin
VV_EDITOR="${VV_EDITOR:-vim}"                        # Düzenleyici program
VV_EDITOR_OPTS="${VV_EDITOR_OPTS:--c \"set paste\"}" # Düzenleyici seçenekleri
VV_DATE_FORMAT="${VV_DATE_FORMAT:-%Y%m%d}"           # Tarih formatı
VV_FILE_PERM="${VV_FILE_PERM:-755}"                  # Dosya izinleri

#===============================================================================
# Yardım metni görüntüleme fonksiyonu
# Yardım metni görüntüleme fonksiyonu
show_help() {
	echo "Kullanım: vv [SEÇENEK]"
	echo
	echo "Seçenekler:"
	echo "  -h, --help          Bu yardım metnini göster"
	echo "  [DOSYA]             Belirtilen dosyayı aç (belirtilmezse otomatik numara verilir)"
	echo "  [DİZİN/DOSYA]       Alt dizin ve dosya belirtilirse, o dizin altında dosya oluşturur"
	echo
	echo "Açıklama:"
	echo "  vv, $VV_DIR dizininde otomatik olarak numaralandırılmış günlük notlar"
	echo "  oluşturmak ve düzenlemek için kullanılan bir araçtır."
	echo "  Komut parametresiz kullanıldığında bugünün tarihiyle yeni bir not dosyası oluşturur"
	echo "  veya mevcut dosyalardan fzf ile seçim yapmanızı sağlar."
	echo
	echo "Örnekler:"
	echo "  vv                  Yeni dosya oluştur veya mevcut dosyaları listele"
	echo "  vv foo.txt          $VV_DIR/foo.txt dosyasını aç/oluştur"
	echo "  vv test/foo.txt     $VV_DIR/test/foo.txt dosyasını aç/oluştur (dizin yoksa oluşturulur)"
	echo
	echo "Özelleştirme:"
	echo "  Aşağıdaki çevresel değişkenler ile davranışı değiştirebilirsiniz:"
	echo "  VV_DIR             Not dosyalarının saklanacağı dizin (varsayılan: $HOME/Tmp/vv)"
	echo "  VV_EDITOR          Kullanılacak editör (varsayılan: vim)"
	echo "  VV_EDITOR_OPTS     Editör seçenekleri (varsayılan: -c \"set paste\")"
	echo "  VV_DATE_FORMAT     Tarih biçimi (varsayılan: %Y%m%d)"
	echo "  VV_FILE_PERM       Dosya izinleri (varsayılan: 755)"
	echo
	echo "fzf içinde:"
	echo "    - Enter tuşu: Seçili dosyayı düzenler"
	echo "    - Ctrl+D tuşu: Seçili dosyayı siler"
	echo
}
# Parametreleri kontrol et
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	show_help
	exit 0
fi

# Ana dizinin varlığını kontrol et, yoksa oluştur
if [ ! -d "$VV_DIR" ]; then
	mkdir -p "$VV_DIR"
fi

# Bugünün tarihini al
TODAY=$(date +"$VV_DATE_FORMAT")
# Parametre kontrolü
if [ -z "$1" ]; then
	# Parametre yoksa fzf ile dosya seçimi sunalım
	if command -v fzf >/dev/null 2>&1; then
		# fzf ile dosya seçimi - Ctrl+D ile silme özelliği eklenmiş
		SELECTED_FILE=$(find "$VV_DIR" -type f | sort -r | fzf --reverse --preview 'cat {}' \
			--prompt="Düzenlemek için dosya seçin (Ctrl+D ile silebilirsiniz): " \
			--bind "ctrl-d:execute(bash -c 'read -p \"\\\"{}\\\" dosyasını silmek istediğinize emin misiniz? (e/h): \" confirm && [[ \"\$confirm\" == [Ee]* ]] && rm \"{}\" && echo \"\\nDosya silindi!\"')+reload(find \"$VV_DIR\" -type f | sort -r)")

		# Kullanıcı bir dosya seçtiyse düzenlemeye aç ve sonra çık
		if [ -n "$SELECTED_FILE" ] && [ -f "$SELECTED_FILE" ]; then
			eval "$VV_EDITOR $VV_EDITOR_OPTS \"$SELECTED_FILE\""
			exit 0
		fi

		# Kullanıcı ESC ile çıktıysa veya dosya seçmediyse
		if [ -z "$SELECTED_FILE" ]; then
			echo "Yeni dosya oluşturuluyor..."
		fi
	else
		echo "fzf bulunamadı. Yeni dosya oluşturuluyor."
	fi
	# Seçim yapılmadıysa yeni dosya oluştur
	NEXT_NUM="01"
	# Bugüne ait son dosyayı bul ve bir sonraki numarayı hesapla
	LAST_FILE=$(find "$VV_DIR" -type f -name "[0-9][0-9]_$TODAY.txt" 2>/dev/null | sort -r | head -n 1)
	if [ -n "$LAST_FILE" ]; then
		# Son dosyadan numarayı çıkar ve bir artır
		LAST_NUM=$(basename "$LAST_FILE" | cut -d'_' -f1)
		NEXT_NUM=$(printf "%02d" $((10#$LAST_NUM + 1)))
	fi
	# Yeni dosyayı oluştur
	NEW_FILE="$VV_DIR/${NEXT_NUM}_${TODAY}.txt"
	touch "$NEW_FILE"
	chmod $VV_FILE_PERM "$NEW_FILE"
	# Düzenleyici ile aç
	eval "$VV_EDITOR $VV_EDITOR_OPTS \"$NEW_FILE\""
else
	# Özel dosya adı verilmişse doğrudan onu kullan
	FILE_PATH="$VV_DIR/$1"

	# Dosyanın bulunduğu dizini al
	FILE_DIR=$(dirname "$FILE_PATH")

	# Gerekli alt dizinleri oluştur
	if [ ! -d "$FILE_DIR" ]; then
		mkdir -p "$FILE_DIR"
		echo "Dizin oluşturuldu: $FILE_DIR"
	fi

	# Dosyayı oluştur veya aç
	[ ! -f "$FILE_PATH" ] && touch "$FILE_PATH"
	chmod $VV_FILE_PERM "$FILE_PATH"
	eval "$VV_EDITOR $VV_EDITOR_OPTS \"$FILE_PATH\""
fi
