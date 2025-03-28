#!/usr/bin/env bash
#######################################
#
# Version: 1.0.2
# Date: 2025-03-29
# Original Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: ClipManager - Tmux Buffer ve Clipboard Yönetim Aracı
#
# Bu script tmux buffer ve sistem clipboard'ının yönetimi için tasarlanmış
# interaktif bir araçtır. İki temel modda çalışır:
#
# Tmux Buffer Modu (-b):
# - Tmux buffer listesini gösterme
# - Buffer içeriğini önizleme
# - Seçili buffer'ı yapıştırma
# - Buffer listesini yenileme
#
# Clipboard Modu (-c):
# - Sistem clipboard geçmişini gösterme
# - Metin/görüntü önizleme desteği
# - Seçili öğeyi silme
# - İçeriği clipboard ve tmux'a kopyalama
# - Clipboard geçmişini yenileme
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

# Kullanım bilgisi
usage() {
	echo "Kullanım: $0 [-b|-c|-h]"
	echo "Seçenekler:"
	echo "  -b: Buffer yönetimi için tmux modu"
	echo "  -c: Clipboard yönetimi için cliphist modu"
	echo "  -h: Bu yardım mesajını gösterir"
	echo
	echo "Kısayollar:"
	echo "  CTRL-R: Listeyi yenile"
	echo "  CTRL-D: Seçili öğeyi sil (sadece clipboard modu)"
	echo "  CTRL-Y: Seçili öğeyi kopyala"
	echo "  Enter: Seç ve kopyala"
	echo "  ESC: Çıkış"
	exit 1
}

# Buffer modu için düzeltilmiş fonksiyon
handle_buffer_mode() {
	# Tmux session kontrolü
	if ! tmux info &>/dev/null; then
		echo "Hata: Tmux oturumu bulunamadı!"
		exit 1
	fi

	# Buffer listesi boş mu kontrolü
	if ! tmux list-buffers &>/dev/null || [[ -z "$(tmux list-buffers 2>/dev/null)" ]]; then
		echo "Hata: Buffer listesi boş!"
		exit 1
	fi

	# Buffer önizleme fonksiyonu
	preview_buffer() {
		local buffer_name="$1"
		if [[ -n "$buffer_name" ]]; then
			tmux show-buffer -b "$buffer_name"
		else
			echo "Geçersiz buffer adı"
		fi
	}

	# Buffer listesi ile fzf
	selected_buffer=$(tmux list-buffers -F '#{buffer_name}:#{buffer_sample}' |
		fzf --preview 'buffer_name=$(echo {} | cut -d ":" -f1); tmux show-buffer -b "$buffer_name"' \
			--preview-window 'right:60%:wrap' \
			--header 'Buffer Seçimi | CTRL-R: Yenile | CTRL-Y: Kopyala | ESC: Çıkış' \
			--bind 'ctrl-r:reload(tmux list-buffers -F "#{buffer_name}:#{buffer_sample}")' \
			--bind 'ctrl-y:execute-silent(buffer_name=$(echo {} | cut -d ":" -f1); tmux show-buffer -b "$buffer_name" | wl-copy)' \
			--delimiter ':')

	# Seçim yapıldı mı kontrolü
	if [[ -n "$selected_buffer" ]]; then
		buffer_name=$(echo "$selected_buffer" | cut -d ':' -f1)
		if [[ -n "$buffer_name" ]]; then
			tmux paste-buffer -b "$buffer_name"
			echo "Seçilen buffer yapıştırıldı: $buffer_name"
		else
			echo "Geçersiz buffer adı, yapıştırılamadı"
		fi
	fi
}

# Clipboard modu için fonksiyon
handle_cliphist_mode() {
	# Gerekli programlar kurulu mu kontrolü
	if ! command -v cliphist &>/dev/null; then
		echo "Hata: cliphist kurulu değil!" >&2
		exit 1
	fi
	if ! command -v chafa &>/dev/null; then
		echo "Hata: chafa kurulu değil!" >&2
		exit 1
	fi

	# Önizleme betiği oluştur
	PREVIEW_SCRIPT=$(mktemp)
	chmod +x "$PREVIEW_SCRIPT"

	# Önizleme betiğinin içeriğini oluştur
	cat >"$PREVIEW_SCRIPT" <<'EOL'
#!/usr/bin/env bash
set -euo pipefail

preview_limit=1000

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
echo "Dosya türü: $file_output"
echo "Boyut: $(du -h "$temp_file" | cut -f1)"
echo "İçerik:"
echo

# PNG/JPEG kontrolü
if [[ "$file_output" == *"PNG"* ]] || [[ "$file_output" == *"JPEG"* ]] || [[ "$file_output" == *"image data"* ]]; then
    chafa --size=80x25 --symbols=block+space --colors=256 "$temp_file" 2>/dev/null || echo "Görüntü önizleme başarısız"
else
    head -c "$preview_limit" "$temp_file"
    if [ "$(wc -c < "$temp_file")" -gt "$preview_limit" ]; then
        echo -e "\n... (devamı var)"
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
			--bind "ctrl-y:execute-silent(echo {} | cliphist decode | wl-copy)" \
			--header 'Clipboard Geçmişi | CTRL-R: Yenile | CTRL-D: Sil | CTRL-Y: Kopyala | Enter: Seç')

	# Geçici dosyaları temizle
	rm -f "$PREVIEW_SCRIPT"

	# Seçim yapıldıysa kopyala
	if [[ -n "$selected" ]]; then
		content=$(cliphist decode <<<"$selected")
		echo "$content" | wl-copy
		if [ -n "${TMUX:-}" ]; then
			echo "$content" | tmux load-buffer -
			echo "İçerik clipboard ve tmux buffer'a kopyalandı"
		else
			echo "İçerik clipboard'a kopyalandı"
		fi
	fi
}

# Ana fonksiyon
main() {
	[[ $# -eq 0 ]] && usage

	case "${1:-}" in
	-b)
		echo "INFO: Buffer modu başlatılıyor..."
		handle_buffer_mode
		;;
	-c)
		echo "INFO: Clipboard modu başlatılıyor..."
		handle_cliphist_mode
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

main "$@"
