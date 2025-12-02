#!/usr/bin/env bash

# Kullanım fonksiyonu
usage() {
	echo "Kullanım: $0 [SEÇENEK] [DOSYA]"
	echo "Seçenekler:"
	echo "  -l, --list              Tüm gistleri listele"
	echo "  -u, --upload DOSYA      Yeni gist oluştur"
	echo "  -d, --delete ID         Gist sil (ID ile)"
	echo "  -h, --help              Bu yardım mesajını göster"
	echo "  -t, --title BAŞLIK      Gist başlığı belirt (upload ile kullanılır)"
	echo
	echo "Örnek kullanım:"
	echo "  $0 -l                   # Tüm gistleri listele"
	echo "  $0 -u dosya.txt         # Dosyayı gist olarak yükle"
	echo "  $0 -u dosya.txt -t 'Özel başlık'  # Başlıklı gist yükle"
	echo "  $0 -d abc123            # abc123 ID'li gisti sil"
	exit 1
}

# Gist listele
list_gists() {
	gist -l
}

# Gist yükle
upload_gist() {
	local DOSYA="$1"
	local BASLIK="${2:-$(basename "$DOSYA") $(date '+%Y-%m-%d %H:%M:%S')}"

	if [ ! -f "$DOSYA" ]; then
		echo "Hata: '$DOSYA' dosyası bulunamadı"
		exit 1
	fi

	gist -p -c -o -d "$BASLIK" "$DOSYA"
}

# Gist sil
delete_gist() {
	local GIST_ID="$1"
	gist --delete "$GIST_ID"
}

# Parametre kontrolü
if [ $# -eq 0 ]; then
	usage
fi

# Ana komut işleme
BASLIK=""
while [[ $# -gt 0 ]]; do
	case "$1" in
	-l | --list)
		list_gists
		exit 0
		;;
	-u | --upload)
		if [ -z "$2" ]; then
			echo "Hata: Yüklenecek dosya belirtilmedi"
			usage
		fi
		DOSYA="$2"
		shift 2
		;;
	-t | --title)
		if [ -z "$2" ]; then
			echo "Hata: Başlık belirtilmedi"
			usage
		fi
		BASLIK="$2"
		shift 2
		;;
	-d | --delete)
		if [ -z "$2" ]; then
			echo "Hata: Silinecek gist ID'si belirtilmedi"
			usage
		fi
		delete_gist "$2"
		exit 0
		;;
	-h | --help)
		usage
		;;
	*)
		echo "Geçersiz seçenek: $1"
		usage
		;;
	esac
done

if [ ! -z "$DOSYA" ]; then
	upload_gist "$DOSYA" "$BASLIK"
fi
