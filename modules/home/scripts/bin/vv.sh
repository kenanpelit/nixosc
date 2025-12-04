#!/usr/bin/env bash
#===============================================================================
#
#   Script: vv - Günlük Not Alma Aracı
#   Version: 1.4.0
#   Date: 2025-06-14
#   Author: Kenan Pelit
#   Description: Otomatik numaralandırma ile günlük not tutma aracı
#
#   Features:
#   - Tarih bazlı otomatik dosya numaralandırma
#   - Alt dizin desteği (vv test/foo.txt gibi)
#   - fzf ile hızlı dosya seçimi
#   - fzf içinde Ctrl+D ile dosya silme özelliği
#   - Vim entegrasyonu ile kolay düzenleme
#   - Gelişmiş hata kontrolü ve güvenlik
#   - Template desteği
#   - Daha iyi performans ve kod kalitesi
#
#   License: MIT
#
#===============================================================================

set -euo pipefail # Katı hata kontrolü

# Renk kodları
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Yapılandırma Değişkenleri (readonly ile sabitlendi)
readonly VV_DIR="${VV_DIR:-$HOME/.anote/scratch}"
readonly VV_EDITOR="${VV_EDITOR:-vim}"
readonly VV_EDITOR_OPTS="${VV_EDITOR_OPTS:--c \"set paste\"}"
readonly VV_DATE_FORMAT="${VV_DATE_FORMAT:-%Y%m%d}"
readonly VV_FILE_PERM="${VV_FILE_PERM:-644}" # 755 yerine 644 daha güvenli
readonly VV_DIR_PERM="${VV_DIR_PERM:-755}"
readonly VV_TEMPLATE="${VV_TEMPLATE:-}"
readonly VV_MAX_FILES="${VV_MAX_FILES:-100}" # fzf performansı için limit

#===============================================================================
# Yardımcı fonksiyonlar

# Renkli mesaj yazdırma
print_message() {
	local color="$1"
	local message="$2"
	echo -e "${color}${message}${NC}" >&2
}

# Hata mesajı yazdırma ve çıkış
die() {
	print_message "$RED" "HATA: $1"
	exit 1
}

# Uyarı mesajı
warn() {
	print_message "$YELLOW" "UYARI: $1"
}

# Bilgi mesajı
info() {
	print_message "$BLUE" "$1"
}

# Başarı mesajı
success() {
	print_message "$GREEN" "$1"
}

# Güvenli dizin oluşturma
create_directory() {
	local dir="$1"
	local perm="$2"

	if [[ ! -d "$dir" ]]; then
		if ! mkdir -p "$dir"; then
			die "Dizin oluşturulamadı: $dir"
		fi
		chmod "$perm" "$dir"
		info "Dizin oluşturuldu: $dir"
	fi
}

# Güvenli dosya oluşturma
create_file() {
	local file="$1"
	local perm="$2"

	if [[ ! -f "$file" ]]; then
		if ! touch "$file"; then
			die "Dosya oluşturulamadı: $file"
		fi
		chmod "$perm" "$file"

		# Template varsa ekle
		if [[ -n "$VV_TEMPLATE" && -f "$VV_TEMPLATE" ]]; then
			if ! cp "$VV_TEMPLATE" "$file"; then
				warn "Template kopyalanamadı"
			fi
		fi
	fi
}

# Dosya yolu validasyonu
validate_file_path() {
	local path="$1"

	# Güvenlik kontrolleri
	if [[ "$path" =~ \.\./|\.\.\\ ]]; then
		die "Güvenlik nedeniyle '..' içeren yollar kabul edilmez"
	fi

	if [[ "${path:0:1}" == "/" ]]; then
		die "Mutlak yollar kabul edilmez"
	fi

	# Dosya adı uzunluk kontrolü
	local filename
	filename=$(basename "$path")
	if [[ ${#filename} -gt 255 ]]; then
		die "Dosya adı çok uzun (maksimum 255 karakter)"
	fi
}

# Editör kontrolü
check_editor() {
	if ! command -v "$VV_EDITOR" >/dev/null 2>&1; then
		die "Editör bulunamadı: $VV_EDITOR"
	fi
}

# Dosya listesi alma (performans optimizasyonu ile)
get_file_list() {
	local max_files="$1"
	find "$VV_DIR" -type f -printf '%T@ %p\n' 2>/dev/null |
		sort -rn |
		head -n "$max_files" |
		cut -d' ' -f2-
}

#===============================================================================
# Ana fonksiyonlar

# Yardım metni görüntüleme
show_help() {
	cat <<'EOF'
Kullanım: vv [SEÇENEK] [DOSYA]

Seçenekler:
  -h, --help          Bu yardım metnini göster
  -v, --version       Sürüm bilgisini göster
  -l, --list          Mevcut tüm dosyaları listele
  -c, --clean         Boş dosyaları temizle
  [DOSYA]             Belirtilen dosyayı aç (belirtilmezse otomatik numara verilir)
  [DİZİN/DOSYA]       Alt dizin ve dosya belirtilirse, o dizin altında dosya oluşturur

Açıklama:
  vv, günlük notlar oluşturmak ve düzenlemek için kullanılan bir araçtır.
  Otomatik numaralandırma ve tarih bazlı dosya organizasyonu sağlar.

Örnekler:
  vv                  Yeni dosya oluştur veya mevcut dosyalardan seç
  vv foo.txt          foo.txt dosyasını aç/oluştur
  vv test/foo.txt     test/foo.txt dosyasını aç/oluştur (dizin yoksa oluşturulur)
  vv -l               Tüm dosyaları listele
  vv -c               Boş dosyaları temizle

Çevresel Değişkenler:
  VV_DIR              Not dizini (varsayılan: ~/.anote/scratch)
  VV_EDITOR           Editör (varsayılan: vim)
  VV_EDITOR_OPTS      Editör seçenekleri (varsayılan: -c "set paste")
  VV_DATE_FORMAT      Tarih formatı (varsayılan: %Y%m%d)
  VV_FILE_PERM        Dosya izinleri (varsayılan: 644)
  VV_TEMPLATE         Template dosyası yolu
  VV_MAX_FILES        fzf'de gösterilecek maksimum dosya sayısı (varsayılan: 100)

fzf Kısayolları:
  Enter               Seçili dosyayı düzenle
  Ctrl+D              Seçili dosyayı sil
  Ctrl+C/Esc          Çıkış

EOF
}

# Sürüm bilgisi
show_version() {
	echo "vv version 1.4.0"
}

# Dosya listesi gösterme
list_files() {
	info "Mevcut dosyalar:"
	if command -v tree >/dev/null 2>&1; then
		tree "$VV_DIR" -a -I '.git'
	else
		find "$VV_DIR" -type f | sort | sed "s|^$VV_DIR/||"
	fi
}

# Boş dosya temizleme
clean_empty_files() {
	local count=0
	while IFS= read -r -d '' file; do
		rm "$file"
		info "Silindi: $(basename "$file")"
		((count++))
	done < <(find "$VV_DIR" -type f -empty -print0 2>/dev/null)

	success "Toplam $count boş dosya temizlendi"
}

# Sonraki dosya numarasını hesaplama
get_next_number() {
	local today="$1"
	local pattern="[0-9][0-9]_${today}.txt"

	local last_file
	last_file=$(find "$VV_DIR" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | sort -V | tail -n 1)

	if [[ -n "$last_file" ]]; then
		local last_num
		last_num=$(basename "$last_file" | cut -d'_' -f1)
		printf "%02d" $((10#$last_num + 1))
	else
		echo "01"
	fi
}

# fzf ile gelişmiş dosya seçimi
select_file_with_fzf() {
	if ! command -v fzf >/dev/null 2>&1; then
		warn "fzf bulunamadı. Yeni dosya oluşturuluyor."
		return 1
	fi

	local file_list
	file_list=$(get_file_list "$VV_MAX_FILES")

	if [[ -z "$file_list" ]]; then
		info "Henüz dosya yok. Yeni dosya oluşturuluyor."
		return 1
	fi

	local selected_file
	selected_file=$(echo "$file_list" | fzf \
		--reverse \
		--preview 'head -20 {} 2>/dev/null || echo "Dosya önizlemesi yapılamadı"' \
		--preview-window=right:60%:wrap \
		--prompt="Dosya seçin (Ctrl+D=sil, Enter=düzenle): " \
		--header="Toplam $(echo "$file_list" | wc -l) dosya" \
		--bind "ctrl-d:execute(bash -c '
            read -p \"$(basename \"{}\") dosyasını silmek istediğinize emin misiniz? (e/H): \" confirm
            if [[ \"\$confirm\" =~ ^[Ee] ]]; then
                rm \"{}\" && echo \"Dosya silindi: $(basename \"{}\")\"
            else
                echo \"İptal edildi\"
            fi
            read -p \"Devam etmek için Enter tuşuna basın...\"
        ')+reload(find \"$VV_DIR\" -type f -printf \"%T@ %p\\n\" 2>/dev/null | sort -rn | head -n \"$VV_MAX_FILES\" | cut -d\" \" -f2-)")

	if [[ -n "$selected_file" && -f "$selected_file" ]]; then
		echo "$selected_file"
		return 0
	fi

	return 1
}

# Ana dosya işleme fonksiyonu
process_file() {
	local file_arg="$1"
	local file_path

	if [[ -z "$file_arg" ]]; then
		# Parametre yoksa fzf ile seçim yap
		if file_path=$(select_file_with_fzf); then
			eval "$VV_EDITOR $VV_EDITOR_OPTS \"$file_path\""
			return 0
		fi

		# Yeni dosya oluştur
		local today
		today=$(date +"$VV_DATE_FORMAT")
		local next_num
		next_num=$(get_next_number "$today")

		file_path="$VV_DIR/${next_num}_${today}.txt"
	else
		# Belirtilen dosyayı kullan
		validate_file_path "$file_arg"
		file_path="$VV_DIR/$file_arg"

		# Alt dizin oluştur
		local file_dir
		file_dir=$(dirname "$file_path")
		create_directory "$file_dir" "$VV_DIR_PERM"
	fi

	# Dosyayı oluştur ve aç
	create_file "$file_path" "$VV_FILE_PERM"
	eval "$VV_EDITOR $VV_EDITOR_OPTS \"$file_path\""
}

#===============================================================================
# Ana program

main() {
	# Parametre kontrolü
	case "${1:-}" in
	-h | --help)
		show_help
		exit 0
		;;
	-v | --version)
		show_version
		exit 0
		;;
	-l | --list)
		list_files
		exit 0
		;;
	-c | --clean)
		clean_empty_files
		exit 0
		;;
	-*)
		die "Geçersiz seçenek: $1. Yardım için: vv --help"
		;;
	esac

	# Editör kontrolü
	check_editor

	# Ana dizin oluştur
	create_directory "$VV_DIR" "$VV_DIR_PERM"

	# Dosya işleme
	process_file "${1:-}"
}

# Ana fonksiyonu çalıştır
main "$@"
