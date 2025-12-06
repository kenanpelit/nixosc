#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                            CLIPMASTER v1.0                                ║
# ║          Gelişmiş Clipboard Yönetim ve Karşılaştırma Aracı               ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Clipboard geçmişinizi güçlü bir şekilde yönetin, arayın ve karşılaştırın.
# cliphist, fzf/rofi ve vimdiff'in gücünü tek bir araçta birleştirir.
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ ÖZELLİKLER                                                              │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ • Akıllı Arayüz       → Hyprland'de rofi, terminal'de fzf otomatik     │
# │ • Metin & Resim       → Hem metin hem resim clipboard desteği          │
# │ • Gelişmiş Arama      → fzf ile canlı önizleme ve fuzzy search         │
# │ • Diff Karşılaştırma  → Vimdiff ile 2-9 öğe karşılaştırma              │
# │ • Resim Düzenleme     → swappy/imv/feh ile önizleme ve düzenleme       │
# │ • Güvenli Temizlik    → Onaylı geçmiş silme                            │
# │ • Editör Entegrasyonu → nvim/vim ile detaylı inceleme                  │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ BAĞIMLILIKLAR                                                           │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ Zorunlu:  cliphist, wl-copy                                            │
# │ İsteğe Bağlı: fzf, rofi, nvim/vim, swappy, imv, feh                    │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ HIZLI BAŞLANGIÇ                                                         │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ clipmaster.sh text            → Metin geçmişini göster                 │
# │ clipmaster.sh search          → Gelişmiş arama (fzf + önizleme)        │
# │ clipmaster.sh compare 3       → Son 3 öğeyi karşılaştır               │
# │ clipmaster.sh preview         → Resim önizleme ve düzenleme            │
# │ clipmaster.sh inspect         → Editörde detaylı inceleme              │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ HYPRLAND ENTEGRASYONU                                                   │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ ~/.config/hypr/hyprland.conf dosyanıza ekleyin:                        │
# │                                                                         │
# │   bind = SUPER, V, exec, clipmaster.sh text                            │
# │   bind = SUPER SHIFT, V, exec, clipmaster.sh search                    │
# │   bind = SUPER CTRL, V, exec, clipmaster.sh preview                    │
# └─────────────────────────────────────────────────────────────────────────┘
#
# Yazar: ClipMaster Projesi
# Lisans: MIT
# Repo: github.com/yourusername/clipmaster
#

set -euo pipefail

# === KONFİGÜRASYON ===
SCRIPT_NAME="ClipMaster"
TEMP_DIR="/tmp/clipmaster-$$"
NOTIFY_CMD="notify-send"
USE_VIM=true
NUM_ITEMS=2

# === BAĞIMLILIK KONTROLÜ ===
command_exists() {
	command -v "$1" &>/dev/null
}

check_dependencies() {
	local required_cmds=(cliphist wl-copy)
	for cmd in "${required_cmds[@]}"; do
		if ! command_exists "$cmd"; then
			echo "Hata: $cmd bulunamadı!" >&2
			exit 1
		fi
	done
}

# === PAGER SEÇİMİ ===
setup_pager() {
	if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command_exists "rofi"; then
		PAGER="rofi -dmenu -i -theme-str 'window {width: 50%;}' -theme-str 'listview {columns: 1;}'"
	elif [[ -t 1 ]] && command_exists "fzf"; then
		PAGER="fzf --height 40% --reverse"
	elif command_exists "rofi"; then
		PAGER="rofi -dmenu -i"
	elif command_exists "fzf"; then
		PAGER="fzf"
	else
		echo "Hata: Ne fzf ne de rofi bulunamadı!" >&2
		exit 1
	fi
}

# === GEÇİCİ DOSYA YÖNETİMİ ===
setup_temp_dir() {
	mkdir -p "$TEMP_DIR"
	trap cleanup EXIT INT TERM
}

cleanup() {
	rm -rf "$TEMP_DIR"
}

# === YARDIMCI FONKSİYONLAR ===
extract_id() {
	awk '{print $1}' <<<"$1" | tr -d '\n'
}

select_item() {
	local prompt="$1" items="$2"
	case "$PAGER" in
	rofi*) echo "$items" | eval "$PAGER -p \"$prompt\"" ;;
	fzf*) echo "$items" | eval "$PAGER --prompt=\"$prompt > \"" ;;
	esac
}

notify() {
	$NOTIFY_CMD "$SCRIPT_NAME" "$1"
}

# === ANA İŞLEVLER ===
text_history() {
	local selected=$(select_item "Metin Geçmişi" "$(cliphist list | grep -v 'binary data')")
	[[ -n "$selected" ]] || return
	cliphist decode $(extract_id "$selected") | wl-copy
	notify "Metin kopyalandı"
}

full_history() {
	local selected=$(select_item "Tüm Geçmiş" "$(cliphist list)")
	[[ -n "$selected" ]] || return
	cliphist decode $(extract_id "$selected") | wl-copy
	notify "İçerik kopyalandı"
}

image_preview() {
	local selected=$(select_item "Resimler" "$(cliphist list | grep -P 'binary data.*(jpeg|jpg|png|bmp)')")
	[[ -n "$selected" ]] || return

	local img="$TEMP_DIR/preview-$(date +%s).png"
	cliphist decode $(extract_id "$selected") >"$img" || return

	if command_exists "swappy"; then
		swappy -f "$img" -o "$img" && [[ -f "$img" ]] && {
			cat "$img" | wl-copy
			notify "Resim kopyalandı"
		}
	elif command_exists "imv"; then
		imv "$img"
	elif command_exists "feh"; then
		feh "$img"
	else
		notify "Görüntüleyici bulunamadı"
	fi
}

wipe_history() {
	local confirm
	if [[ "$PAGER" =~ fzf ]]; then
		confirm=$(echo -e "Hayır\nEvet" | fzf --prompt="Geçmişi temizle? " --height=20%)
	else
		confirm=$(echo -e "Hayır\nEvet" | eval "$PAGER -p \"Geçmişi temizle?\"")
	fi

	if [[ "$confirm" == "Evet" ]]; then
		cliphist wipe
		notify "Geçmiş temizlendi"
	else
		notify "İşlem iptal edildi"
	fi
}

fzf_search() {
	if ! command_exists "fzf"; then
		echo "Hata: fzf gerekli!" >&2
		return 1
	fi

	local selected=$(cliphist list | fzf --height 50% --reverse \
		--preview "cliphist decode {1}" --preview-window right:50%:wrap)
	[[ -n "$selected" ]] || return
	cliphist decode $(extract_id "$selected") | wl-copy
	notify "İçerik kopyalandı"
}

inspect_item() {
	local selected=$(select_item "İncele" "$(cliphist list)")
	[[ -n "$selected" ]] || return

	local id=$(extract_id "$selected")
	local content=$(cliphist decode "$id")
	local temp_file="$TEMP_DIR/inspect-$(date +%s).txt"

	echo "$content" >"$temp_file"

	if command_exists "nvim"; then
		nvim "$temp_file"
	elif command_exists "vim"; then
		vim "$temp_file"
	else
		${EDITOR:-nano} "$temp_file"
	fi
}

# === KARŞILAŞTIRMA İŞLEVLERİ ===
compare_items() {
	local num="${1:-$NUM_ITEMS}"

	# Sayı kontrolü
	if ! [[ "$num" =~ ^[2-9]$ ]]; then
		echo "Hata: Sayı 2 ile 9 arasında olmalı" >&2
		return 1
	fi

	# Clipboard öğelerini al
	local items=()
	local temp_files=()

	for ((i = 1; i <= num; i++)); do
		local id=$(cliphist list | sed -n "${i}p" | awk '{print $1}')
		if [[ -z "$id" ]]; then
			echo "Hata: Clipboard geçmişinde yeterli öğe yok" >&2
			return 1
		fi

		local content=$(cliphist decode "$id")
		local tf="$TEMP_DIR/diff-${i}-$(date +%s).txt"
		echo "$content" >"$tf"
		temp_files+=("$tf")
	done

	# Karşılaştırma yap
	if [[ "$USE_VIM" == true ]] && command_exists "nvim"; then
		nvim -d "${temp_files[@]}"
	elif [[ "$USE_VIM" == true ]] && command_exists "vim"; then
		vim -d "${temp_files[@]}"
	else
		case $num in
		2)
			diff --side-by-side --color=always "${temp_files[0]}" "${temp_files[1]}" | less -R
			;;
		3)
			diff3 --color=always "${temp_files[0]}" "${temp_files[1]}" "${temp_files[2]}" | less -R
			;;
		*)
			echo "Son $num öğe gösteriliyor:"
			paste "${temp_files[@]}" | column -t -s $'\t' | less -R
			;;
		esac
	fi
}

interactive_diff() {
	local selected=$(select_item "Karşılaştır (Son 2 öğe)" "$(cliphist list | head -n 10)")
	[[ -n "$selected" ]] || return
	compare_items 2
}

# === YARDIM MESAJI ===
show_help() {
	cat <<EOF
╔═══════════════════════════════════════════════════════════════════════════╗
║                            CLIPMASTER v1.0                                ║
║          Gelişmiş Clipboard Yönetim ve Karşılaştırma Aracı               ║
╚═══════════════════════════════════════════════════════════════════════════╝

Kullanım: $0 [komut] [seçenekler]

Komutlar:
  text            Metin geçmişini göster
  all             Tüm geçmişi göster
  preview         Resim önizleme ve düzenleme
  wipe            Geçmişi temizle (onaylı)
  search          fzf ile gelişmiş arama (canlı önizleme)
  inspect         Öğeyi düzenleyicide aç
  diff            İnteraktif karşılaştırma
  compare [N]     Son N öğeyi karşılaştır (varsayılan: 2)
  help            Bu yardım mesajını göster

Diff Seçenekleri:
  -n, --number N  Karşılaştırılacak öğe sayısı (2-9)
  --no-vim        Vimdiff yerine normal diff kullan

Örnekler:
  $0 text                    # Metin geçmişini göster
  $0 search                  # fzf ile gelişmiş arama
  $0 compare 3               # Son 3 öğeyi karşılaştır
  $0 compare -n 4 --no-vim   # Son 4 öğeyi normal diff ile karşılaştır
  $0 preview                 # Resimleri önizle ve düzenle

Hyprland Kısayol Önerileri:
  bind = SUPER, V, exec, $0 text
  bind = SUPER SHIFT, V, exec, $0 search
  bind = SUPER CTRL, V, exec, $0 preview

EOF
}

# === ANA PROGRAM ===
main() {
	check_dependencies
	setup_pager
	setup_temp_dir

	# Argüman işleme
	local command="${1:-text}"
	shift || true

	# Diff seçenekleri için argüman ayrıştırma
	if [[ "$command" == "compare" || "$command" == "diff" ]]; then
		while [[ $# -gt 0 ]]; do
			case "$1" in
			-n | --number)
				NUM_ITEMS="$2"
				shift 2
				;;
			--no-vim)
				USE_VIM=false
				shift
				;;
			[2-9])
				NUM_ITEMS="$1"
				shift
				;;
			*)
				shift
				;;
			esac
		done
	fi

	# Komut yönlendirme
	case "$command" in
	text) text_history ;;
	all) full_history ;;
	preview) image_preview ;;
	wipe) wipe_history ;;
	search) fzf_search ;;
	inspect) inspect_item ;;
	diff) interactive_diff ;;
	compare) compare_items "$NUM_ITEMS" ;;
	help | --help | -h) show_help ;;
	*)
		echo "Geçersiz komut: $command" >&2
		echo "Yardım için: $0 help" >&2
		exit 1
		;;
	esac
}

main "$@"
