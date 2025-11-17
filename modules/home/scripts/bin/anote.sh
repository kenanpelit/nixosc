#!/usr/bin/env bash

# =================================================================
# anote.sh - Terminal Tabanlı Not Alma ve Snippet Yönetim Sistemi
# =================================================================
#
# Bu betik, terminal üzerinden hızlı not alma, kodlama snippet'leri ve
# cheatsheet'leri organize etmek için geliştirilmiş bir araçtır.
# fzf ile interaktif arama, bat ile güzel görüntüleme ve çeşitli
# terminal araçlarıyla zengin bir deneyim sunar.
#
# Geliştiren: Kenan Pelit
# Repository: github.com/kenanpelit
# İlham kaynağı: notekami projesi (https://github.com/gotbletu/fzf-nova)
# Versiyon: 3.0 (Optimized)
# Lisans: GPLv3

# Katı mod - hataları daha iyi yakalamak için
set -eo pipefail

# =================================================================
# KONFİGÜRASYON DEĞİŞKENLERİ
# =================================================================

# Temel dizinler
readonly ANOTE_DIR="${ANOTE_DIR:-$HOME/.anote}"
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/anote"
readonly CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/anote/config"

# Alt dizinler
readonly CHEAT_DIR="$ANOTE_DIR/cheats"
readonly SNIPPETS_DIR="$ANOTE_DIR/snippets"
readonly SCRATCH_DIR="$ANOTE_DIR/scratch"

# Varsayılan ayarlar
EDITOR="${EDITOR:-nvim}"
readonly TIMESTAMP="$(date +%Y-%m-%d\ %H:%M:%S)"
readonly SCRATCH_FILE="$SCRATCH_DIR/$(date +%Y-%m).txt"
readonly HISTORY_FILE="$CACHE_DIR/history.json"
readonly CLEANUP_INTERVAL=$((7 * 24 * 60 * 60)) # 7 gün

# Varsayılan fzf ayarları - Catppuccin Mocha Theme
export FZF_DEFAULT_OPTS="-e -i --info=inline --layout=reverse --scroll-off=5 --tiebreak=index --no-unicode"
FZF_DEFAULT_OPTS+=" --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
FZF_DEFAULT_OPTS+=" --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
FZF_DEFAULT_OPTS+=" --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
FZF_DEFAULT_OPTS+=" --color=border:#6c7086,label:#cdd6f4,query:#cdd6f4"
FZF_DEFAULT_OPTS+=" --color=selected-bg:#313244,selected-fg:#cdd6f4"
FZF_DEFAULT_OPTS+=" --bind 'home:first,end:last,ctrl-k:preview-page-up,ctrl-j:preview-page-down'"
FZF_DEFAULT_OPTS+=" --bind 'ctrl-y:preview-up,ctrl-e:preview-down,ctrl-/:change-preview-window(hidden|)'"
FZF_DEFAULT_OPTS+=" --bind 'ctrl-b:toggle-preview,ctrl-d:toggle-preview-wrap'"

# Varsa konfigürasyon dosyasını yükle
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# =================================================================
# YARDIMCI FONKSİYONLAR
# =================================================================

# Yardım menüsü
show_anote_help() {
	cat <<'EOF'
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                        ANOTE - Terminal Not Yöneticisi                        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  AÇIKLAMA:   Terminal üzerinde basit cheatsheet, snippet, karalama ve not alma
              yöneticisi.

  BAĞIMLILIKLAR:  fzf, bat, jq, grep, sed, awk ve bir clipboard aracı
                  (xsel, xclip, wl-copy, pbcopy, veya tmux)

KULLANIM: anote.sh <seçenekler>

SEÇENEKLER:
  Seçenek olmadan çalıştır  → İnteraktif menüyü başlatır
  -a, --auto <metin>        → Not defterine otomatik giriş ekler
  -A, --audit               → Not defterini metin editöründe açar
  -e, --edit [dosya]        → Dosya düzenler veya oluşturur
  -l, --list                → Tüm dosyaları listeler
  -d, --dir                 → Tüm dizinleri listeler
  -p, --print [dosya]       → Dosya içeriğini gösterir
  -s, --search [kelime]     → Tüm dosyalarda arar
  -t, --snippet             → Snippet'i panoya kopyalar ve gösterir
  -i, --info                → Bu bilgi sayfasını gösterir
  -h, --help                → Bu yardım sayfasını gösterir
  -S, --single-snippet      → Tek satır snippet modunu başlatır
  -M, --multi-snippet       → Çok satırlı snippet modunu başlatır
  -c, --config              → Konfigürasyon dosyasını düzenler
      --scratch               → Karalama defterini açar

TUŞ KISAYOLLARI (FZF içinde):
  Tab / Shift+Tab          → Aşağı/yukarı gezinme
  Ctrl+K / Ctrl+J          → Önizleme sayfası yukarı/aşağı
  Ctrl+E                   → Seçili dosyayı düzenle
  Ctrl+F                   → Dosyayı düzenle
  Ctrl+R                   → Listeyi yenile
  Esc                      → Geri/Çıkış
  Enter                    → Seç/Uygula

ÖRNEKLER:
  anote.sh                          → İnteraktif menü
  anote.sh -e notlar/linux/awk.sh   → Belirli bir dosyayı düzenle
  anote.sh -a "Bugün yapılacaklar"  → Not defterine hızlıca not ekle
  anote.sh -s "regexp"              → "regexp" kelimesini ara
  anote.sh -t                       → Snippet kopyalama modunu başlat

KAYIT DİZİNİ: ~/.anote
EOF
}

# Bilgi menüsü (snippet formatları hakkında)
show_snippet_info() {
	cat <<'EOF'
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                         ANOTE - Snippet Formatları                            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

SNIPPET FORMATLARI:

1. Tek-satır snippetler (snippetrc dosyası içinde):
   komut_adı;; komut açıklaması

   Örnek:
   ls -la;; Tüm dosyaları detaylı göster
   find . -name "*.txt";; Metin dosyalarını bul

2. Çok-satırlı snippetler (ayrı dosyalarda):
   ####; Snippet Başlığı

   Snippet içeriği buraya gelir.
   Birden fazla satır olabilir.

   ###; Açıklama (opsiyonel)
   Snippet hakkında açıklama yazabilirsiniz.

   ##; Kullanım Örnekleri (opsiyonel)
   Örnek kullanımlar burada gösterilebilir.

NOTLAR:
- ####; ile başlayan satırlar snippet başlığını belirtir
- ###; ile başlayan satırlar açıklama bölümünü belirtir
- ##; ile başlayan satırlar örnek kullanım bölümünü belirtir
- Bu işaretleyiciler panoya kopyalanmaz, sadece içerik kopyalanır

ÖNERİLER:
- Her snippet için anlamlı başlıklar kullanın
- Karmaşık komutlar için açıklama ekleyin
- Örneklerle kullanımı gösterin
EOF
}

# Bağımlılık kontrolü
check_dependencies() {
	local missing_deps=()
	local required_deps=("fzf" "bat" "jq" "grep" "sed" "awk")

	for dep in "${required_deps[@]}"; do
		command -v "$dep" &>/dev/null || missing_deps+=("$dep")
	done

	# En az bir clipboard yardımcı programı gerekli
	if ! command -v wl-copy &>/dev/null &&
		! command -v xsel &>/dev/null &&
		! command -v xclip &>/dev/null &&
		! command -v pbcopy &>/dev/null &&
		! command -v clip &>/dev/null &&
		[[ "$TERM_PROGRAM" != tmux ]] && [[ -z "$TMUX" ]]; then
		missing_deps+=("wl-copy/xclip/xsel/pbcopy/clip/tmux")
	fi

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		echo "HATA: Aşağıdaki bağımlılıklar eksik:" >&2
		printf "  - %s\n" "${missing_deps[@]}" >&2
		echo "Lütfen bu paketleri yükleyin ve tekrar deneyin." >&2
		exit 1
	fi
}

# Dizinleri oluştur
create_required_directories() {
	mkdir -p "$ANOTE_DIR" "$CHEAT_DIR" "$SNIPPETS_DIR" "$SCRATCH_DIR" "$CACHE_DIR"

	# Dizinler boş ise örnek dosyalar oluştur
	if [[ ! "$(ls -A "$SNIPPETS_DIR" 2>/dev/null)" ]]; then
		cat >"$SNIPPETS_DIR/ornek.sh" <<'EOF'
####; Örnek Bash Komutu

echo "Merhaba, dünya!"

###; Açıklama
Bu basit bir bash komutu örneğidir.
EOF
	fi

	if [[ ! "$(ls -A "$CHEAT_DIR" 2>/dev/null)" ]]; then
		cat >"$CHEAT_DIR/snippetrc" <<'EOF'
ls -la;; Dizin içeriğini ayrıntılı listele
cd -;; Önceki dizine git
mkdir -p;; İç içe dizinler oluştur
EOF
	fi
}

# Güvenli geçmiş güncelleme fonksiyonu
update_history() {
	local dir="$1" file="$2"
	[[ -z "$dir" || -z "$file" ]] && return 1

	local timestamp=$(date +%s)
	local temp_file="$CACHE_DIR/history.tmp"

	# history.json dosyası yoksa veya bozuksa oluştur
	if [[ ! -f "$HISTORY_FILE" ]] || ! jq empty "$HISTORY_FILE" 2>/dev/null; then
		echo "{}" >"$HISTORY_FILE"
	fi

	# Dizin ve dosya yollarında özel karakterleri escape et
	local esc_dir esc_file
	esc_dir=$(printf '%s' "$dir" | jq -R .)
	esc_file=$(printf '%s' "$file" | jq -R .)

	# Güvenli JSON güncelleme
	jq --argjson dir "$esc_dir" \
		--argjson file "$esc_file" \
		--arg time "$timestamp" '
	   .[$dir] = (
	       if has($dir) and (.[$dir] | type) == "array" then
	           .[$dir] | map(select(.file != $file)) + [{
	               "file": $file,
	               "time": ($time | tonumber)
	           }] | sort_by(-.time)[0:100]
	       else
	           [{
	               "file": $file,
	               "time": ($time | tonumber)
	           }]
	       end
	   )
	   ' "$HISTORY_FILE" >"$temp_file" 2>/dev/null

	if [[ $? -eq 0 && -s "$temp_file" ]]; then
		mv "$temp_file" "$HISTORY_FILE"
	else
		echo "{\"$dir\": [{\"file\": \"$file\", \"time\": $timestamp}]}" >"$HISTORY_FILE"
	fi

	rm -f "$temp_file"
}

# Geliştirilmiş geçmiş temizleme fonksiyonu
clean_history() {
	local temp_file="$CACHE_DIR/history.tmp"

	if [[ -f "$HISTORY_FILE" ]]; then
		# Önce JSON'un geçerliliğini kontrol et
		if ! jq empty "$HISTORY_FILE" 2>/dev/null; then
			echo "⚠️ Geçmiş dosyası bozuk, yeniden oluşturuluyor..."
			echo "{}" >"$HISTORY_FILE"
			return 0
		fi

		# Var olmayan dosya referanslarını güvenli şekilde temizle
		jq '
		to_entries |
		map(
			select(.value != null and (.value | type) == "array") |
			.value = (.value |
				map(
					select(
						. != null and
						(. | type) == "object" and
						has("file") and
						(.file | type) == "string" and
						(.file | length) > 0
					)
				) |
				map(select(.file as $f | ($f | test("^/")) and ($f | test("\\.")) ))
			)
		) |
		from_entries |
		to_entries |
		map(select(.value | length > 0)) |
		from_entries
		' "$HISTORY_FILE" >"$temp_file" 2>/dev/null

		if [[ $? -eq 0 && -s "$temp_file" ]]; then
			mv "$temp_file" "$HISTORY_FILE"
		else
			echo "{}" >"$HISTORY_FILE"
		fi

		rm -f "$temp_file"
	else
		echo "{}" >"$HISTORY_FILE"
	fi
}

# Önbellek bakımı
maintain_cache() {
	local last_clean_file="$CACHE_DIR/last_clean"
	local current_time=$(date +%s)

	if [[ ! -f "$last_clean_file" ]] ||
		[[ $((current_time - $(cat "$last_clean_file"))) -gt $CLEANUP_INTERVAL ]]; then
		clean_history
		echo "$current_time" >"$last_clean_file"
	fi
}

# Önbellek güncelleme (snippet kullanım geçmişi için)
update_cache() {
	local item="$1" cache_file="$2"

	[[ ! -f "$cache_file" ]] && touch "$cache_file"

	# Girdiyi en başa ekle ve tekrarları kaldır
	echo "$item" | cat - "$cache_file" | awk '!seen[$0]++' | head -n 100 >"$CACHE_DIR/temp_cache"
	mv "$CACHE_DIR/temp_cache" "$cache_file"
}

# Panoya kopyalama fonksiyonu - Optimize edilmiş
copy_to_clipboard() {
	local content="$1"
	[[ -z "$content" ]] && { echo "⚠️ Kopyalanacak içerik boş!"; return 1; }

	local clipboard_tools="" success=false

	# İçeriği geçici dosyaya yaz
	mkdir -p "$CACHE_DIR"
	printf '%s' "$content" >"$CACHE_DIR/clipboard_content.tmp"

	# Clipboard araçlarını dene
	local -A clipboard_commands=(
		["wl-copy"]="wl-copy"
		["xclip"]="xclip -selection clipboard"
		["xsel"]="xsel --clipboard --input"
		["pbcopy"]="pbcopy"
		["clip"]="clip"
	)

	for tool in "${!clipboard_commands[@]}"; do
		if command -v "$tool" &>/dev/null; then
			if [[ "$tool" == "xclip" || "$tool" == "xsel" ]] && [[ -z "$DISPLAY" ]]; then
				continue
			fi

			if printf '%s' "$content" | ${clipboard_commands[$tool]} 2>/dev/null; then
				success=true
				clipboard_tools="$tool"
				break
			fi
		fi
	done

	# tmux buffer kontrolü
	if [[ "$TERM_PROGRAM" == "tmux" || -n "$TMUX" ]]; then
		if printf '%s' "$content" | tmux load-buffer - 2>/dev/null; then
			[[ "$success" == "true" ]] && clipboard_tools+=", tmux buffer" || {
				clipboard_tools="tmux buffer"
				success=true
			}
		fi
	fi

	rm -f "$CACHE_DIR/clipboard_content.tmp"

	if [[ "$success" != "true" ]]; then
		mv "$CACHE_DIR/clipboard_content.tmp" "$CACHE_DIR/clipboard_content" 2>/dev/null
		echo "⚠️ Panoya kopyalama başarısız! İçerik: $CACHE_DIR/clipboard_content"
		return 1
	fi

	# Başarı mesajı
	local preview
	if [[ ${#content} -gt 100 ]]; then
		preview=$(echo "${content:0:50}...${content: -30}" | tr -d '\n')
	else
		preview=$(echo "$content" | tr -d '\n')
	fi

	echo "✓ İçerik başarıyla panoya kopyalandı (${clipboard_tools})"
	echo "$(tput setaf 8)Önizleme: ${preview}$(tput sgr0)"
	return 0
}

# =================================================================
# YARDIMCI FONKSİYONLAR - GENEL
# =================================================================

# Dosya içeriğini göster
show_file_content() {
	local file="$1"
	if command -v bat &>/dev/null; then
		bat --color=always -pp "$file" 2>/dev/null || cat "$file"
	else
		cat "$file"
	fi
}

# Editörde dosya aç
open_in_editor() {
	local file="$1"
	local line="${2:-}"

	if [[ "$TERM_PROGRAM" == "tmux" || -n "$TMUX" ]]; then
		local filename=$(basename "$file")
		[[ -n "$line" ]] && tmux new-window -n "$filename" "$EDITOR +$line $file" ||
			tmux new-window -n "$filename" "$EDITOR $file"
	else
		[[ -n "$line" ]] && "$EDITOR" +"$line" "$file" || "$EDITOR" "$file"
	fi
}

# Kullanıcıya devam sorgusu
ask_continue() {
	local prompt="${1:-Başka bir seçim yapmak ister misiniz? (e/h) [h]: }"
	local yn
	read -n 1 -p "$prompt" yn
	echo
	[[ -z "$yn" ]] && yn="h"
	[[ "$yn" == "e" || "$yn" == "E" ]]
}

# Geri navigasyon kontrolü
check_navigation() {
	if [[ -f /tmp/anote_nav ]]; then
		rm -f /tmp/anote_nav
		return 0
	fi
	return 1
}

# =================================================================
# SNIPPET İŞLEME FONKSİYONLARI
# =================================================================

# Snippet içeriğini ayıkla - İyileştirilmiş
extract_snippet_content() {
	local file="$1" title="$2"

	# Öncelikle awk ile dene
	local content
	content=$(awk -v title="$title" '
		BEGIN { RS=""; found=0 }
		$0 ~ title && /^####;/ {
			found=1;
			gsub(/^####;[^\n]*\n?/, "");
			gsub(/\n###;[^\n]*/, "");
			gsub(/\n##;[^\n]*/, "");
			gsub(/^\n+/, "");
			gsub(/\n+$/, "");
			print;
			exit
		}
	' "$file")

	# Başarısız olursa sed ile dene
	if [[ -z "$content" ]]; then
		content=$(sed -n "/^####; *$title/,/^####;/p" "$file" |
			sed '1d;$d' |
			sed '/^###;/d; /^##;/d')
	fi

	echo "$content"
}

# Snippet işleme - Birleştirilmiş fonksiyon
process_snippet_selection() {
	local selected="$1"

	# Format doğrulama
	if [[ ! "$selected" =~ ^[^:]+:[0-9]+:####\;[[:space:]]*.+ ]]; then
		echo "⚠️ Hatalı seçim formatı: $selected"
		return 1
	fi

	local file_name line_num snippet_title
	file_name=$(echo "$selected" | cut -d: -f1)
	line_num=$(echo "$selected" | cut -d: -f2)
	snippet_title=$(echo "$selected" | cut -d: -f3- | sed 's/^####; *//')

	# Validasyon
	[[ ! -f "$file_name" ]] && { echo "⚠️ Dosya bulunamadı: $file_name"; return 1; }
	[[ -z "$snippet_title" ]] && { echo "⚠️ Snippet başlığı boş"; return 1; }

	echo "🔍 İşleniyor: $snippet_title (dosya: $file_name)"

	local dir=$(dirname "$file_name")
	update_history "$dir" "$file_name"

	# İçeriği ayıkla
	local snippet_content
	snippet_content=$(extract_snippet_content "$file_name" "$snippet_title")

	[[ -z "$snippet_content" ]] && {
		echo "❌ Snippet içeriği alınamadı!"
		read -n 1 -p "Devam etmek için bir tuşa basın..."
		return 1
	}

	# Panoya kopyala
	echo "📋 Panoya kopyalanıyor..."
	if copy_to_clipboard "$snippet_content"; then
		echo "✅ Başarıyla kopyalandı!"
		echo -e "\n--- Kopyalanan Snippet ---"
		echo "$snippet_content" | show_file_content /dev/stdin
		echo -e "\n"
	else
		echo "❌ Kopyalama başarısız!"
	fi

	return 0
}

# =================================================================
# KULLANICI ARAYÜZÜ FONKSİYONLARI
# =================================================================

# Ana menü
list_anote_options() {
	cat <<EOF
snippet| -- snippets'ten panoya kopyala
single| -- tek satır snippet modunu başlat
multi| -- çok satırlı snippet modunu başlat (tüm dizinler)
multi-cheats| -- çok satırlı snippet modunu başlat (sadece cheats)
cheats| -- cheats'ten panoya kopyala
copy| -- dosya içeriğini panoya kopyala
edit| -- dosyayı düzenle
create| -- yeni dosya oluştur
search| -- tümünde ara
scratch| -- karalama kağıdı
info| -- bilgi sayfası
EOF
}

# Ana TUI
show_anote_tui() {
	local selected
	selected=$(list_anote_options | column -s '|' -t |
		fzf --header 'Esc:çıkış C-n/p:aşağı/yukarı Enter:seç' \
			--prompt="anote > " | cut -d ' ' -f1)

	[[ -z "$selected" ]] && exit 0

	case $selected in
	snippet) snippet_mode ;;
	single) single_mode ;;
	multi) multi_mode "$ANOTE_DIR" "Tüm Dizinler" ;;
	multi-cheats) multi_mode "$CHEAT_DIR" "Sadece Cheats" ;;
	cheats) cheats_mode ;;
	copy) copy_mode ;;
	edit) edit_mode ;;
	create) create_mode ;;
	search) search_mode ;;
	scratch) scratch_mode ;;
	info) show_snippet_info | less -R ;;
	esac
}

# Snippet Modu
snippet_mode() {
	while true; do
		local selected
		selected=$(grep -nrH '^####; ' "$SNIPPETS_DIR"/* 2>/dev/null | sort -t: -k1,1 |
			fzf -d ' ' --with-nth 2.. \
				--prompt="anote > snippet: " \
				--bind "ctrl-f:execute:$EDITOR \$(echo {} | cut -d: -f1)" \
				--bind "ctrl-e:execute:$EDITOR +\$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)" \
				--bind "ctrl-r:reload(grep -nrH '^####; ' $SNIPPETS_DIR/*)" \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--header 'ESC:Geri C-e:satır-düzenle C-f:dosya-düzenle' \
				--preview-window 'down' \
				--preview '
                   file=$(echo {} | cut -d: -f1)
                   title=$(echo {} | cut -d " " -f2-)
                   ext=${file##*.}
                   awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file" |
                       bat --color=always -pp -l "$ext" 2>/dev/null ||
                       awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file"
               ')

		check_navigation && { show_anote_tui; break; }
		[[ -z "$selected" ]] && exit 0

		process_snippet_selection "$selected" || continue
		ask_continue || break
	done
}

# Tek Satır Snippet Modu
single_mode() {
	local SNIPPET_CACHE="$CACHE_DIR/snippetrc"
	local SNIPPET_FILE="$CHEAT_DIR/snippetrc"
	touch "$SNIPPET_FILE" "$SNIPPET_CACHE"

	local selected
	selected=$(cat "$SNIPPET_CACHE" "$SNIPPET_FILE" 2>/dev/null | awk '!seen[$0]++' |
		sed '/^$/d' |
		fzf -e -i \
			--prompt="Snippet > " \
			--info=default \
			--layout=reverse \
			--tiebreak=index \
			--header="CTRL+E: Düzenle | ESC: Çıkış | ENTER: Kopyala" \
			--bind "ctrl-e:execute($EDITOR $SNIPPET_FILE < /dev/tty > /dev/tty)" |
		sed -e 's/;;.*$//' |
		sed 's/^[ \t]*//;s/[ \t]*$//' |
		tr -d '\n')

	[[ -z "$selected" ]] && exit 0

	update_cache "$selected" "$SNIPPET_CACHE"
	copy_to_clipboard "$selected"
	echo -e "\nPanoya kopyalanan: $selected"
	sleep 1
}

# Çok Satırlı Snippet Dosyası Seçme Modu - Optimize edilmiş
multi_mode() {
	local base_dir="${1:-$ANOTE_DIR}"
	local mode_label="${2:-Tüm Dizinler}"
	local MULTI_CACHE="$CACHE_DIR/multi"
	mkdir -p "$CACHE_DIR"
	touch "$MULTI_CACHE"

	while true; do
		local selected
		selected=$({
			cat "$MULTI_CACHE" 2>/dev/null
			find "$base_dir" -type f -not -name ".*" -not -path "*/backups/*" 2>/dev/null
		} |
			awk '!seen[$0]++' |
			sort |
			fzf -e -i \
				--delimiter / \
				--with-nth -2,-1 \
				--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
				--preview-window='right:60%:wrap' \
				--prompt="Metin bloğu ($mode_label) > " \
				--header="ESC: Çıkış | ENTER: Kopyala | CTRL+E: Düzenle" \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--bind "ctrl-e:execute($EDITOR {} < /dev/tty > /dev/tty)")

		check_navigation && { show_anote_tui; break; }
		[[ -z "$selected" ]] && exit 0

		local dir=$(dirname "$selected")
		update_history "$dir" "$selected"
		update_cache "$selected" "$MULTI_CACHE"

		local content=$(cat "$selected")
		copy_to_clipboard "$content"

		echo -e "\n--- Kopyalanan İçerik ---"
		show_file_content "$selected"
		echo -e "\n"

		ask_continue || break
	done
}

# Cheats Modu
cheats_mode() {
	while true; do
		local selected
		selected=$(grep -nrH '^####; ' "$CHEAT_DIR"/* 2>/dev/null | sort -t: -k1,1 |
			fzf -d ' ' --with-nth 2.. \
				--prompt="anote > cheat: " \
				--bind "ctrl-f:execute:$EDITOR \$(echo {} | cut -d: -f1)" \
				--bind "ctrl-e:execute:$EDITOR +\$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)" \
				--bind "ctrl-r:reload(grep -nrH '^####; ' $CHEAT_DIR/*)" \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--header 'ESC:Geri C-e:satır-düzenle C-f:dosya-düzenle' \
				--preview-window 'down' \
				--preview '
                   file=$(echo {} | cut -d: -f1)
                   title=$(echo {} | cut -d " " -f2-)
                   ext=${file##*.}
                   awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file" |
                       bat --color=always -pp -l "$ext" 2>/dev/null ||
                       awk -v title="$title" "BEGIN{RS=\"\"} \$0 ~ title" "$file"
               ')

		check_navigation && { show_anote_tui; break; }
		[[ -z "$selected" ]] && exit 0

		process_snippet_selection "$selected" || continue
		ask_continue || break
	done
}

# Dosya İçeriği Kopyalama Modu
copy_mode() {
	while true; do
		local selected
		selected=$(find "$ANOTE_DIR"/ -type f -not -path "*/backups/*" 2>/dev/null | sort |
			fzf -d / --with-nth -2.. \
				--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--header 'ESC:Geri ENTER:Kopyala' \
				--prompt="anote > kopyala: ")

		check_navigation && { show_anote_tui; break; }
		[[ -z "$selected" ]] && exit 0

		local dir=$(dirname "$selected")
		update_history "$dir" "$selected"

		local content=$(cat "$selected")
		copy_to_clipboard "$content"

		echo -e "\n--- Kopyalanan İçerik ---"
		show_file_content "$selected"
		echo -e "\n"

		ask_continue || break
	done
}

# Dosya Düzenleme Modu
edit_mode() {
	while true; do
		if [[ "$TERM_PROGRAM" == "tmux" || -n "$TMUX" ]]; then
			local selected
			selected=$(find "$ANOTE_DIR"/ -type f -not -path "*/backups/*" 2>/dev/null | sort |
				fzf -m -d / --with-nth -2.. \
					--bind "tab:down,shift-tab:up" \
					--bind "shift-delete:execute:rm -i {} >/dev/tty" \
					--bind "ctrl-v:execute:qmv -f do {} >/dev/tty 2>/dev/null || echo 'qmv bulunamadı'" \
					--bind "ctrl-r:reload:find '$ANOTE_DIR'/ -type f | sort" \
					--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
					--header 'ESC:Geri C-v:yeniden-adlandır C-r:yenile S-del:sil' \
					--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
					--prompt="anote > düzenle: ")

			check_navigation && { show_anote_tui; break; }
			[[ -z "$selected" ]] && exit 0

			while IFS= read -r line; do
				local filename=$(basename "$line")
				tmux new-window -n "$filename" "$EDITOR $line"
			done < <(echo "$selected")
		else
			read -e -p "Dosya yolu (tab ile tamamlayabilirsiniz): " -i "$ANOTE_DIR/" file_path

			if [[ -d "$file_path" ]]; then
				local selected
				selected=$(find "$file_path" -type f 2>/dev/null | sort |
					fzf -d / --with-nth -2.. \
						--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
						--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
						--header 'ESC:Geri ENTER:Düzenle' \
						--prompt="anote > düzenle: ")
			elif [[ -f "$file_path" ]]; then
				selected="$file_path"
			else
				[[ ! -e "$(dirname "$file_path")" ]] && mkdir -p "$(dirname "$file_path")"
				selected="$file_path"
			fi

			check_navigation && { show_anote_tui; break; }
			[[ -z "$selected" ]] && exit 0

			local dir=$(dirname "$selected")
			update_history "$dir" "$selected"
			"$EDITOR" "$selected"
		fi
		break
	done
}

# Dosya Arama Modu
search_mode() {
	while true; do
		local selected
		selected=$(grep -rnv '^[[:space:]]*$' --exclude-dir=backups "$ANOTE_DIR"/* 2>/dev/null |
			fzf -d : --with-nth 1,2,3 \
				--prompt="anote > ara: " \
				--bind "esc:execute-silent(echo 'back' > /tmp/anote_nav)+abort" \
				--header "ESC:Geri ENTER:Seç" \
				--preview '
                    file=$(echo {} | cut -d: -f1)
                    line=$(echo {} | cut -d: -f2)
                    bat --color=always --highlight-line "$line" "$file" 2>/dev/null ||
                    cat "$file" | nl -w4 -s": " | grep -A 5 -B 5 "^[ ]*$line:"
                ')

		check_navigation && { show_anote_tui; break; }
		[[ -z "$selected" ]] && exit 0

		local file_name=$(echo "$selected" | cut -d ':' -f1)
		local file_num=$(echo "$selected" | cut -d ':' -f2)
		local dir=$(dirname "$file_name")

		update_history "$dir" "$file_name"
		open_in_editor "$file_name" "$file_num"
		break
	done
}

# Yeni Dosya Oluşturma Modu
create_mode() {
	while true; do
		clear
		cat <<'EOF'
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                             YENİ DOSYA OLUŞTUR                               ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  1) Tam dosya yolu gir (tab ile tamamlanabilir)
  2) Önce dizin seç, sonra dosya adı gir
  3) Sık kullanılan dizinleri göster
  4) Son oluşturulan dosyaları göster
  5) Ana Menüye Dön

EOF
		read -p "  Seçiminiz (1-5): " choice

		case $choice in
		1)
			create_file_by_path
			return
			;;
		2)
			create_file_by_dir
			return
			;;
		3)
			show_frequent_dirs
			;;
		4)
			show_recent_files
			;;
		5)
			show_anote_tui
			return
			;;
		*)
			echo -e "\n⚠️ Geçersiz seçim! Lütfen 1-5 arası bir sayı girin."
			sleep 1
			;;
		esac
	done
}

# Tam dosya yolu ile dosya oluştur
create_file_by_path() {
	echo
	echo "Dosya yolu girin (Tab tuşu ile tamamlanabilir):"
	read -e -p "  > " -i "$ANOTE_DIR/" file_path

	[[ -z "$file_path" ]] && return

	local dir_path=$(dirname "$file_path")

	if [[ ! -d "$dir_path" ]]; then
		read -p "  Dizin '$dir_path' mevcut değil. Oluşturulsun mu? (e/h): " confirm
		[[ "$confirm" != "e" && "$confirm" != "E" ]] && return
		mkdir -p "$dir_path"
		echo "  ✓ Dizin oluşturuldu: $dir_path"
	fi

	check_file_extension "$file_path" || return
	update_history "$dir_path" "$file_path"
	open_in_editor "$file_path"
}

# Dizin seçerek dosya oluştur
create_file_by_dir() {
	echo
	echo "Önce dizin seçin (Tab tuşu ile tamamlanabilir):"
	read -e -p "  > " -i "$ANOTE_DIR/" dir_path

	[[ -z "$dir_path" ]] && return

	if [[ ! -d "$dir_path" ]]; then
		read -p "  Dizin '$dir_path' mevcut değil. Oluşturulsun mu? (e/h): " confirm
		[[ "$confirm" != "e" && "$confirm" != "E" ]] && return
		mkdir -p "$dir_path"
		echo "  ✓ Dizin oluşturuldu: $dir_path"
	fi

	if [[ "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
		echo -e "\n  Dizindeki mevcut dosyalar:"
		ls -1 "$dir_path" | while read line; do
			echo "    - $line"
		done
		echo
	fi

	echo "Şimdi dosya adını girin:"
	read -p "  > " file_name
	[[ -z "$file_name" ]] && return

	local file_path="${dir_path%/}/$file_name"
	check_file_extension "$file_path" || return
	update_history "$dir_path" "$file_path"
	open_in_editor "$file_path"
}

# Dosya uzantısı kontrolü
check_file_extension() {
	local file_path="$1"
	local file_ext="${file_path##*.}"

	if [[ "$file_path" == "$file_ext" ]]; then
		echo "  ⚠️ Dosya uzantısı belirtilmedi. Önerilen uzantılar: .md, .txt, .sh"
		read -p "  Devam etmek istiyor musunuz? (e/h): " confirm
		[[ "$confirm" != "e" && "$confirm" != "E" ]] && return 1
	fi
	return 0
}

# Sık kullanılan dizinleri göster
show_frequent_dirs() {
	echo -e "\nSık kullanılan dizinler:\n"
	find "$ANOTE_DIR" -maxdepth 2 -type d | sort | while read dir; do
		echo "  - $dir"
	done
	echo
	read -p "Devam etmek için Enter'a basın..." dummy
}

# Son oluşturulan dosyaları göster
show_recent_files() {
	echo
	if [[ -f "$HISTORY_FILE" ]]; then
		echo "Son oluşturulan dosyalar:"
		echo
		jq -r 'to_entries | .[].value[0:5] | .[].file' "$HISTORY_FILE" 2>/dev/null |
			sort | uniq | head -10 | while read file; do
			[[ -f "$file" ]] && echo "  - $file ($(stat -c %y "$file" | cut -d' ' -f1))"
		done
	else
		echo "Henüz kayıtlı geçmiş bulunmuyor."
	fi
	echo
	read -p "Devam etmek için Enter'a basın..." dummy
}

# Karalama Kağıdı Modu
scratch_mode() {
	mkdir -p "$(dirname "$SCRATCH_FILE")"
	touch "$SCRATCH_FILE"

	local first_line=""
	[[ -s "$SCRATCH_FILE" ]] && {
		first_line=$(head -n 1 "$SCRATCH_FILE")
		[[ "$(tail -c 1 "$SCRATCH_FILE")" != "" ]] && echo "" >>"$SCRATCH_FILE"
	}

	if [[ -z "$first_line" || "$first_line" != "# Scratch Notes - $USER" ]]; then
		{
			echo "# Scratch Notes - $USER"
			echo "# Bu dosya $ANOTE_DIR içinde otomatik olarak oluşturulmuş karalama notları içerir."
			echo "# Her yeni giriş bir tarih/saat başlığı ile ayrılır."
			echo ""
		} >"$SCRATCH_FILE.tmp"

		[[ -s "$SCRATCH_FILE" ]] && cat "$SCRATCH_FILE" >>"$SCRATCH_FILE.tmp"
		mv "$SCRATCH_FILE.tmp" "$SCRATCH_FILE"
	fi

	printf "\n#### %s\n\n" "$(date "+%Y-%m-%d %H:%M:%S")" >>"$SCRATCH_FILE"

	# Backup
	local backup_dir="$ANOTE_DIR/backups"
	local today=$(date +%Y%m%d)
	local backup_file="$backup_dir/scratch_$today.bak"

	[[ -d "$backup_dir" && ! -f "$backup_file" ]] && cp "$SCRATCH_FILE" "$backup_file"

	# Editörde aç
	if [[ "$TERM_PROGRAM" == "tmux" || -n "$TMUX" ]]; then
		tmux new-window -n "scratch" "$EDITOR \"+normal G$\" $SCRATCH_FILE"
	else
		if [[ "$EDITOR" == *"nvim"* || "$EDITOR" == *"vim"* ]]; then
			$EDITOR "+normal G$" "$SCRATCH_FILE"
		else
			$EDITOR "+$" "$SCRATCH_FILE"
		fi
	fi

	[[ "$1" != "direct" ]] && { sleep 0.5; show_anote_tui; }
}

# =================================================================
# ANA PROGRAM
# =================================================================

main() {
	check_dependencies
	create_required_directories
	maintain_cache

	case "$1" in
	-h | --help)
		show_anote_help
		exit 0
		;;
	-i | --info)
		show_snippet_info | less -R
		exit 0
		;;
	-A | --audit | --scratch)
		scratch_mode "direct"
		;;
	-a | --auto)
		[[ -z "$2" ]] && { echo 'HATA: Not girişi eksik!' >&2; exit 1; }
		mkdir -p "$(dirname "$SCRATCH_FILE")"
		touch "$SCRATCH_FILE"
		shift
		input="$*"
		[[ -s "$SCRATCH_FILE" ]] && echo "" >>"$SCRATCH_FILE"
		printf "%s\n" "#### $TIMESTAMP" >>"$SCRATCH_FILE"
		printf "%s\n" "$input" >>"$SCRATCH_FILE"
		echo "Not eklendi: $SCRATCH_FILE"
		;;
	-d | --dir)
		cd "$ANOTE_DIR" || exit 1
		find . -type d -not -path "*/\.*" -printf "%P\n" | sort
		;;
	-l | --list)
		cd "$ANOTE_DIR" || exit 1
		find . -type f -not -path "*/\.*" -not -path "*/backups/*" -printf "%P\n" | sort
		;;
	-e | --edit)
		if [[ -z "$2" ]]; then
			cd "$ANOTE_DIR" || exit 1
			selected=$(find . -type f -not -path "*/\.*" | sort |
				fzf -e -i --prompt="anote > düzenle: " \
					--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
					--info=hidden --layout=reverse --scroll-off=5 \
					--bind 'home:first,end:last,ctrl-k:preview-page-up,ctrl-j:preview-page-down')
			[[ -z "$selected" ]] && exit 0
			"$EDITOR" "$selected"
		elif [[ -f "$ANOTE_DIR/$2" ]]; then
			"$EDITOR" "$ANOTE_DIR/$2"
		elif [[ -d "$(dirname "$ANOTE_DIR/$2")" ]]; then
			"$EDITOR" "$ANOTE_DIR/$2"
		elif [[ ! -d "$(dirname "$ANOTE_DIR/$2")" ]]; then
			read -rp "Dizin '$ANOTE_DIR/$(dirname "$2")' mevcut değil. Oluşturulsun mu? [e/h]: " answer
			printf '\n'
			if [[ $answer =~ ^[Ee]$ ]]; then
				mkdir -p "$(dirname "$ANOTE_DIR/$2")"
				"$EDITOR" "$ANOTE_DIR/$2"
			fi
		fi
		;;
	-s | --search)
		if [[ -z "$2" ]]; then
			selected=$(grep -rnv '^[[:space:]]*$' --exclude-dir=backups "$ANOTE_DIR"/* 2>/dev/null |
				fzf -d : --with-nth 1,2,3 --prompt="anote > ara: " \
					--preview '
				    file=$(echo {} | cut -d: -f1)
				    line=$(echo {} | cut -d: -f2)
				    bat --color=always --highlight-line "$line" "$file" 2>/dev/null ||
				    cat "$file" | nl -w4 -s": " | grep -A 5 -B 5 "^[ ]*$line:"
				')
			[[ -z "$selected" ]] && exit 0
			file_name=$(echo "$selected" | cut -d ':' -f1)
			file_num=$(echo "$selected" | cut -d ':' -f2)
			dir=$(dirname "$file_name")
			update_history "$dir" "$file_name"
			open_in_editor "$file_name" "$file_num"
		else
			cd "$ANOTE_DIR" || exit 1
			shift
			grep --color=auto -rnH "$*" . 2>/dev/null || echo "Sonuç bulunamadı."
		fi
		;;
	-p | --print)
		if [[ -z "$2" ]]; then
			selected=$(find "$ANOTE_DIR"/ -type f -not -path "*/\.*" -not -path "*/backups/*" 2>/dev/null | sort |
				fzf -d / --with-nth -2.. \
					--preview 'bat --color=always -pp {} 2>/dev/null || cat {}' \
					--prompt="anote > görüntüle: ")
			[[ -z "$selected" ]] && exit 0
			show_file_content "$selected"
		else
			[[ -f "$ANOTE_DIR/$2" ]] && show_file_content "$ANOTE_DIR/$2" || {
				echo "HATA: Dosya bulunamadı: $ANOTE_DIR/$2" >&2
				exit 1
			}
		fi
		;;
	-t | --snippet)
		snippet_mode
		;;
	-S | --single-snippet)
		single_mode
		;;
	-M | --multi-snippet)
		multi_mode "$ANOTE_DIR" "Tüm Dizinler"
		;;
	-Ms | --multi-snippet-cheats)
		multi_mode "$CHEAT_DIR" "Sadece Cheats"
		;;
	-c | --config)
		mkdir -p "$(dirname "$CONFIG_FILE")"
		if [[ ! -f "$CONFIG_FILE" ]]; then
			cat >"$CONFIG_FILE" <<EOF
# anote.sh konfigürasyon dosyası

# Ana dizin
ANOTE_DIR="$HOME/.anote"

# Editör
EDITOR="nvim"

# Tarih formatı
DATE_FORMAT="%Y-%m-%d %H:%M:%S"

# Önbellek temizleme aralığı (saniye)
CLEANUP_INTERVAL=604800  # 7 gün

# fzf ayarları
FZF_OPTS="-e -i --info=hidden --layout=reverse --scroll-off=5"
EOF
		fi
		"$EDITOR" "$CONFIG_FILE"
		;;
	"")
		show_anote_tui
		;;
	*)
		if [[ -f "$ANOTE_DIR/$1" ]]; then
			show_file_content "$ANOTE_DIR/$1"
		else
			echo "HATA: Dosya bulunamadı: $ANOTE_DIR/$1" >&2
			exit 1
		fi
		;;
	esac
}

# Programı çalıştır
main "$@"
