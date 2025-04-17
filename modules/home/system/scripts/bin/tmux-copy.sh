#!/usr/bin/env bash
#######################################
#
# Version: 2.1.0
# Date: 2025-04-17
# Original Authors: Kenan Pelit
# Description: Enhanced Tmux and Clipboard Manager
#
# Bu script üç temel modda çalışır:
#
# 1. Tmux Buffer Modu (-b):
#    - Tmux buffer listesini gösterme
#    - Buffer içeriğini önizleme
#    - Seçili buffer'ı yapıştırma
#    - Buffer listesini yenileme
#
# 2. Clipboard Modu (-c):
#    - Sistem clipboard geçmişini gösterme
#    - Metin/görüntü önizleme desteği
#    - Seçili öğeyi silme
#    - İçeriği clipboard ve tmux'a kopyalama
#    - Clipboard geçmişini yenileme
#
# 3. Komut Hızlandırıcı Modu (-s):
#    - Sık kullanılan komutları listeleme
#    - Komut kullanım istatistiklerini gösterme
#    - Seçili komutu çalıştırma
#    - Kullanım geçmişini otomatik kaydetme
#
# Gereksinimler:
# - tmux: Buffer modu için
# - cliphist/wl-clipboard: Clipboard modu için
# - chafa: Görüntü önizleme için
# - fzf: İnteraktif seçim için
#
# License: MIT
#
#######################################

# Hata yakalama
set -euo pipefail

# Yapılandırma değişkenleri
DIR="${HOME}/.config/tmux/fzf"
CACHE_FILE="${HOME}/.cache/fzf_cache"
HISTORY_LIMIT=100

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# FZF tema yapılandırması - tüm modlarda tutarlı görünüm için
setup_fzf_theme() {
	local prompt_text="${1:-FZF}"
	local header_text="${2:-CTRL-R: Yenile | ESC: Çık}"

	export FZF_DEFAULT_OPTS="\
        -e -i \
        --info=default \
        --layout=reverse \
        --margin=1 \
        --padding=1 \
        --ansi \
        --prompt='$prompt_text: ' \
        --pointer='❯' \
        --header='$header_text' \
        --color='bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796,fg:#cad3f5' \
        --color='header:#8aadf4,info:#c6a0f6,pointer:#f4dbd6,marker:#f4dbd6,prompt:#c6a0f6' \
        --bind 'ctrl-j:preview-down,ctrl-k:preview-up' \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
        --bind 'ctrl-/:change-preview-window(hidden|)' \
        --color='pointer:magenta' \
        --tiebreak=index"
}

# Kullanım bilgisi
usage() {
	cat <<EOF
$(echo -e "${BLUE}Enhanced Tmux ve Clipboard Yöneticisi v2.1.0${NC}")

$(echo -e "Kullanım: $0 ${GREEN}[-b|-c|-s|-h]${NC}")
$(echo -e "Seçenekler:")
$(echo -e "  ${GREEN}-b${NC}: Buffer yönetimi için tmux modu")
$(echo -e "  ${GREEN}-c${NC}: Clipboard yönetimi için cliphist modu")
$(echo -e "  ${GREEN}-s${NC}: Hızlı komut çalıştırma modu")
$(echo -e "  ${GREEN}-h${NC}: Bu yardım mesajını gösterir")

$(echo -e "${YELLOW}Kısayollar:${NC}")
$(echo -e "  CTRL-R: Listeyi yenile")
$(echo -e "  CTRL-D: Seçili öğeyi sil (sadece clipboard modu)")
$(echo -e "  CTRL-Y: Seçili öğeyi kopyala")
$(echo -e "  CTRL-J/K: Önizlemede aşağı/yukarı")
$(echo -e "  CTRL-D/U: Önizlemede sayfa aşağı/yukarı")
$(echo -e "  CTRL-/: Önizleme penceresini aç/kapat")
$(echo -e "  Enter: Seç ve işlem yap")
$(echo -e "  ESC: Çıkış")
EOF
	exit 1
}

# Mesaj fonksiyonları
info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

error() {
	echo -e "${RED}[HATA]${NC} $1" >&2
}

success() {
	echo -e "${GREEN}[BAŞARILI]${NC} $1"
}

# Gerekli programların kontrolü
check_requirements() {
	local req_failed=0

	# Temel gereksinimler
	if ! command -v fzf &>/dev/null; then
		error "fzf kurulu değil!"
		req_failed=1
	fi

	# Mod spesifik gereksinimler
	case "$1" in
	"buffer")
		if ! tmux info &>/dev/null; then
			error "Tmux oturumu bulunamadı!"
			req_failed=1
		fi
		;;
	"clipboard")
		if ! command -v cliphist &>/dev/null; then
			error "cliphist kurulu değil!"
			req_failed=1
		fi
		if ! command -v wl-copy &>/dev/null; then
			error "wl-clipboard kurulu değil!"
			req_failed=1
		fi
		# Görüntü önizleme opsiyonel
		if ! command -v chafa &>/dev/null; then
			info "Not: chafa kurulu değil - görüntü önizleme devre dışı!"
		fi
		;;
	"speed")
		if [ ! -d "$DIR" ]; then
			error "Komut dizini bulunamadı: $DIR"
			error "Lütfen dizini oluşturun veya yapılandırmayı kontrol edin"
			req_failed=1
		fi
		;;
	esac

	return $req_failed
}

# Boş buffer kontrolü için grafik
show_empty_buffer_art() {
	cat <<-'EMPTYART'
		        
		   ┌────────────────────────────────────────────────────┐
		   │                                                    │
		   │   ¯\_(ツ)_/¯                                       │
		   │                                                    │
		   │   Tmux buffer'ım boş!                              │
		   │                                                    │
		   │   Önce bir şeyler kopyalasanız iyi olur yoksa      │
		   │   burada birlikte bekleyeceğiz...                  │
		   │                                                    │
		   │   İpucu: Tmux'ta [prefix]+[ ile copy mode'a girin  │
		   │   ve birşeyler kopyalayın                          │
		   │                                                    │
		   └────────────────────────────────────────────────────┘
		        
	EMPTYART
}

# Buffer modu fonksiyonu
handle_buffer_mode() {
	# Gereksinimler kontrolü
	if ! check_requirements "buffer"; then
		exit 1
	fi

	# Buffer listesi boş mu kontrolü
	if ! tmux list-buffers &>/dev/null || [[ -z "$(tmux list-buffers 2>/dev/null)" ]]; then
		show_empty_buffer_art
		exit 1
	fi

	# FZF tema ayarı
	setup_fzf_theme "Buffer" "Buffer Seçimi | CTRL-R: Yenile | CTRL-Y: Kopyala | ESC: Çık"

	info "Buffer modu başlatılıyor..."

	# FZF için buffer listesi
	selected_buffer=$(tmux list-buffers -F '#{buffer_name}:#{buffer_sample}' |
		fzf --preview 'buffer_name=$(echo {} | cut -d ":" -f1); tmux show-buffer -b "$buffer_name"' \
			--preview-window 'right:60%:wrap' \
			--bind "ctrl-r:reload(tmux list-buffers -F '#{buffer_name}:#{buffer_sample}')" \
			--bind "ctrl-y:execute-silent(buffer_name=\$(echo {} | cut -d ':' -f1); tmux show-buffer -b \"\$buffer_name\" | wl-copy && echo 'Kopyalandı: \$buffer_name' >&2)" \
			--delimiter ':')

	# Seçim yapıldı mı kontrolü
	if [[ -n "$selected_buffer" ]]; then
		buffer_name=$(echo "$selected_buffer" | cut -d ':' -f1)
		if [[ -n "$buffer_name" ]]; then
			tmux paste-buffer -b "$buffer_name"
			success "Seçilen buffer yapıştırıldı: $buffer_name"
		else
			error "Geçersiz buffer adı, yapıştırılamadı"
		fi
	fi
}

# Clipboard modu fonksiyonu
handle_cliphist_mode() {
	# Gereksinimler kontrolü
	if ! check_requirements "clipboard"; then
		exit 1
	fi

	# FZF tema ayarı
	setup_fzf_theme "Clipboard" "Clipboard Geçmişi | CTRL-R: Yenile | CTRL-D: Sil | CTRL-Y: Kopyala | Enter: Seç"

	info "Clipboard modu başlatılıyor..."

	# Önizleme betiği oluştur
	PREVIEW_SCRIPT=$(mktemp)
	chmod +x "$PREVIEW_SCRIPT"

	# Önizleme betiğinin içeriğini oluştur
	cat >"$PREVIEW_SCRIPT" <<'EOL'
#!/usr/bin/env bash
set -euo pipefail

preview_limit=5000

# Terminal ekranını temizle
clear

# Parametre kontrolü
if [ -z "${1:-}" ]; then
    echo "Önizleme için içerik sağlanmadı"
    exit 0
fi

# Geçici dosya oluştur
temp_file=$(mktemp)

# İçeriği al ve temp dosyaya kaydet
if ! cliphist decode <<< "$1" > "$temp_file" 2>/dev/null; then
    echo "İçerik alınamadı"
    rm -f "$temp_file"
    exit 0
fi

# Dosya boş mu kontrol et
if [ ! -s "$temp_file" ]; then
    echo "İçerik boş"
    rm -f "$temp_file"
    exit 0
fi

# File çıktısını al
file_output=$(file -b "$temp_file")
echo -e "\033[1;34mDosya türü:\033[0m $file_output"
echo -e "\033[1;34mBoyut:\033[0m $(du -h "$temp_file" | cut -f1)"
echo -e "\033[1;34mİçerik:\033[0m"
echo

# PNG/JPEG kontrolü
if [[ "$file_output" == *"PNG"* ]] || [[ "$file_output" == *"JPEG"* ]] || [[ "$file_output" == *"image data"* ]]; then
    if command -v chafa &>/dev/null; then
        chafa --size=80x25 --symbols=block+space --colors=256 "$temp_file" 2>/dev/null || echo "Görüntü önizleme başarısız"
    else
        echo "[Önizleme için chafa gerekli]"
    fi
else
    head -c "$preview_limit" "$temp_file"
    if [ "$(wc -c < "$temp_file")" -gt "$preview_limit" ]; then
        echo -e "\n\033[0;33m... (devamı var)\033[0m"
    fi
fi

# Temizlik
rm -f "$temp_file"
EOL

	# FZF ile seçim yap
	selected=$(cliphist list |
		fzf --preview "$PREVIEW_SCRIPT {}" \
			--preview-window "right:60%:wrap" \
			--bind "ctrl-r:reload(cliphist list)" \
			--bind "ctrl-d:execute(echo {} | cliphist delete)+reload(cliphist list)" \
			--bind "ctrl-y:execute-silent(echo {} | cliphist decode | wl-copy && echo 'İçerik kopyalandı' >&2)")

	# Geçici dosyaları temizle
	rm -f "$PREVIEW_SCRIPT"

	# Seçim yapıldıysa kopyala
	if [[ -n "$selected" ]]; then
		content=$(cliphist decode <<<"$selected")
		echo "$content" | wl-copy
		if [ -n "${TMUX:-}" ]; then
			echo "$content" | tmux load-buffer -
			success "İçerik clipboard ve tmux buffer'a kopyalandı"
		else
			success "İçerik clipboard'a kopyalandı"
		fi
	fi
}

# Hızlı komut çalıştırma (speed) modu
handle_speed_mode() {
	# Gereksinimler kontrolü
	if ! check_requirements "speed"; then
		exit 1
	fi

	info "Hızlı komut modu başlatılıyor..."

	# Cache dosyasını oluştur (yoksa)
	mkdir -p "$(dirname "$CACHE_FILE")"
	touch "$CACHE_FILE"

	# İstatistikler
	total=$(find "$DIR" -type f -name '_*' 2>/dev/null | wc -l)
	ssh_count=$(find "$DIR" -type f -name '_ssh*' 2>/dev/null | wc -l)
	tmux_count=$(find "$DIR" -type f -name '_tmux*' 2>/dev/null | wc -l)

	# FZF tema ayarı - speed mode için özel header
	setup_fzf_theme "Speed" "Toplam: $total | SSH: $ssh_count | TMUX: $tmux_count | ESC ile çık, ENTER ile çalıştır"

	# Speed modu için ek ayarlar
	export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
        --delimiter=_ \
        --with-nth=2.."

	# Sık kullanılanları al
	get_frequent() {
		if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
			cat "$CACHE_FILE" |
				sort |
				uniq -c |
				sort -nr |
				head -n 10 |
				awk '{print $2}' |
				sed 's/^/⭐ /'
		fi
	}

	# Ana komut
	SELECTED="$(
		(
			# Sık kullanılanlar
			get_frequent
			# Tüm liste
			find "$DIR" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null |
				sort |
				grep '^_' |
				sed 's@\.@ @g'
		) |
			column -s ',' -t |
			fzf |
			sed 's/^⭐ //' |
			cut -d ' ' -f1
	)"

	# Seçim yapılmadıysa çık
	[ -z "$SELECTED" ] && exit 0

	# Kullanımı kaydet (sadece script adını)
	echo "${SELECTED}" >>"$CACHE_FILE"

	# Cache dosyasını maksimum limit satırda tut
	if [ "$(wc -l <"$CACHE_FILE")" -gt "$HISTORY_LIMIT" ]; then
		tail -n "$HISTORY_LIMIT" "$CACHE_FILE" >"$CACHE_FILE.tmp" &&
			mv "$CACHE_FILE.tmp" "$CACHE_FILE"
	fi

	# Seçilen scripti çalıştır
	script_path=$(find "$DIR" -name "${SELECTED},*" -o -name "${SELECTED}.*" | head -1)
	if [ -n "$script_path" ] && [ -f "$script_path" ]; then
		success "Çalıştırılıyor: $script_path"
		eval "$script_path"
	else
		error "Script bulunamadı: ${SELECTED}"
		exit 1
	fi
}

# Ana fonksiyon
main() {
	[[ $# -eq 0 ]] && usage

	case "${1:-}" in
	-b)
		handle_buffer_mode
		;;
	-c)
		handle_cliphist_mode
		;;
	-s)
		handle_speed_mode
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		usage
		;;
	esac
}

# Programı çalıştır
main "$@"
